-- RUIN Codex: boss loot for the Journal
-- The Journal lists what each boss drops. The lists come from loot data
-- files (LootSample.lua is the template), from a data addon that fills the
-- global RUIN_CodexLoot before Codex loads, or from another addon calling
--   RUIN_API:GetModule("Codex"):AddLoot(instance, data)
--
-- One instance's data:
--   {
--       source   = "Where the list comes from",   -- shown under the list
--       verified = false,                          -- true once checked on WoW Forever
--       bosses = {                                 -- in kill order
--           { "Rhahk'Zor", { 5187, 872 } },        -- boss name, then item IDs
--           { "Edwin VanCleef", { 5193, { 5191, 18 }, 10399 } },   -- { itemID, drop chance % }
--           { "Gilnid", { { 1156, name = "Lavishly Jeweled Ring" } } },   -- name: shown until the game sends the item
--       },
--       trash = { 1156 },                          -- optional: drops from anything inside
--   }
-- instance: the Journal entry's id ("dm") or its name ("The Deadmines").
-- Boss names that match the Journal's bosses (any case) are listed with
-- them; others are added after. A later AddLoot for the same instance
-- replaces the earlier one, so a newer data file wins over the sample.
local ADDON, ns = ...

local Loot = { data = {}, errors = {} }
ns.Loot = Loot

local function cleanItem(e)
    if type(e) == "number" then
        if e >= 1 and e < 1000000 and e == math.floor(e) then return { id = e } end
        return nil
    end
    if type(e) == "table" and tonumber(e[1]) then
        local item = cleanItem(tonumber(e[1]))
        if not item then return nil end
        local chance = tonumber(e[2] or e.chance)
        if chance and chance > 0 and chance <= 100 then item.chance = chance end
        local name = e.name or e[3]
        if type(name) == "string" and name ~= "" then item.name = name:gsub("|", ""):sub(1, 60) end
        if type(e.note) == "string" then item.note = e.note:gsub("|", ""):sub(1, 40) end
        return item
    end
    return nil
end

local function cleanList(list, where)
    local out = {}
    for _, e in ipairs(type(list) == "table" and list or {}) do
        local item = cleanItem(e)
        if item then out[#out + 1] = item
        else Loot.errors[#Loot.errors + 1] = where .. ": skipped an entry that isn't an item ID" end
    end
    return out
end

local function key(text) return tostring(text or ""):lower():gsub("[^%w]", "") end

-- Returns true, or nil and why.
function Loot.Add(instance, data)
    if type(instance) ~= "string" or instance == "" then return nil, "no instance id" end
    if type(data) ~= "table" then return nil, "no data" end
    local entry = { source = type(data.source) == "string" and data.source:sub(1, 120) or nil,
                    verified = data.verified == true, bosses = {}, trash = cleanList(data.trash, instance .. " trash") }
    local bosses = data.bosses
    if type(bosses) == "table" and bosses[1] == nil then   -- { ["Boss"] = { ... } } also works
        local list = {}
        for name, items in pairs(bosses) do list[#list + 1] = { name, items } end
        table.sort(list, function(a, b) return tostring(a[1]) < tostring(b[1]) end)
        bosses = list
    end
    for _, b in ipairs(type(bosses) == "table" and bosses or {}) do
        if type(b) == "table" and type(b[1]) == "string" then
            entry.bosses[#entry.bosses + 1] = { name = b[1]:gsub("|", ""):sub(1, 60), items = cleanList(b[2], instance .. " " .. b[1]) }
        end
    end
    Loot.data[key(instance)] = entry
    return true
end

-- The loot entry for a Journal entry ({ id, name, bosses = { { name, tip } } }):
-- { source, verified, trash = { items }, bosses = { { name, tip, items = { { id, chance } } } } }, or nil.
function Loot.For(entry)
    if type(entry) ~= "table" then return nil end
    local d = Loot.data[key(entry.id)] or Loot.data[key(entry.name)]
    if not d then return nil end
    local out = { source = d.source, verified = d.verified, trash = d.trash, bosses = {} }
    local used = {}
    for _, jb in ipairs(entry.bosses or {}) do
        local items = {}
        for i, lb in ipairs(d.bosses) do
            if not used[i] and key(lb.name) == key(jb[1]) then items = lb.items; used[i] = true end
        end
        out.bosses[#out.bosses + 1] = { name = jb[1], tip = jb[2], items = items }
    end
    for i, lb in ipairs(d.bosses) do
        if not used[i] then out.bosses[#out.bosses + 1] = { name = lb.name, items = lb.items } end
    end
    return out
end

-- Every item ID listed for an instance (to tell listed drops from new ones).
function Loot.Listed(entry)
    local set = {}
    local d = Loot.For(entry)
    if not d then return set end
    for _, b in ipairs(d.bosses) do for _, it in ipairs(b.items) do set[it.id] = true end end
    for _, it in ipairs(d.trash or {}) do set[it.id] = true end
    return set
end

-- Data files call ns.AddLoot(...) while the addon loads.
ns.AddLoot = Loot.Add
