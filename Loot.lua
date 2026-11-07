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
--           { "Faldrim Anvilmar", { { name = "Ephemeral Choker", info = "Neck" } } },   -- no ID yet: name and a short description
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

local function clip(text, n) return (tostring(text):gsub("[|%c]", ""):sub(1, n)) end

local function cleanItem(e)
    -- a named drop with no item ID yet: { name = "Ephemeral Choker", info = "Neck" }
    if type(e) == "table" and e[1] == nil and e.id == nil and type(e.name) == "string" and e.name ~= "" then
        local item = { name = clip(e.name, 60) }
        if type(e.info) == "string" and e.info ~= "" then item.info = clip(e.info, 80) end
        return item
    end
    if type(e) == "table" and e[1] == nil and tonumber(e.id) then e = { tonumber(e.id), e.chance, name = e.name, note = e.note, info = e.info } end
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
        if type(e.info) == "string" and e.info ~= "" then item.info = clip(e.info, 80) end
        return item
    end
    return nil
end

local function cleanList(list, where)
    local out = {}
    for _, e in ipairs(type(list) == "table" and list or {}) do
        local item = cleanItem(e)
        if item then out[#out + 1] = item
        else Loot.errors[#Loot.errors + 1] = where .. ": skipped an entry that isn't an item ID or a named item" end
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
-- Loot.questie(entry), set by Codex.lua, gives the dungeon's drops read from
-- Questie or QuestieDB: { sections = { { name, rare, items = { ... } } }, trash = { ... } }
-- or nil. When it has a list, that list leads: listed drops it lacks (by ID or
-- name) are added, and a listed drop it has lends its drop chance and slot.
local function merged(entry, d, q)
    local out = { source = "questie", verified = false, trash = {}, bosses = {} }
    local listed = {}               -- listed items by ID and by name
    local function remember(it)
        if it.id then listed["id:" .. it.id] = it end
        if it.name then listed["n:" .. key(it.name)] = it end
    end
    for _, b in ipairs(d and d.bosses or {}) do for _, it in ipairs(b.items) do remember(it) end end
    for _, it in ipairs(d and d.trash or {}) do remember(it) end
    local shown = {}
    local function take(it)
        local l = (it.id and listed["id:" .. it.id]) or (it.name and listed["n:" .. key(it.name)])
        local copy = { id = it.id, name = it.name, info = it.info or (l and l.info), chance = l and l.chance, quest = it.quest }
        if it.id then shown["id:" .. it.id] = true end
        if it.name then shown["n:" .. key(it.name)] = true end
        if l and l.id then shown["id:" .. l.id] = true end
        if l and l.name then shown["n:" .. key(l.name)] = true end
        return copy
    end
    local function isShown(it) return (it.id and shown["id:" .. it.id]) or (it.name and shown["n:" .. key(it.name)]) end
    local secByKey, usedSec = {}, {}
    for i, sec in ipairs(q.sections or {}) do secByKey[key(sec.name)] = i end
    local listedByKey = {}
    for _, lb in ipairs(d and d.bosses or {}) do listedByKey[key(lb.name)] = lb end
    local function bossItems(name)
        local items = {}
        local i = secByKey[key(name)]
        if i then usedSec[i] = true; for _, it in ipairs(q.sections[i].items) do items[#items + 1] = take(it) end end
        return items
    end
    -- the journal's bosses, in order, then rares and other named drops Questie knows
    for _, jb in ipairs(entry.bosses or {}) do
        out.bosses[#out.bosses + 1] = { name = jb[1], tip = jb[2], items = bossItems(jb[1]) }
    end
    for i, sec in ipairs(q.sections or {}) do
        if not usedSec[i] then
            local items = {}
            for _, it in ipairs(sec.items) do items[#items + 1] = take(it) end
            out.bosses[#out.bosses + 1] = { name = sec.name, tip = sec.rare and "Rare: not every run." or nil, items = items }
        end
    end
    -- listed drops Questie doesn't have: under their boss, or a section of their own
    local byName = {}
    for _, b in ipairs(out.bosses) do byName[key(b.name)] = b end
    for _, lb in ipairs(d and d.bosses or {}) do
        local target = byName[key(lb.name)]
        for _, it in ipairs(lb.items) do
            if not isShown(it) then
                if not target then
                    target = { name = lb.name, items = {} }
                    out.bosses[#out.bosses + 1] = target
                    byName[key(lb.name)] = target
                end
                target.items[#target.items + 1] = take(it)
            end
        end
    end
    for _, it in ipairs(q.trash or {}) do if not isShown(it) then out.trash[#out.trash + 1] = take(it) end end
    for _, it in ipairs(d and d.trash or {}) do if not isShown(it) then out.trash[#out.trash + 1] = take(it) end end
    return out
end

function Loot.For(entry)
    if type(entry) ~= "table" then return nil end
    local d = Loot.data[key(entry.id)] or Loot.data[key(entry.name)]
    local q = Loot.questie and Loot.questie(entry)
    if q then
        -- the Classic sample is replaced; the WoW Forever launch lists are merged in
        if d and d.source and tostring(d.source):find("Classic", 1, true) then d = nil end
        return merged(entry, d, q)
    end
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

-- Every item listed for an instance (to tell listed drops from new ones):
-- item IDs, and the names of drops listed without an ID (lowercase, under names).
function Loot.Listed(entry)
    local set, names = {}, {}
    local d = Loot.For(entry)
    if not d then return set, names end
    local function add(it)
        if it.id then set[it.id] = true end
        if it.name then names[it.name:lower()] = true end
    end
    for _, b in ipairs(d.bosses) do for _, it in ipairs(b.items) do add(it) end end
    for _, it in ipairs(d.trash or {}) do add(it) end
    return set, names
end

-- Data files call ns.AddLoot(...) while the addon loads.
ns.AddLoot = Loot.Add
