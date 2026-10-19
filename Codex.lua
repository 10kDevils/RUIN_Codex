-- RUIN Codex
-- A dungeon and raid journal, drops that RUIN members loot shared across
-- the org, and a tooltip line saying whether an item is an upgrade for you,
-- scored with stat weights for your spec. Officers curate best-in-slot lists
-- and push them to RUIN; the Upgrades page lists the best known items for
-- your level and spec, and the Raids page plans joint raids with RUIN Muster.
local ADDON, ns = ...
local R = RUIN_API
if not R or (R.apiLevel or 1) < 3 then
    print("|cffc41e3aRUIN|r Codex needs a newer RUIN Core (0.3.0 or later).")
    return
end
local W = R.Widgets
local C = W.COLORS

local M = R:RegisterModule("Codex", { version = "0.3.0" })

local DEFAULTS = { drops = {}, tooltip = true, spec = "Auto", bis = {} }
local BRACKETS = { "1-29", "30-44", "45-59", "60" }
local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local RAID_NEED = { [10] = { 2, 3, 5 }, [20] = { 3, 5, 12 }, [40] = { 5, 10, 25 } }
local db
local ui = { selected = 1, raid = 1, raidSize = 20 }

---------------------------------------------------------------------------
-- Your class and spec
---------------------------------------------------------------------------
local function myClass()
    local _, class = UnitClass("player")
    return class
end

local function talentSpec(class)
    -- Modern clients: the chosen specialization.
    if GetSpecialization and GetSpecializationInfo then
        local ok, idx = pcall(GetSpecialization)
        if ok and idx then
            local _, name = GetSpecializationInfo(idx)
            name = name and (ns.SpecAlias[name] or name)
            if name and ns.SpecWeights[class] and ns.SpecWeights[class][name] then return name end
        end
    end
    -- Talent trees: the one with the most points.
    if GetTalentTabInfo then
        local bestName, bestPoints = nil, 0
        for tab = 1, 3 do
            local res = { pcall(GetTalentTabInfo, tab) }
            if res[1] then
                local name, points
                for i = 2, #res do
                    local v = res[i]
                    if not name and type(v) == "string" and v ~= "" then name = v
                    elseif name and points == nil and type(v) == "number" and v >= 0 and v <= 61 and v == math.floor(v) then points = v end
                end
                name = name and (ns.SpecAlias[name] or name)
                if name and points and points > bestPoints and ns.SpecWeights[class] and ns.SpecWeights[class][name] then
                    bestName, bestPoints = name, points
                end
            end
        end
        if bestName then return bestName end
    end
    return nil
end

local function mySpec()
    local class = myClass()
    if db.spec ~= "Auto" and ns.SpecWeights[class] and ns.SpecWeights[class][db.spec] then return db.spec end
    return talentSpec(class) or (ns.SpecOrder[class] and ns.SpecOrder[class][1])
end

local function bracketFor(level)
    level = level or UnitLevel("player") or 1
    if level >= 60 then return "60" elseif level >= 45 then return "45-59" elseif level >= 30 then return "30-44" end
    return "1-29"
end

---------------------------------------------------------------------------
-- Item helpers
---------------------------------------------------------------------------
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 },
    INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}
local SLOT_NAMES = { [1] = "head", [2] = "neck", [3] = "shoulders", [5] = "chest", [6] = "waist", [7] = "legs",
    [8] = "feet", [9] = "wrists", [10] = "hands", [11] = "ring 1", [12] = "ring 2", [13] = "trinket 1",
    [14] = "trinket 2", [15] = "back", [16] = "main hand", [17] = "off hand", [18] = "ranged" }
local BIS_SLOTS = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18 }

local function itemStats(link)
    if C_Item and C_Item.GetItemStats then return C_Item.GetItemStats(link) end
    if GetItemStats then return GetItemStats(link) end
    return nil
end

local function equipLoc(link)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not f then return nil end
    return select(4, f(link))
end

local function itemIdFromLink(link)
    return tonumber(tostring(link):match("item:(%d+)"))
end

local function weightsFor(class, spec)
    local byClass = ns.SpecWeights[class or ""]
    return byClass and (byClass[spec or ""] or byClass[(ns.SpecOrder[class] or {})[1] or ""]) or ns.Weights[class or ""]
end

local function score(link, class, spec)
    local stats = itemStats(link)
    if not stats then return nil end
    class = class or myClass()
    local w = weightsFor(class, spec or mySpec())
    if not w then return nil end
    local s = 0
    for key, val in pairs(stats) do
        local k = ns.StatMap[key]
        if k and w[k] then s = s + w[k] * val end
    end
    return s
end

local function sameItem(a, b)
    return a and b and itemIdFromLink(a) == itemIdFromLink(b)
end

-- How an item compares with what you wear: pct (or "empty" / "noscore"),
-- the slot it was compared against, and a debug line.
local function compare(link)
    local loc = equipLoc(link)
    local slots = SLOTS[loc or ""]
    if not slots then return nil end
    local new = score(link)
    if not new then return nil, nil, "Codex debug: no stats readable for this item" end
    if new <= 0 then return nil, nil, "Codex debug: no stats your spec weighs" end

    -- Compare against the weakest item in the slot(s) it can go in.
    local weakest, weakestSlot, weakestScore, detail = nil, nil, nil, {}
    for _, slot in ipairs(slots) do
        local eq = GetInventoryItemLink("player", slot)
        if eq and sameItem(eq, link) then return "same" end      -- you're hovering the item you wear
        local s = eq and score(eq)
        detail[#detail + 1] = ("%s=%s"):format(SLOT_NAMES[slot] or slot, eq and (s and ("%.1f"):format(s) or "no stats") or "empty")
        local cmp = eq and (s or 0) or -1                    -- empty slot ranks lowest
        if weakest == nil or cmp < weakestScore then weakest, weakestSlot, weakestScore = eq or false, slot, cmp end
    end
    local dbg = ("Codex debug: %s %s, %s weights, this=%.1f, %s"):format(loc, weakestSlot and SLOT_NAMES[weakestSlot] or "?",
        tostring(mySpec()), new, table.concat(detail, ", "))
    if weakest == false then return "empty", weakestSlot, dbg end
    if weakestScore <= 0 then return "noscore", weakestSlot, dbg end
    return (new - weakestScore) / weakestScore * 100, weakestSlot, dbg
end

-- Returns the tooltip line, plus a debug line describing the comparison.
local function upgradeLine(link)
    local pct, slot, dbg = compare(link)
    if pct == nil or pct == "same" then return nil, dbg end
    local slotName = SLOT_NAMES[slot] or "that slot"
    if pct == "empty" then return ("%sCodex: upgrade (nothing in %s)|r"):format(C.good, slotName), dbg end
    if pct == "noscore" then
        return ("%sCodex: upgrade (your %s item has no stats Codex weighs)|r"):format(C.good, slotName), dbg
    end
    local spec = mySpec()
    if pct >= 1 then return ("%sCodex: +%d%% upgrade over your %s|r %s(%s)|r"):format(C.good, pct, slotName, C.dim, spec or "rough"), dbg end
    if pct <= -1 then return ("%sCodex: %d%% vs your %s|r"):format(C.bad, pct, slotName), dbg end
    return ("%sCodex: about the same as your %s|r"):format(C.dim, slotName), dbg
end

local function dropSources(id)
    local out = {}
    for inst, items in pairs(db.drops) do
        local e = items[id]
        if e then out[#out + 1] = { inst = inst, n = e.n or 1 } end
    end
    table.sort(out, function(a, b) return a.n > b.n end)
    return out
end

local function dropLine(link)
    local id = itemIdFromLink(link)
    if not id then return nil end
    local src = dropSources(id)[1]
    if src then return ("%sCodex: drops in %s (looted %dx by RUIN)|r"):format(C.gold, src.inst, src.n) end
    return nil
end

---------------------------------------------------------------------------
-- Best-in-slot lists: officers curate one per class, spec and level bracket
---------------------------------------------------------------------------
local function bisKey(class, spec, bracket) return class .. ":" .. spec .. ":" .. bracket end

-- Is this item on a RUIN best-in-slot list for your class and spec?
local function bisLine(link)
    local id = itemIdFromLink(link)
    if not id then return nil end
    local class, spec = myClass(), mySpec()
    local hits = {}
    for _, b in ipairs(BRACKETS) do
        local list = db.bis[bisKey(class or "", spec or "", b)]
        if list then
            for slot, iid in pairs(list.i or {}) do
                if iid == id then hits[#hits + 1] = b; break end
            end
        end
    end
    if #hits == 0 then return nil end
    return ("%sCodex: RUIN best-in-slot for %s (%s)|r"):format("|cffc09cf0", spec, table.concat(hits, ", "))
end

function M:SetBis(class, spec, bracket, slot, itemId)
    if not R:IsOfficer() and R:IsConnected() then return self:Print("Only officers edit RUIN's best-in-slot lists.") end
    local key = bisKey(class, spec, bracket)
    local list = db.bis[key] or { c = class, s = spec, b = bracket, i = {} }
    list.i[slot] = itemId
    list.t, list.by = GetServerTime(), UnitName("player")
    list.sent = nil
    db.bis[key] = list
    return list
end

function M:SendBis(class, spec, bracket)
    local key = bisKey(class, spec, bracket)
    local list = db.bis[key]
    if not list then return self:Print("That list is empty.") end
    if not R:IsOfficer() then return self:Print("Only officers send best-in-slot lists to RUIN.") end
    list.t = GetServerTime()
    self:Send("BIS", { k = key, c = list.c, s = list.s, b = list.b, i = list.i, t = list.t, by = list.by }, "ORG", nil, R.PRIORITY.BULK)
    list.sent = true
    self:Toast(("Sent the %s %s (%s) best-in-slot list to RUIN."):format(spec, class:lower(), bracket))
end

function M:OnBis(d, sender)
    if type(d.k) ~= "string" or type(d.i) ~= "table" or type(d.t) ~= "number" then return end
    local cur = db.bis[d.k]
    if cur and (cur.t or 0) >= d.t then return end
    local items = {}
    for slot, id in pairs(d.i) do
        if tonumber(slot) and tonumber(id) then items[tonumber(slot)] = tonumber(id) end
    end
    db.bis[d.k] = { c = d.c, s = d.s, b = d.b, i = items, t = d.t, by = sender, sent = true }
    if d.c == myClass() and d.s == mySpec() then
        self:Toast(("New RUIN best-in-slot list for %s (%s) from %s."):format(d.s, d.b, W.ClassName(sender)))
    end
end

-- Officers give newcomers the lists they have.
function M:OnAsk()
    if not R:IsOfficer() then return end
    C_Timer.After(4 + math.random() * 8, function()
        for key, list in pairs(db.bis) do
            if list.sent then
                self:Send("BIS", { k = key, c = list.c, s = list.s, b = list.b, i = list.i, t = list.t, by = list.by }, "ORG", nil, R.PRIORITY.BULK)
            end
        end
    end)
end

function M:ExportBis(class, spec, bracket)
    local list = db.bis[bisKey(class, spec, bracket)]
    if not list then return self:Print("That list is empty.") end
    R:ShowText("Export best-in-slot list", "Copy with Ctrl+C. Officers can import it with the Import button.",
        R.Util.Encode("BIS", { c = list.c, s = list.s, b = list.b, i = list.i }), nil, true)
end

function M:ImportBis(text)
    local d, err = R.Util.Decode("BIS", text)
    if type(d) ~= "table" or type(d.c) ~= "string" or type(d.s) ~= "string" or type(d.b) ~= "string" or type(d.i) ~= "table" then
        return self:Print("Couldn't import: " .. tostring(err or "not a best-in-slot list") .. ".")
    end
    for slot, id in pairs(d.i) do
        if tonumber(slot) and tonumber(id) then self:SetBis(d.c, d.s, d.b, tonumber(slot), tonumber(id)) end
    end
    ui.bisClass, ui.bisSpec, ui.bisBracket = d.c, d.s, d.b
    self:Print(("Imported the %s %s (%s) list. Press Send to RUIN to share it."):format(d.s, d.c:lower(), d.b))
end

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
local function onTooltip(tooltip)
    if not db or not db.tooltip then return end
    local link
    if TooltipUtil and TooltipUtil.GetDisplayedItem then
        link = select(2, TooltipUtil.GetDisplayedItem(tooltip))
    elseif tooltip.GetItem then
        link = select(2, tooltip:GetItem())
    end
    if not link or (issecretvalue and issecretvalue(link)) then return end
    local ok, line, dbg = pcall(upgradeLine, link)
    if ok and line then tooltip:AddLine(line) end
    if ok and dbg and RUIN_DB and RUIN_DB.settings and RUIN_DB.settings.debug then
        tooltip:AddLine(C.dim .. dbg .. "|r", nil, nil, nil, true)
    end
    local okB, lineB = pcall(bisLine, link)
    if okB and lineB then tooltip:AddLine(lineB) end
    local ok2, line2 = pcall(dropLine, link)
    if ok2 and line2 then tooltip:AddLine(line2) end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onTooltip)
elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", onTooltip)
end

---------------------------------------------------------------------------
-- Learning drops: your own loot inside a dungeon is shared with RUIN
---------------------------------------------------------------------------
local refreshPage = function() end

local function recordDrop(inst, id)
    db.drops[inst] = db.drops[inst] or {}
    local e = db.drops[inst][id] or { n = 0 }
    e.n, e.t = e.n + 1, GetServerTime()
    db.drops[inst][id] = e
    refreshPage()
end

local function qualityOf(id, link)
    if C_Item and C_Item.GetItemQualityByID then
        local q = C_Item.GetItemQualityByID(id)
        if q then return q end
    end
    local q = GetItemInfo and select(3, GetItemInfo(id))
    if q then return q end
    local iq = link:match("|cnIQ(%d):")
    if iq then return tonumber(iq) end
    local colors = { ff9d9d9d = 0, ffffffff = 1, ff1eff00 = 2, ff0070dd = 3, ffa335ee = 4, ffff8000 = 5 }
    return colors[(link:match("|c(%x%x%x%x%x%x%x%x)") or ""):lower()]
end

local function onLoot(_, text, looter)
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
    if not IsInInstance then return end
    local inInstance, kind = IsInInstance()
    if not inInstance or (kind ~= "party" and kind ~= "raid") then return end
    -- Only your own loot is reported, so a group of RUIN members doesn't count one drop five times.
    local me = UnitName("player")
    if looter and looter ~= "" and (looter:gsub("%-.*$", "")) ~= me then return end
    local inst = GetInstanceInfo and GetInstanceInfo() or "Unknown"
    for link in text:gmatch("|H(item:[^|]+)|h") do
        local id = itemIdFromLink(link)
        local q = id and qualityOf(id, text)
        if id and (q == nil or q >= 2) then
            recordDrop(inst, id)
            M:Send("DROP", { i = inst, id = id }, "ORG", nil, R.PRIORITY.BULK)
        end
    end
end

function M:OnDrop(d, sender)
    if type(d.i) ~= "string" or type(d.id) ~= "number" then return end
    recordDrop(d.i, d.id)
end

---------------------------------------------------------------------------
-- Next upgrades: known drops and best-in-slot items better than your gear
---------------------------------------------------------------------------
local function itemInfo(id)
    if not GetItemInfo then return nil end
    local name, link, quality, _, minLevel = GetItemInfo(id)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    return name, link, quality, minLevel
end

local function equippable(link)
    if C_Item and C_Item.IsEquippableItem then return C_Item.IsEquippableItem(link) end
    if IsEquippableItem then return IsEquippableItem(link) end
    return true
end

function M:Upgrades(limit)
    local level = UnitLevel("player") or 1
    local candidates, seen = {}, {}
    local function consider(id, source)
        if seen[id] then
            if source then seen[id].sources[#seen[id].sources + 1] = source end
            return
        end
        local name, link, _, minLevel = itemInfo(id)
        local e = { id = id, sources = { source }, name = name, link = link, minLevel = minLevel }
        seen[id] = e
        if not link or not equippable(link) then return end
        if minLevel and minLevel > level + 3 then return end
        local pct, slot = compare(link)
        if pct == nil or pct == "same" then return end
        if type(pct) == "number" and pct < 1 then return end
        e.pct, e.slot = pct, slot
        candidates[#candidates + 1] = e
    end
    for inst, items in pairs(db.drops) do
        for id, d in pairs(items) do consider(id, ("%s (looted %dx)"):format(inst, d.n or 1)) end
    end
    local class, spec = myClass(), mySpec()
    for _, b in ipairs(BRACKETS) do
        local list = db.bis[bisKey(class or "", spec or "", b)]
        for _, id in pairs(list and list.i or {}) do consider(id, "RUIN best-in-slot (" .. b .. ")") end
    end
    local function rank(e) return (e.pct == "empty" or e.pct == "noscore") and 10000 or e.pct end
    table.sort(candidates, function(a, b) return rank(a) > rank(b) end)
    local out = {}
    for i = 1, math.min(limit or 40, #candidates) do out[i] = candidates[i] end
    return out
end

-- For other modules (Exchange's bag sweep): how an item compares with your
-- gear. Returns a percentage, "empty", "noscore", "same", or nil.
function M:Compare(link)
    local ok, pct = pcall(compare, link)
    if ok then return pct end
end

---------------------------------------------------------------------------
-- Raid planning with RUIN Muster
---------------------------------------------------------------------------
local function defaultWhen()
    local t = date("*t", time() + 86400)
    t.hour, t.min, t.sec = 20, 0, 0
    return date("%Y-%m-%d %H:%M", time(t))
end

function M:PlanRaid(raid, when, size)
    local mu = R:GetModule("Muster")
    if not mu or not mu.Create then return self:Print("Install RUIN Muster to schedule raids.") end
    if mu.CanPost and not mu:CanPost() then return self:Print("Only officers schedule raids (or switch on Muster's practice mode).") end
    local need = RAID_NEED[size] or RAID_NEED[20]
    return mu:Create(raid.name, when, { kind = "Raid", size = tostring(size), need = { need[1], need[2], need[3] },
                                        desc = ("Joint %d-player %s, planned in Codex."):format(size, raid.name) })
end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
local function itemText(id)
    local name, link = itemInfo(id)
    return link or name or ("item #" .. id)
end

local function journalLines(dg, isRaid)
    local lines = {
        { C.gold .. dg.name .. "|r" },
        { C.dim .. (isRaid and (dg.size .. " players") or ("Levels " .. dg.levels)) .. "  ·  " .. dg.where .. "|r" },
        { " " },
        { C.gold .. "Bosses|r" },
    }
    for _, b in ipairs(dg.bosses) do
        lines[#lines + 1] = { C.white .. b[1] .. "|r  " .. C.dim .. b[2] .. "|r" }
    end
    lines[#lines + 1] = { " " }
    lines[#lines + 1] = { C.gold .. "Looted by RUIN members|r" }
    local seen = db.drops[dg.name]
    local any = false
    if seen then
        local ids = {}
        for id in pairs(seen) do ids[#ids + 1] = id end
        table.sort(ids, function(a, b) return (seen[a].n or 0) > (seen[b].n or 0) end)
        for _, id in ipairs(ids) do
            local _, link = itemInfo(id)
            lines[#lines + 1] = { itemText(id) .. C.dim .. "  x" .. (seen[id].n or 1) .. "|r", link = link }
            any = true
        end
    end
    if not any then lines[#lines + 1] = { C.dim .. "Nothing yet. Drops appear here as RUIN members loot them.|r" } end
    return lines
end

local function detailList(parent)
    local l = W.List(parent, 28, function(row)
        row.text = W.Label(row, "")
        row.text:SetPoint("TOPLEFT", 4, -2)
        row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.text:SetJustifyV("TOP")
    end, function(row, line)
        row.text:SetText(line[1])
        row.link = line.link
    end)
    return l
end

local function buildJournal(page)
    ui.dungeons = W.List(page, 28, function(row)
        row.btn = W.Button(row, "", 160)
        row.btn:SetPoint("LEFT", 0, 0)
    end, function(row, dg, i)
        row.btn:SetText(dg.name)
        if i == ui.selected then row.btn:LockHighlight() else row.btn:UnlockHighlight() end
        row.btn:SetScript("OnClick", function() ui.selected = i; refreshPage() end)
    end)
    ui.dungeons.frame:SetPoint("TOPLEFT", 0, 0)
    ui.dungeons.frame:SetPoint("BOTTOMLEFT", 0, 0)
    ui.dungeons.frame:SetWidth(170)
    ui.detail = detailList(page)
    ui.detail.frame:SetPoint("TOPLEFT", 200, 0)
    ui.detail.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -24, 0)
end

local function specOptions()
    local opts = { "Auto" }
    for _, s in ipairs(ns.SpecOrder[myClass() or ""] or {}) do opts[#opts + 1] = s end
    return opts
end

local function buildUpgrades(page)
    local h = W.Header(page, "Best known upgrades for you")
    h:SetPoint("TOPLEFT", 0, -2)
    ui.specCycle = W.Cycle(page, 170, specOptions(), function() return db.spec end,
        function(v) db.spec = v; refreshPage() end, "Weights: ")
    ui.specCycle:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 2)
    local tip = W.Check(page, "Tooltip lines", function() return db.tooltip end, function(v) db.tooltip = v end)
    tip:SetPoint("RIGHT", ui.specCycle, "LEFT", -110, 0)
    ui.upSub = W.Label(page, "", "GameFontHighlightSmall")
    ui.upSub:SetPoint("TOPLEFT", 0, -20)
    ui.upSub:SetPoint("RIGHT", page, "RIGHT", -6, 0)
    ui.upgrades = W.List(page, 30, function(row)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(24, 24)
        row.icon:SetPoint("LEFT", 4, 0)
        row.text = W.Label(row, "")
        row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 1)
        row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.text:SetWordWrap(false)
        row.sub = W.Label(row, "", "GameFontHighlightSmall")
        row.sub:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -2)
        row.sub:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.sub:SetWordWrap(false)
    end, function(row, e)
        local icon = GetItemIcon and GetItemIcon(e.id) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(e.id))
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local gain = (e.pct == "empty") and (C.good .. "fills your empty " .. (SLOT_NAMES[e.slot] or "slot") .. "|r")
            or (e.pct == "noscore" and (C.good .. "upgrade|r"))
            or ("%s+%d%%|r over your %s"):format(C.good, e.pct, SLOT_NAMES[e.slot] or "gear")
        row.text:SetText((e.link or e.name or ("item #" .. e.id)) .. "  " .. gain)
        row.sub:SetText(C.dim .. table.concat(e.sources, "  ·  ") .. (e.minLevel and e.minLevel > 1 and ("  ·  level " .. e.minLevel) or "") .. "|r")
        row.link = e.link
    end)
    ui.upgrades:SetEmptyText("No known upgrades yet. Codex learns items as RUIN members loot them, and officers add best-in-slot lists.")
    ui.upgrades.frame:SetPoint("TOPLEFT", 0, -40)
    ui.upgrades.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -24, 0)
end

local function buildBis(page)
    ui.bisClass, ui.bisSpec, ui.bisBracket = nil, nil, nil
    local h = W.Header(page, "Best-in-slot")
    h:SetPoint("TOPLEFT", 0, -2)
    ui.bisClassBtn = W.Cycle(page, 100, CLASSES, function() return ui.bisClass end, function(v)
        ui.bisClass = v
        ui.bisSpec = ns.SpecOrder[v][1]
        refreshPage()
    end)
    ui.bisClassBtn:SetPoint("TOPLEFT", 90, 2)
    ui.bisSpecBtn = W.Button(page, "", 130, nil)
    ui.bisSpecBtn:SetPoint("LEFT", ui.bisClassBtn, "RIGHT", 4, 0)
    ui.bisSpecBtn:SetScript("OnClick", function(_, mouse)
        local opts = ns.SpecOrder[ui.bisClass] or {}
        local idx = 1
        for i, s in ipairs(opts) do if s == ui.bisSpec then idx = i end end
        idx = (mouse == "RightButton") and ((idx - 2) % #opts + 1) or (idx % #opts + 1)
        ui.bisSpec = opts[idx]
        refreshPage()
    end)
    ui.bisBracketBtn = W.Cycle(page, 80, BRACKETS, function() return ui.bisBracket end, function(v) ui.bisBracket = v; refreshPage() end)
    ui.bisBracketBtn:SetPoint("LEFT", ui.bisSpecBtn, "RIGHT", 4, 0)
    ui.bisSend = W.Button(page, "Send to RUIN", 110, function() M:SendBis(ui.bisClass, ui.bisSpec, ui.bisBracket) end)
    ui.bisSend:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 2)
    local exp = W.Button(page, "Export", 64, function() M:ExportBis(ui.bisClass, ui.bisSpec, ui.bisBracket) end)
    exp:SetPoint("RIGHT", ui.bisSend, "LEFT", -4, 0)
    ui.bisImport = W.Button(page, "Import", 64, function()
        R:ShowText("Import best-in-slot list", "Paste a RUIN best-in-slot string (RUIN-BIS1:...) and press OK.", "", function(t)
            M:ImportBis(t); refreshPage()
        end)
    end)
    ui.bisImport:SetPoint("RIGHT", exp, "LEFT", -4, 0)
    ui.bisInfo = W.Label(page, "", "GameFontHighlightSmall")
    ui.bisInfo:SetPoint("TOPLEFT", 0, -24)
    ui.bisInfo:SetPoint("RIGHT", page, "RIGHT", -6, 0)

    ui.bisBoxes = {}
    ui.bisList = W.List(page, 26, function(row)
        row.slot = W.Label(row, "", "GameFontNormalSmall")
        row.slot:SetPoint("LEFT", 6, 0)
        row.slot:SetWidth(76)
        row.text = W.Label(row, "")
        row.text:SetPoint("LEFT", 86, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -250, 0)
        row.text:SetWordWrap(false)
        row.clear = W.Button(row, "Clear", 50)
        row.clear:SetPoint("RIGHT", 0, 0)
        row.set = W.Button(row, "Set", 40)
        row.set:SetPoint("RIGHT", row.clear, "LEFT", -2, 0)
        row.box = W.EditBox(row, 140)
        row.box:SetPoint("RIGHT", row.set, "LEFT", -6, 0)
        ui.bisBoxes[#ui.bisBoxes + 1] = row.box
    end, function(row, slot)
        local list = db.bis[bisKey(ui.bisClass, ui.bisSpec, ui.bisBracket)]
        local id = list and list.i[slot]
        row.slot:SetText((tostring(SLOT_NAMES[slot] or slot):gsub("^%l", string.upper)))
        local link
        if id then link = select(2, itemInfo(id)) end
        row.text:SetText(id and (itemText(id)) or (C.dim .. "-|r"))
        row.link = link
        local officer = R:IsOfficer() or not R:IsConnected()
        row.box:SetShown(officer)
        row.set:SetShown(officer)
        row.clear:SetShown(officer and id ~= nil)
        row.set:SetScript("OnClick", function()
            local text = row.box:GetText() or ""
            local newId = itemIdFromLink(text) or tonumber(text)
            if not newId then return M:Print("Shift-click an item into the box, or type its item ID.") end
            M:SetBis(ui.bisClass, ui.bisSpec, ui.bisBracket, slot, newId)
            row.box:SetText("")
            refreshPage()
        end)
        row.clear:SetScript("OnClick", function()
            M:SetBis(ui.bisClass, ui.bisSpec, ui.bisBracket, slot, nil)
            refreshPage()
        end)
    end)
    ui.bisList.frame:SetPoint("TOPLEFT", 0, -42)
    ui.bisList.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -24, 0)

    local function insert(link)
        if type(link) ~= "string" then return end
        for _, box in ipairs(ui.bisBoxes) do
            if box:HasFocus() then box:SetText(link) end
        end
    end
    if ChatEdit_InsertLink then pcall(hooksecurefunc, "ChatEdit_InsertLink", insert) end
    if ChatFrameUtil and ChatFrameUtil.InsertLink then pcall(hooksecurefunc, ChatFrameUtil, "InsertLink", insert) end
end

local function buildRaids(page)
    ui.raids = W.List(page, 28, function(row)
        row.btn = W.Button(row, "", 160)
        row.btn:SetPoint("LEFT", 0, 0)
    end, function(row, r, i)
        row.btn:SetText(r.name)
        if i == ui.raid then row.btn:LockHighlight() else row.btn:UnlockHighlight() end
        row.btn:SetScript("OnClick", function() ui.raid = i; ui.raidSize = r.size <= 20 and r.size or 20; refreshPage() end)
    end)
    ui.raids.frame:SetPoint("TOPLEFT", 0, 0)
    ui.raids.frame:SetPoint("BOTTOMLEFT", 0, 0)
    ui.raids.frame:SetWidth(170)

    local card = W.Card(page)
    card:SetPoint("TOPLEFT", 200, 0)
    card:SetPoint("RIGHT", page, "RIGHT", -4, 0)
    card:SetHeight(84)
    local h = W.Header(card, "Plan a joint RUIN run")
    h:SetPoint("TOPLEFT", 8, -6)
    ui.raidWhen = W.EditBox(card, 130)
    ui.raidWhen:SetPoint("TOPLEFT", 12, -28)
    ui.raidWhen:SetText(defaultWhen())
    local size = W.Cycle(card, 90, { 10, 20, 40 }, function() return ui.raidSize end, function(v) ui.raidSize = v end, "Size ")
    size:SetPoint("LEFT", ui.raidWhen, "RIGHT", 8, 0)
    ui.raidPost = W.Button(card, "Post in Muster", 120, function()
        local raid = ns.Raids[ui.raid]
        if raid and M:PlanRaid(raid, ui.raidWhen:GetText(), ui.raidSize) then refreshPage() end
    end)
    ui.raidPost:SetPoint("LEFT", size, "RIGHT", 6, 0)
    ui.raidRuns = W.Label(card, "", "GameFontHighlightSmall")
    ui.raidRuns:SetPoint("TOPLEFT", 10, -56)
    ui.raidRuns:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    ui.raidRuns:SetWordWrap(false)

    ui.raidDetail = detailList(page)
    ui.raidDetail.frame:SetPoint("TOPLEFT", 200, -92)
    ui.raidDetail.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -24, 0)
end

local function buildPage(panel)
    ui.panel = panel
    ui.tabs = W.SubTabs(panel, { "Journal", "Upgrades", "Best-in-slot", "Raids" }, function() refreshPage() end)
    buildJournal(ui.tabs.pages[1])
    buildUpgrades(ui.tabs.pages[2])
    buildBis(ui.tabs.pages[3])
    buildRaids(ui.tabs.pages[4])

    refreshPage = function()
        if not ui.panel:IsVisible() then return end
        local tab = ui.tabs.selected
        if tab == 1 then
            ui.dungeons:SetItems(ns.Dungeons)
            local dg = ns.Dungeons[ui.selected] or ns.Dungeons[1]
            ui.detail:SetItems(dg and journalLines(dg, false) or {})
        elseif tab == 2 then
            ui.specCycle.Refresh()
            local spec = mySpec()
            ui.upSub:SetText(C.dim .. ("Scored with %s weights for a level %d %s. Items you can use within 3 levels, from RUIN's loot and best-in-slot lists."):format(
                tostring(spec), UnitLevel("player") or 0, (myClass() or "?"):lower()) .. "|r")
            ui.upgrades:SetItems(M:Upgrades(40))
        elseif tab == 3 then
            ui.bisClass = ui.bisClass or myClass() or "WARRIOR"
            ui.bisSpec = ui.bisSpec or mySpec() or ns.SpecOrder[ui.bisClass][1]
            ui.bisBracket = ui.bisBracket or bracketFor()
            ui.bisClassBtn.Refresh()
            ui.bisSpecBtn:SetText(ui.bisSpec)
            ui.bisBracketBtn.Refresh()
            local list = db.bis[bisKey(ui.bisClass, ui.bisSpec, ui.bisBracket)]
            local officer = R:IsOfficer() or not R:IsConnected()
            ui.bisSend:SetShown(R:IsOfficer())
            ui.bisImport:SetShown(officer)
            ui.bisInfo:SetText(C.dim .. (list and list.t and ("Last changed by %s, %s%s."):format(tostring(list.by), W.Ago(GetServerTime() - list.t),
                list.sent and "" or (officer and "  Not sent to RUIN yet." or "")) or
                (officer and "No list yet. Shift-click items into the boxes and press Set, then Send to RUIN." or "No RUIN list for this spec yet.")) .. "|r")
            ui.bisList:SetItems(BIS_SLOTS)
        elseif tab == 4 then
            ui.raids:SetItems(ns.Raids)
            local raid = ns.Raids[ui.raid] or ns.Raids[1]
            ui.raidDetail:SetItems(raid and journalLines(raid, true) or {})
            local mu = R:GetModule("Muster")
            ui.raidPost:SetEnabled(mu ~= nil)
            local runs = {}
            if mu and mu.GetUpcoming then
                for _, ev in ipairs(mu:GetUpcoming()) do
                    if raid and ev.title:lower():find(raid.name:lower(), 1, true) then
                        runs[#runs + 1] = ("%s (%d signed)"):format(date("%a %d %b %H:%M", ev.at), ev.signed)
                    end
                end
            end
            ui.raidRuns:SetText(not mu and (C.dim .. "Install RUIN Muster to schedule runs and take sign-ups.|r")
                or (#runs > 0 and (C.good .. "Upcoming: |r" .. table.concat(runs, ",  ")) or (C.dim .. "No run scheduled yet.|r")))
        end
    end
    panel:SetScript("OnShow", function() refreshPage() end)
    ui.tabs:Select(1)
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
function M:OnEnable()
    if type(RUIN_CodexDB) ~= "table" then RUIN_CodexDB = {} end
    db = RUIN_CodexDB
    for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end

    self:Listen("DROP", "OnDrop")
    self:Listen("BIS", "OnBis")
    self:Listen("ASK", "OnAsk")
    self:AddTab("Codex", buildPage)
    self:RegisterEvent("CHAT_MSG_LOOT", onLoot)
    R:Subscribe("Muster:EVENTS", function() refreshPage() end)
    R:Subscribe("CHANNELS_CHANGED", function()
        C_Timer.After(8, function() if R:IsConnected() then self:Send("ASK", {}, "ORG") end end)
    end)

    -- Item names arrive from the server a moment after they're first asked for.
    local pending = false
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED", function()
        if pending then return end
        pending = true
        C_Timer.After(0.5, function() pending = false; refreshPage() end)
    end)

    -- Opening Codex inside a dungeon jumps to that dungeon's entry.
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        local inst = GetInstanceInfo and GetInstanceInfo()
        for i, dg in ipairs(ns.Dungeons) do if dg.name == inst then ui.selected = i end end
        for i, r in ipairs(ns.Raids) do if r.name == inst then ui.raid = i end end
    end)
end

function RUIN_Codex_Open() M:OpenTab() end
BINDING_HEADER_RUIN_CODEX = "RUIN Codex"
BINDING_NAME_RUIN_CODEX_OPEN = "Open Codex"

-- /codex [dungeon or raid name] | upgrades | bis | spec <name|auto>
SLASH_RUINCODEX1 = "/codex"
SlashCmdList.RUINCODEX = function(msg)
    msg = (msg or ""):lower()
    local cmd, rest = msg:match("^(%S*)%s*(.*)$")
    local tab = 1
    if cmd == "upgrades" then tab = 2
    elseif cmd == "bis" then tab = 3
    elseif cmd == "spec" then
        local pick = "Auto"
        for _, s in ipairs(ns.SpecOrder[myClass() or ""] or {}) do if s:lower() == rest then pick = s end end
        db.spec = pick
        M:Print("Codex weights: " .. (pick == "Auto" and ("auto (" .. tostring(mySpec()) .. ")") or pick) .. ".")
        return
    elseif msg ~= "" then
        for i, dg in ipairs(ns.Dungeons) do
            if dg.name:lower():find(msg, 1, true) or dg.id == msg then ui.selected = i end
        end
        for i, r in ipairs(ns.Raids) do
            if r.name:lower():find(msg, 1, true) or r.id == msg then ui.raid = i; tab = 4 end
        end
    end
    M:OpenTab()
    if ui.tabs then ui.tabs:Select(tab) end
    refreshPage()
end
