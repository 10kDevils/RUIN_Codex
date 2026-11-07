-- RUIN Codex
-- Class macros you can add in one click (and a reference of macro commands),
-- and a dungeon and raid journal: bosses, the loot each boss drops (from loot
-- data files, see Loot.lua), drops RUIN members have looted, and run planning
-- with RUIN Muster. Item tooltips say whether an item is an upgrade for your
-- spec. Gear tracking (best-in-slot lists, a gear path) is left to a gear
-- addon RUIN may work with later.
local ADDON, ns = ...
local R = RUIN_API
if not R or (R.apiLevel or 1) < 9 then
    print("|cff54b7d9[RUIN]|r Codex needs a newer RUIN Core (0.3.16 or later).")
    return
end
local W = R.Widgets
local C = W.COLORS

local M = R:RegisterModule("Codex", { version = "0.5.3" })
ns.Codex = M

local DEFAULTS = { drops = {}, kills = {}, mobs = {}, tooltip = true, spec = "Auto", installed = {} }
local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

-- "WARRIOR" -> "Warrior" (the game's own name when it has one).
function ns.ClassLabel(class)
    if class == "SHARED" then return "All classes" end
    local names = LOCALIZED_CLASS_NAMES_MALE
    if names and names[class] then return names[class] end
    class = tostring(class or "")
    return class:sub(1, 1) .. class:sub(2):lower()
end
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
-- Bows, guns, crossbows, thrown and wands: their damage counts as ranged (RDPS).
local RANGED_LOC = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true }
-- Retail has no ranged slot: bows, guns and wands go in the main hand.
if R and R.client == "retail" then
    SLOTS.INVTYPE_RANGED, SLOTS.INVTYPE_RANGEDRIGHT, SLOTS.INVTYPE_THROWN = { 16 }, { 16 }, { 16 }
end
M.SLOTS, M.RANGED_LOC = SLOTS, RANGED_LOC
local SLOT_NAMES = { [1] = "head", [2] = "neck", [3] = "shoulders", [5] = "chest", [6] = "waist", [7] = "legs",
    [8] = "feet", [9] = "wrists", [10] = "hands", [11] = "ring 1", [12] = "ring 2", [13] = "trinket 1",
    [14] = "trinket 2", [15] = "back", [16] = "main hand", [17] = "off hand", [18] = "ranged" }

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

-- An item's value for a class and spec: the item API's stats plus its
-- tooltip's "Equip:" lines (spell damage and healing, crit, hit, attack
-- power, mana per 5...), weighed by the spec's stat weights.
local function score(link, class, spec)
    local stats = ns.ItemStats.Read(link)
    if not stats then return nil end
    class = class or myClass()
    spec = spec or mySpec()
    local w = weightsFor(class, spec)
    if not w then return nil end
    return ns.ItemStats.Score(stats, w, class, spec, RANGED_LOC[equipLoc(link) or ""] == true)
end
M.Score = score

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
    local ok2, line2 = pcall(dropLine, link)
    if ok2 and line2 then tooltip:AddLine(line2) end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onTooltip)
elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", onTooltip)
end

---------------------------------------------------------------------------
-- Learning drops: loot inside a dungeon or raid is shared with RUIN. Your
-- own loot always; a groupmate's who doesn't run RUIN by one RUIN member of
-- the group; members who were offline catch up when they connect.
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

-- Which lines are real loot: "X receives loot: [item]." and "You receive loot:
-- [item]." (and their "xN" forms). Items handed out by quests, crafting or
-- the roll system's "won"/"selected Need" lines don't count.
local lootPatterns
local function toPattern(g)
    g = g:gsub("([%(%)%.%-%+%[%]%?%*%^%$])", "%%%1")
    return "^" .. g:gsub("%%s", "(.+)"):gsub("%%d", "%%d+") .. "$"
end
local function buildPatterns()
    lootPatterns = {}
    local function add(g, self)
        if type(g) == "string" and g ~= "" then lootPatterns[#lootPatterns + 1] = { p = toPattern(g), self = self } end
    end
    add(LOOT_ITEM_SELF_MULTIPLE or "You receive loot: %sx%d.", true)
    add(LOOT_ITEM_SELF or "You receive loot: %s.", true)
    add(LOOT_ITEM_MULTIPLE or "%s receives loot: %sx%d.", false)
    add(LOOT_ITEM or "%s receives loot: %s.", false)
end

-- The looter of a loot line ("me" for your own), or nil if it isn't a loot line.
local function parseLoot(text)
    if not lootPatterns then buildPatterns() end
    for _, lp in ipairs(lootPatterns) do
        local a, b = text:match(lp.p)
        if a then
            if lp.self then return "me", a end
            return a, b
        end
    end
    return nil
end

local function short(n) return (tostring(n or ""):gsub("%-.*$", "")) end

-- RUIN members online, by short name (lower case).
local function ruinNames()
    local set = {}
    for _, p in ipairs(R:GetOnlineMembers() or {}) do if p.name then set[short(p.name):lower()] = true end end
    return set
end

-- Your group, by short name (you included).
local function groupNames()
    local out = { short(UnitName("player")) }
    local n = GetNumGroupMembers and GetNumGroupMembers() or 0
    local raid = IsInRaid and IsInRaid()
    for k = 1, n do
        local unit = raid and ("raid" .. k) or ("party" .. k)
        local name = UnitName(unit)
        if type(name) == "string" and not (issecretvalue and issecretvalue(name)) and name ~= out[1] then out[#out + 1] = short(name) end
    end
    return out
end

-- Should you report this player's loot? Your own always. Someone else's when
-- they don't run RUIN and you're the first RUIN member of the group by name,
-- so each drop is counted once however many RUIN members are there.
local function reportsFor(looter)
    local me = short(UnitName("player"))
    if looter == "me" or short(looter):lower() == me:lower() then return true end
    local ruin = ruinNames()
    if ruin[short(looter):lower()] then return false end           -- their own RUIN reports it
    local first
    for _, n in ipairs(groupNames()) do
        local low = n:lower()
        if (ruin[low] or low == me:lower()) and (not first or low < first) then first = low end
    end
    return first == me:lower()
end
M.ReportsFor = reportsFor

local recent = {}          -- "id|looter" -> time, so the chat line and the encounter event count once
local function report(inst, id, looter, q)
    if not id or (q ~= nil and q < 2) then return end
    local key = id .. "|" .. short(looter == "me" and UnitName("player") or looter):lower()
    if recent[key] and GetTime() - recent[key] < 15 then return end
    recent[key] = GetTime()
    recordDrop(inst, id)
    M:Send("DROP", { i = inst, id = id }, "ORG", nil, R.PRIORITY.BULK)
end

local function inGroupInstance()
    if not IsInInstance then return false end
    local inInstance, kind = IsInInstance()
    return inInstance and (kind == "party" or kind == "raid")
end

local function onLoot(_, text, looterArg)
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
    R.Items.RememberLinks(text)
    if not inGroupInstance() then return end
    local looter = parseLoot(text)
    if not looter then return end
    if looter ~= "me" and type(looterArg) == "string" and looterArg ~= "" and not (issecretvalue and issecretvalue(looterArg)) then
        looter = looterArg
    end
    if not reportsFor(looter) then return end
    local inst = GetInstanceInfo and GetInstanceInfo() or "Unknown"
    for link in text:gmatch("|H(item:[^|]+)|h") do
        local id = itemIdFromLink(link)
        report(inst, id, looter, id and qualityOf(id, text))
    end
end

-- Retail: boss loot also comes as an event, which still works where loot lines are hidden.
local function onEncounterLoot(_, _, itemID, itemLink, _, playerName)
    if not inGroupInstance() or type(playerName) ~= "string" or (issecretvalue and (issecretvalue(playerName) or issecretvalue(itemID))) then return end
    if not reportsFor(playerName) then return end
    local id = tonumber(itemID) or (type(itemLink) == "string" and itemIdFromLink(itemLink))
    report(GetInstanceInfo and GetInstanceInfo() or "Unknown", id, playerName, id and qualityOf(id, type(itemLink) == "string" and itemLink or ""))
end

function M:OnDrop(d, sender)
    if type(d.i) ~= "string" or type(d.id) ~= "number" then return end
    if d.id < 1 or d.id > 10000000 or d.id ~= math.floor(d.id) or #d.i > 64 then return end
    recordDrop(d.i, d.id)
end

-- Members who were offline catch up: on connecting, ask; one member who
-- knows more answers with their drop counts, which merge by the larger count.
local lastHeard, sharePending = -999, false
local function knownCount()
    local n = 0
    for _, items in pairs(db.drops) do for _ in pairs(items) do n = n + 1 end end
    for _, bosses in pairs(db.kills or {}) do for _ in pairs(bosses) do n = n + 1 end end
    for _, m in pairs(db.mobs or {}) do for _ in pairs(m.items or {}) do n = n + 1 end end
    return n
end

function M:OnDropAsk(d)
    if sharePending or knownCount() <= (tonumber(d.n) or 0) then return end
    sharePending = true
    local asked = GetTime()
    C_Timer.After(3 + math.random() * 10, function()
        sharePending = false
        if lastHeard >= asked then return end
        for inst, items in pairs(db.drops) do
            local batch = {}
            for id, e in pairs(items) do
                batch[#batch + 1] = { id, e.n or 1 }
                if #batch >= 25 then M:Send("DROPS", { i = inst, l = batch }, "ORG", nil, R.PRIORITY.BULK); batch = {} end
            end
            if #batch > 0 then M:Send("DROPS", { i = inst, l = batch }, "ORG", nil, R.PRIORITY.BULK) end
        end
        M.SendTallies()
    end)
end

function M:OnDrops(d)
    lastHeard = GetTime()
    if type(d.i) ~= "string" or type(d.l) ~= "table" or #d.i > 64 then return end
    db.drops[d.i] = db.drops[d.i] or {}
    local changed = false
    for k, it in ipairs(d.l) do
        if k > 40 then break end
        local id, n = type(it) == "table" and tonumber(it[1]), type(it) == "table" and tonumber(it[2])
        if id and n and id >= 1 and id <= 10000000 and id == math.floor(id) and n >= 1 then
            local e = db.drops[d.i][id] or { n = 0 }
            if n > (e.n or 0) then e.n, e.t = math.min(n, 9999), e.t or GetServerTime(); changed = true end
            db.drops[d.i][id] = e
        end
    end
    if changed then refreshPage() end
end

---------------------------------------------------------------------------
-- Kill and mob-loot tallies, for the Journal's reference numbers: how often
-- RUIN killed each boss (so a listed drop shows "3 of 12 kills"), and the
-- greens and blues in the loot windows of the dungeon's mobs (the General
-- list, with a drop chance per mob looted). Shared with the org like drops.
---------------------------------------------------------------------------
local function bossKey(s) return (tostring(s or ""):lower():gsub("[^%w]", "")) end

-- The dungeon's boss list (the journal's names), so encounter names that
-- differ a little ("Faldrim" vs "Faldrim Anvilmar") count for the right boss.
local function bossesOf(inst)
    local dg = M.FindDungeon and M:FindDungeon(inst)
    local out = {}
    if dg then
        for _, b in ipairs(dg.bosses or {}) do out[#out + 1] = b[1] end
        local loot = ns.Loot and ns.Loot.For(dg)
        for _, b in ipairs(loot and loot.bosses or {}) do out[#out + 1] = b.name end
    end
    return out
end

local function matchBoss(inst, name)
    local k = bossKey(name)
    if k == "" then return nil end
    for _, b in ipairs(bossesOf(inst)) do
        local bk = bossKey(b)
        if bk == k or (#k >= 4 and bk:find(k, 1, true)) or (#bk >= 4 and k:find(bk, 1, true)) then return b end
    end
    return nil
end
M.MatchBoss = matchBoss

-- The first RUIN member of your group by name reports for the group (you,
-- when you're alone or the only RUIN member), so a kill counts once.
local function iReportForGroup()
    local me = short(UnitName("player")):lower()
    local ruin = ruinNames()
    local first
    for _, n in ipairs(groupNames()) do
        local low = n:lower()
        if (ruin[low] or low == me) and (not first or low < first) then first = low end
    end
    return first == nil or first == me
end

local function recordKill(inst, boss, n)
    db.kills[inst] = db.kills[inst] or {}
    db.kills[inst][boss] = (db.kills[inst][boss] or 0) + (n or 1)
    refreshPage()
end

local recentKill = {}
local bossGUIDs = {}       -- boss corpses aren't counted as mobs
local function onBossDown(name, guid)
    if guid then bossGUIDs[guid] = true end
    if not inGroupInstance() then return end
    local inst = GetInstanceInfo and GetInstanceInfo() or "Unknown"
    local boss = matchBoss(inst, name)
    if not boss then return end
    local k = inst .. "|" .. bossKey(boss)
    if recentKill[k] and GetTime() - recentKill[k] < 300 then return end
    recentKill[k] = GetTime()
    if not iReportForGroup() then return end
    recordKill(inst, boss)
    M:Send("KILL", { i = inst, b = boss }, "ORG", nil, R.PRIORITY.BULK)
end

local function okText(s, max) return type(s) == "string" and s ~= "" and #s <= (max or 64) and not (issecretvalue and issecretvalue(s)) end

function M:OnKill(d)
    if not okText(d.i) or not okText(d.b) then return end
    recordKill(d.i, d.b)
end

-- ENCOUNTER_END (encounterID, name, difficulty, size, success)
local function onEncounterEnd(_, _, name, _, _, success)
    if success == 1 or success == true then onBossDown(name) end
end

-- WoW Forever: a boss dying in the combat log (its dungeons may have no encounters)
local function onCombatLog()
    if not CombatLogGetCurrentEventInfo then return end
    local _, sub, _, _, _, _, _, guid, name = CombatLogGetCurrentEventInfo()
    if sub ~= "UNIT_DIED" or not okText(name) or not inGroupInstance() then return end
    if type(guid) ~= "string" or (issecretvalue and issecretvalue(guid)) or not guid:find("^Creature") then return end
    local inst = GetInstanceInfo and GetInstanceInfo() or "Unknown"
    if matchBoss(inst, name) then onBossDown(name, guid) end
end

-- Mob loot windows: every corpse RUIN members open inside counts once, and
-- each green or blue in it counts as a drop from the dungeon's mobs.
local seenCorpse = {}
local pendingMobs = {}     -- inst -> { n = corpses, items = { [id] = n } } not yet sent
local flushQueued = false

local function mobsOf(inst)
    db.mobs[inst] = db.mobs[inst] or { n = 0, items = {} }
    db.mobs[inst].items = db.mobs[inst].items or {}
    return db.mobs[inst]
end

local function flushMobs()
    flushQueued = false
    for inst, p in pairs(pendingMobs) do
        local batch = {}
        for id, n in pairs(p.items) do
            batch[#batch + 1] = { id, n }
            if #batch >= 25 then M:Send("MOBS", { i = inst, n = 0, l = batch }, "ORG", nil, R.PRIORITY.BULK); batch = {} end
        end
        M:Send("MOBS", { i = inst, n = p.n, l = batch }, "ORG", nil, R.PRIORITY.BULK)
    end
    pendingMobs = {}
end
M.FlushMobs = flushMobs

local function isCorpse(guid)
    return type(guid) == "string" and not (issecretvalue and issecretvalue(guid)) and (guid:find("^Creature") or guid:find("^Vehicle")) ~= nil
end

local function onLootOpened()
    if not inGroupInstance() or not GetNumLootItems or not GetLootSlotLink then return end
    local inst = GetInstanceInfo and GetInstanceInfo() or "Unknown"
    local tguid = UnitGUID and UnitGUID("target")
    if isCorpse(tguid) and UnitName and matchBoss(inst, UnitName("target")) then bossGUIDs[tguid] = true end
    local corpses, found = {}, {}
    for slot = 1, GetNumLootItems() or 0 do
        local srcs = GetLootSourceInfo and { GetLootSourceInfo(slot) } or {}
        local guid = srcs[1]
        if not isCorpse(guid) then
            guid = (UnitIsDead and UnitIsDead("target") and isCorpse(tguid)) and tguid or nil
        end
        if guid and not bossGUIDs[guid] and not seenCorpse[guid] then
            for k = 1, #srcs, 2 do if isCorpse(srcs[k]) and not bossGUIDs[srcs[k]] then corpses[srcs[k]] = true end end
            corpses[guid] = true
            local link = GetLootSlotLink(slot)
            local id = type(link) == "string" and not (issecretvalue and issecretvalue(link)) and itemIdFromLink(link)
            local q = id and qualityOf(id, link)
            if id and (q == 2 or q == 3) then found[#found + 1] = id end
        end
    end
    local n = 0
    for guid in pairs(corpses) do seenCorpse[guid] = true; n = n + 1 end
    if n == 0 then return end
    local m = mobsOf(inst)
    pendingMobs[inst] = pendingMobs[inst] or { n = 0, items = {} }
    local p = pendingMobs[inst]
    m.n, p.n = m.n + n, p.n + n
    for _, id in ipairs(found) do
        m.items[id] = (m.items[id] or 0) + 1
        p.items[id] = (p.items[id] or 0) + 1
    end
    refreshPage()
    if not flushQueued then
        flushQueued = true
        C_Timer.After(30, flushMobs)
    end
end
M.OnLootOpened = onLootOpened

function M:OnMobs(d)
    if not okText(d.i) or type(d.l) ~= "table" then return end
    local n = tonumber(d.n) or 0
    if n < 0 or n > 500 or n ~= math.floor(n) then return end
    local m = mobsOf(d.i)
    m.n = m.n + n
    for k, it in ipairs(d.l) do
        if k > 40 then break end
        local id, c = type(it) == "table" and tonumber(it[1]), type(it) == "table" and tonumber(it[2])
        if id and c and id >= 1 and id <= 10000000 and id == math.floor(id) and c >= 1 and c <= 500 then
            m.items[id] = (m.items[id] or 0) + c
        end
    end
    refreshPage()
end

-- catch-up: totals, merged by the larger count (like drops)
function M:OnTally(d)
    lastHeard = GetTime()
    if not okText(d.i) then return end
    local changed = false
    if type(d.k) == "table" then
        db.kills[d.i] = db.kills[d.i] or {}
        for k, it in ipairs(d.k) do
            if k > 40 then break end
            local b, n = type(it) == "table" and it[1], type(it) == "table" and tonumber(it[2])
            if okText(b) and n and n >= 1 and n == math.floor(n) and n > (db.kills[d.i][b] or 0) then
                db.kills[d.i][b] = math.min(n, 99999); changed = true
            end
        end
    end
    local mn = tonumber(d.m)
    if mn or type(d.l) == "table" then
        local m = mobsOf(d.i)
        if mn and mn == math.floor(mn) and mn > m.n then m.n = math.min(mn, 9999999); changed = true end
        for k, it in ipairs(type(d.l) == "table" and d.l or {}) do
            if k > 40 then break end
            local id, n = type(it) == "table" and tonumber(it[1]), type(it) == "table" and tonumber(it[2])
            if id and n and id >= 1 and id <= 10000000 and id == math.floor(id) and n >= 1 and n > (m.items[id] or 0) then
                m.items[id] = math.min(n, 9999999); changed = true
            end
        end
    end
    if changed then refreshPage() end
end

function M.SendTallies()
    for inst, bosses in pairs(db.kills) do
        local list = {}
        for b, n in pairs(bosses) do list[#list + 1] = { b, n } end
        if #list > 0 then M:Send("TALLY", { i = inst, k = list }, "ORG", nil, R.PRIORITY.BULK) end
    end
    for inst, m in pairs(db.mobs) do
        local batch, first = {}, true
        for id, n in pairs(m.items or {}) do
            batch[#batch + 1] = { id, n }
            if #batch >= 25 then
                M:Send("TALLY", { i = inst, m = first and m.n or nil, l = batch }, "ORG", nil, R.PRIORITY.BULK)
                batch, first = {}, false
            end
        end
        if first or #batch > 0 then M:Send("TALLY", { i = inst, m = first and m.n or nil, l = batch }, "ORG", nil, R.PRIORITY.BULK) end
    end
end

local function itemInfo(id)
    if not GetItemInfo then return nil end
    local name, link, quality, _, minLevel = GetItemInfo(id)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    return name, link, quality, minLevel
end

-- For other modules (Exchange's bag sweep, Core's party dungeon signal): how
-- an item compares with your gear, counting its "Equip:" spell damage and
-- healing lines. Takes an item link or an item id. Returns a percentage,
-- "empty", "noscore", "same", or nil (unknown, or the item isn't loaded yet).
function M:Compare(link)
    if type(link) == "number" then link = "item:" .. math.floor(link) end
    if type(link) ~= "string" then return nil end
    local ok, pct = pcall(compare, link)
    if ok then return pct end
end

-- true = an upgrade for your spec, false = not, nil = Codex can't tell.
function M:IsUpgrade(link)
    local pct = self:Compare(link)
    if pct == "empty" or pct == "noscore" then return true end
    if pct == "same" then return false end
    if type(pct) == "number" then return pct >= 1 end
    return nil
end

---------------------------------------------------------------------------
-- Raid planning with RUIN Muster
---------------------------------------------------------------------------
-- Post a joint RUIN run of a dungeon (5 players) or a raid (10, 20 or 40)
-- to RUIN Muster, where everyone signs up by role.
function M:PlanRun(entry, when, size, isRaid)
    local mu = R:GetModule("Muster")
    if not mu or not mu.Create then return self:Print("Install RUIN Muster to schedule runs.") end
    if mu.CanPost and not mu:CanPost() then return self:Print("Only officers schedule runs (or switch on Muster's practice mode).") end
    if not entry then return end
    if not isRaid then size = 5 end
    local need = isRaid and (RAID_NEED[size] or RAID_NEED[20]) or { 1, 1, 3 }
    return mu:Create(entry.name, when, { kind = isRaid and "Raid" or "Dungeon", size = tostring(size),
                                         need = { need[1], need[2], need[3] },
                                         desc = ("Joint %d-player %s, planned in Codex."):format(size, entry.name) })
end

function M:PlanRaid(raid, when, size) return self:PlanRun(raid, when, size, true) end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
-- The item's link or name (never a bare ID): Core remembers names it has
-- seen, and a loot list's own name stands in until the game sends the item.
local function itemText(id, fallback)
    return R.Items.Text(id, fallback)
end

local function chanceText(it)
    return it.chance and (C.dim .. ("  %s%%"):format(it.chance % 1 == 0 and ("%d"):format(it.chance) or ("%.1f"):format(it.chance)) .. "|r") or ""
end

local function seenText(seen, id)
    local e = seen and seen[id]
    return e and ("  " .. C.good .. "looted " .. (e.n or 1) .. "x by RUIN|r") or ""
end

local function pctText(n, of)
    local p = n / of * 100
    if p >= 10 or p == math.floor(p) then return ("%d%%"):format(math.floor(p + 0.5)) end
    return ("%.1f%%"):format(p)
end

-- the reference tracker after a listed drop: "3/12 kills · 25%"
local function trackText(seen, id, kills)
    local n = id and seen and seen[id] and (seen[id].n or 1) or 0
    if kills and kills > 0 then
        return "  " .. C.dim .. ("%d/%d kill%s"):format(math.min(n, kills), kills, kills == 1 and "" or "s")
            .. " · " .. pctText(math.min(n, kills), kills) .. "|r"
    end
    return n > 0 and seenText(seen, id) or ""
end

-- An item's link for the tooltip: the game's own, or "item:<id>" (the
-- tooltip loads it from the server), or nil when only its name is known.
local function linkFor(id)
    if not id then return nil end
    local _, link = itemInfo(id)
    return link or ("item:" .. id)
end

-- A listed name the game already knows (seen in a bag, chat or the AH).
local function idByName(name)
    if type(name) ~= "string" or name == "" or not GetItemInfo then return nil end
    local _, link = GetItemInfo(name)
    return type(link) == "string" and itemIdFromLink(link) or nil
end

-- The journal page for one dungeon or raid: where it is, what's known about
-- it (quests, attunement, set, quest XP, notes), each boss with its tips and
-- the loot it drops (from loot data files), other drops, then drops RUIN
-- members looted that no list has yet.
local STATUS_TEXT = { complete = "fully documented", strong = "well documented", partial = "partly documented",
                      story_only = "story only, no boss list yet", minimal = "little published yet" }

---------------------------------------------------------------------------
-- Dungeon quests: every quest the dungeon has for your race and class, with
-- where it starts, the quests that unlock it, its rewards and whether you've
-- done it. RUIN Pathfinder reads them from Questie (or QuestieDB); without
-- them the Journal shows the launch data's quest names.
---------------------------------------------------------------------------
local STATE_TEXT = {
    done = { "Done", "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t" },
    ready = { "Ready to hand in", "|TInterface\\GossipFrame\\ActiveQuestIcon:14:14|t" },
    active = { "In your quest log", "|TInterface\\GossipFrame\\IncompleteQuestIcon:14:14|t" },
    available = { "Available", "|TInterface\\GossipFrame\\AvailableQuestIcon:14:14|t" },
    low = { "Needs level %d", "|TInterface\\GossipFrame\\AvailableQuestIcon:14:14|t" },
    locked = { "Do the quests before it first", "|TInterface\\GossipFrame\\AvailableQuestIcon:14:14|t" },
}

-- Quest rewards from Ruinous Forever Planner's dungeon lists, when it's installed.
local rewardIndex
local function questRewards(qid)
    if rewardIndex == nil then
        rewardIndex = false
        local P = rawget(_G, "RuinousForeverPlanner")
        local ed = type(P) == "table" and type(P.EfficiencyData) == "table" and P.EfficiencyData.dungeons
        if type(ed) == "table" then
            rewardIndex = {}
            for _, d in ipairs(ed) do
                for _, it in ipairs(type(d.items) == "table" and d.items or {}) do
                    local q, id = tonumber(it.questID), tonumber(it.id)
                    if q and id then
                        local list = rewardIndex[q] or {}
                        local dup = false
                        for _, x in ipairs(list) do if x.id == id then dup = true end end
                        if not dup then list[#list + 1] = { id = id, name = it.name } end
                        rewardIndex[q] = list
                    end
                end
            end
        end
    end
    return rewardIndex and rewardIndex[qid] or nil
end
M.QuestRewards = questRewards

local function questLines(lines, dg)
    local PF = R:GetModule("Pathfinder")
    local list, why
    if PF and PF.DungeonQuests then list, why = PF:DungeonQuests(dg.name) end
    lines[#lines + 1] = { " " }
    if not list then
        lines[#lines + 1] = { C.gold .. "Quests|r" }
        for _, t in ipairs(dg.quests or {}) do lines[#lines + 1] = { "    " .. C.dim .. "-|r " .. t } end
        local hint = not PF and "Install RUIN Pathfinder (with Questie) to see every quest for your faction, where it starts, the quests that unlock it, and a route through them."
            or ("Quest details: " .. tostring(why or "not available").. ".")
        lines[#lines + 1] = { "    " .. C.dim .. hint .. "|r" }
        return
    end
    local done = 0
    for _, q in ipairs(list) do if q.state == "done" then done = done + 1 end end
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "your faction"
    lines[#lines + 1] = { C.gold .. "Quests for " .. faction .. "|r  " .. C.dim .. ("%d quest%s, %d done · from Questie"):format(#list, #list == 1 and "" or "s", done) .. "|r" }
    if #list == 0 then
        lines[#lines + 1] = { "    " .. C.dim .. "Questie lists no quests here for your character yet.|r" }
        for _, t in ipairs(dg.quests or {}) do lines[#lines + 1] = { "    " .. C.dim .. "- " .. t .. " (launch data)|r" } end
        return
    end
    lines[#lines + 1] = { "    " .. C.good .. "> Open the quest route in Pathfinder|r  " .. C.dim .. "every quest here and the ones that unlock them, in order|r",
        action = function() PF:OpenDungeonRoute(dg.name) end,
        tip = { "Quest route", "Starts a Pathfinder route through every quest above: the quests that unlock them first, then the pick-ups, the run and the hand-ins." } }
    local function qname(id)
        local i = PF.QuestInfo and PF:QuestInfo(id)
        return i and i.name or ("quest " .. id)
    end
    for _, q in ipairs(list) do
        local st = STATE_TEXT[q.state] or STATE_TEXT.available
        local label = st[1]:find("%%d") and st[1]:format(q.req or 0) or st[1]
        local color = (q.state == "done" and C.good) or ((q.state == "ready" or q.state == "available") and C.white) or C.dim
        local head = "    " .. st[2] .. " " .. color .. q.name .. "|r  " .. C.dim .. "[" .. (q.level or "?") .. "]"
            .. (q.req and (" · needs level " .. q.req) or "") .. " · " .. label .. "|r"
        local where = {}
        if q.item then where[#where + 1] = "Starts from " .. q.item .. (q.inside and " (inside)" or "")
        elseif q.starts and q.starts[1] then where[#where + 1] = "Starts: " .. q.starts[1] .. (q.inside and " (inside)" or "") end
        if q.ends and q.ends[1] then where[#where + 1] = "Hand in: " .. q.ends[1] .. (q.endsInside and " (inside)" or "") end
        local tip = { q.name, q.objective or "" }
        lines[#lines + 1] = { head, quest = q.id, tip = tip }
        if #where > 0 then lines[#lines + 1] = { "        " .. C.dim .. table.concat(where, "  ·  ") .. "|r", quest = q.id, tip = tip } end
        if #q.pre > 0 then
            local chain = {}
            for _, p in ipairs(q.pre) do
                local ok = PF.QuestDone and PF:QuestDone(p)
                chain[#chain + 1] = (ok and C.good or C.white) .. qname(p) .. (ok and " (done)" or "") .. "|r"
            end
            lines[#lines + 1] = { "        " .. C.dim .. "First: |r" .. table.concat(chain, C.dim .. " > |r"), quest = q.pre[1], tip = { "Quests before " .. q.name, "Do these in order to unlock it. Click to mark the first on your map." } }
        end
        local rewards = questRewards(q.id)
        if rewards then
            for _, rw in ipairs(rewards) do
                local id = rw.id
                lines[#lines + 1] = { "        " .. C.dim .. "Reward:|r " .. itemText(id, rw.name), link = linkFor(id) }
            end
        end
    end
end

local function journalLines(dg, isRaid)

    local loot = ns.Loot and ns.Loot.For(dg)
    local seen = db.drops[dg.name]
    -- drops RUIN looted, by name, so a listed name without an ID can show the real item
    local seenByName = {}
    for id in pairs(seen or {}) do
        local name = itemInfo(id)
        if name then seenByName[name:lower()] = id end
    end
    local lines = {}
    if dg.forever then
        lines[#lines + 1] = { W.TagText("Unverified", "WoW Forever launch data") .. C.dim .. "  From the WoW Forever launch databases ("
            .. dg.forever .. ")" .. (dg.status and STATUS_TEXT[dg.status] and (", " .. STATUS_TEXT[dg.status]) or "")
            .. ". Not yet checked by RUIN. \"Looted by RUIN\" is real.|r" }
    else
        lines[#lines + 1] = { W.TagText("Sample", "WoW Classic sample") .. C.dim .. "  Level ranges, boss tips and loot lists are Classic's until RUIN records Forever's. \"Looted by RUIN\" is real.|r" }
    end
    lines[#lines + 1] = { C.gold .. dg.name .. "|r" }
    lines[#lines + 1] = { C.dim .. (isRaid and (dg.size .. " players") or ("Levels " .. dg.levels)) .. "  ·  " .. dg.where .. "|r" }
    -- what's known about the place
    local function section(title, list)
        if not list or #list == 0 then return end
        lines[#lines + 1] = { " " }
        lines[#lines + 1] = { C.gold .. title .. "|r" }
        for _, t in ipairs(list) do lines[#lines + 1] = { "    " .. C.dim .. "-|r " .. t } end
    end
    questLines(lines, dg)
    if dg.questXP then section("Quest XP", { dg.questXP }) end
    if dg.attunement then
        local a = dg.attunement
        local list = {}
        if a.alliance and a.alliance ~= "" then list[#list + 1] = "Alliance: " .. a.alliance end
        if a.horde and a.horde ~= "" then list[#list + 1] = "Horde: " .. a.horde end
        if a.note and a.note ~= "" then list[#list + 1] = C.dim .. a.note .. "|r" end
        section("Attunement", list)
    end
    if dg.set then
        local list = {}
        for _, bn in ipairs(dg.set.bonuses or {}) do list[#list + 1] = "(" .. bn[1] .. ") " .. bn[2] end
        section("Set: " .. dg.set.name .. (dg.set.pieces and (" (" .. dg.set.pieces .. " pieces)") or ""), list)
    end
    section("Notes", dg.notes)

    lines[#lines + 1] = { " " }
    lines[#lines + 1] = { C.gold .. "Bosses and loot|r" }
    local bosses = loot and loot.bosses or {}
    if #bosses == 0 then
        for _, b in ipairs(dg.bosses) do bosses[#bosses + 1] = { name = b[1], tip = b[2], items = {} } end
    end
    if #bosses == 0 then lines[#lines + 1] = { "    " .. C.dim .. "No boss list published yet.|r" } end
    local kills = db.kills[dg.name] or {}
    local function killsOf(boss)
        local k = bossKey(boss)
        for b, n in pairs(kills) do if bossKey(b) == k then return n end end
        return 0
    end
    local function itemLine(it, k)
        local id = it.id or (it.name and (seenByName[it.name:lower()] or idByName(it.name)))
        local text = id and itemText(id, it.name) or (C.white .. it.name .. "|r")
        local info = it.info and ("  " .. C.dim .. "(" .. it.info .. ")|r") or ""
        local track = (k and k > 0) and trackText(seen, id, k) or (chanceText(it) .. (id and seenText(seen, id) or ""))
        return { "    " .. C.dim .. "-|r " .. text .. info .. track, link = linkFor(id), name = it.name, info = it.info }
    end
    for _, b in ipairs(bosses) do
        local k = killsOf(b.name)
        lines[#lines + 1] = { C.white .. b.name .. "|r" .. (k > 0 and ("  " .. C.good .. "killed " .. k .. "x by RUIN|r") or "")
            .. (b.tip and ("  " .. C.dim .. b.tip .. "|r") or "") }
        for _, it in ipairs(b.items) do lines[#lines + 1] = itemLine(it, k) end
        if loot and #b.items == 0 then lines[#lines + 1] = { "    " .. C.dim .. "- no list for this boss yet|r" } end
    end
    if loot and loot.trash and #loot.trash > 0 then
        lines[#lines + 1] = { " " }
        lines[#lines + 1] = { C.gold .. "Other drops inside|r" }
        for _, it in ipairs(loot.trash) do lines[#lines + 1] = itemLine(it) end
    end
    local listed, listedNames = {}, {}
    if ns.Loot then listed, listedNames = ns.Loot.Listed(dg) end
    local function isListed(id)
        local name = itemInfo(id)
        return listed[id] or (name and listedNames[name:lower()])
    end
    -- General: greens and blues from the dungeon's mobs, counted in the loot
    -- windows RUIN members opened, with a chance per mob looted
    local mobs = db.mobs[dg.name]
    local general = {}
    for id, n in pairs(mobs and mobs.items or {}) do
        if not isListed(id) then general[#general + 1] = { id = id, n = n } end
    end
    table.sort(general, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.id < b.id end)
    lines[#lines + 1] = { " " }
    local looted = mobs and mobs.n or 0
    lines[#lines + 1] = { C.gold .. "General|r  " .. C.dim .. "greens and blues from the mobs inside"
        .. (looted > 0 and (" · " .. looted .. " mob" .. (looted == 1 and "" or "s") .. " looted by RUIN") or "") .. "|r" }
    for i, g in ipairs(general) do
        if i > 60 then
            lines[#lines + 1] = { "    " .. C.dim .. ("and %d more"):format(#general - 60) .. "|r" }
            break
        end
        lines[#lines + 1] = { "    " .. C.dim .. "-|r " .. itemText(g.id) .. "  " .. C.dim .. ("x%d"):format(g.n)
            .. (looted > 0 and (" · about " .. pctText(math.min(g.n, looted), looted) .. " per mob") or "") .. "|r", link = linkFor(g.id) }
    end
    if #general == 0 then
        lines[#lines + 1] = { "    " .. C.dim .. "Nothing yet. Greens and blues show here as RUIN members loot the mobs.|r" }
    end
    -- what RUIN looted that no list (and not General) has
    local inGeneral = {}
    for _, g in ipairs(general) do inGeneral[g.id] = true end
    local extra = {}
    for id in pairs(seen or {}) do
        if not isListed(id) and not inGeneral[id] then extra[#extra + 1] = id end
    end
    table.sort(extra, function(a, b) return (seen[a].n or 0) > (seen[b].n or 0) end)
    lines[#lines + 1] = { " " }
    lines[#lines + 1] = { C.gold .. (loot and "Also looted by RUIN members" or "Looted by RUIN members") .. "|r" }
    for _, id in ipairs(extra) do
        lines[#lines + 1] = { itemText(id) .. C.dim .. "  x" .. (seen[id].n or 1) .. "|r", link = linkFor(id) }
    end
    if #extra == 0 then
        lines[#lines + 1] = { C.dim .. (loot and "Nothing beyond the list yet." or "Nothing yet. Drops appear here as RUIN members loot them.") .. "|r" }
    end
    if loot then
        lines[#lines + 1] = { " " }
        lines[#lines + 1] = { (loot.verified and W.TagText("Verified", "Checked on Forever") or W.TagText("Unverified", "Not checked on Forever"))
            .. C.dim .. "  Loot list: " .. (loot.source or "a loot data file") .. "|r" }
    else
        lines[#lines + 1] = { " " }
        lines[#lines + 1] = { C.dim .. "No loot list for this one yet. Drops RUIN members loot appear above as they happen.|r" }
    end
    return lines
end

M.JournalLines = journalLines   -- for tests and other modules
M.UI = ui

-- Clicking an item: the full tooltip that stays open (like an item link in
-- chat); shift-click links it in chat, ctrl-click tries it on.
function M.ShowItem(link, button)
    if type(link) ~= "string" then return end
    local hyper = link:match("|H(item:[^|]+)|h") or link
    local full = link:find("|H", 1, true) and link
    if not full then
        local name, l = itemInfo(tonumber(hyper:match("^item:(%d+)")) or 0)
        full = l or ("|cffffffff|H" .. hyper .. "|h[" .. (name or "item") .. "]|h|r")
    end
    if IsModifiedClick and HandleModifiedItemClick and IsModifiedClick() then
        local ok, done = pcall(HandleModifiedItemClick, full)
        if ok and done then return end
    end
    if SetItemRef and pcall(SetItemRef, hyper, full, button or "LeftButton") then return end
    local tip = ItemRefTooltip
    if tip then
        if ShowUIPanel then pcall(ShowUIPanel, tip) end
        if not tip:IsShown() then tip:SetOwner(UIParent, "ANCHOR_PRESERVE") end
        pcall(tip.SetHyperlink, tip, hyper)
        tip:Show()
    end
end

-- Journal text: one line per entry, each as tall as its wrapped text, in a
-- scrolling column (item lines show the item's tooltip on hover).
local function detailList(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(10, 10)
    sf:SetScrollChild(child)
    local obj = { frame = sf, rows = {} }
    function obj:SetItems(lines)
        local width = math.max(120, (sf:GetWidth() or 400) - 4)
        child:SetWidth(width)
        local y = 0
        for i, line in ipairs(lines) do
            local row = self.rows[i]
            if not row then
                row = CreateFrame("Frame", nil, child)
                row.text = W.Label(row, "")
                row.text:SetPoint("TOPLEFT", 4, 0)
                row.text:SetJustifyV("TOP")
                row:EnableMouse(true)
                row:SetScript("OnEnter", function(self)
                    if not GameTooltip then return end
                    if self.tipLines then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(self.tipLines[1], 1, 1, 1)
                        if self.tipLines[2] and self.tipLines[2] ~= "" then GameTooltip:AddLine(self.tipLines[2], 0.8, 0.85, 0.95, true) end
                        if self.quest then GameTooltip:AddLine(C.dim .. "Click to mark it on your map.|r") end
                        GameTooltip:Show()
                    elseif self.link then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
                        GameTooltip:AddLine(C.dim .. "Click for the full tooltip. Shift-click to link it in chat.|r")
                        GameTooltip:Show()
                    elseif self.itemName then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(self.itemName, 1, 1, 1)
                        if self.itemInfo then GameTooltip:AddLine(self.itemInfo, 0.7, 0.7, 0.7) end
                        GameTooltip:AddLine("The game hasn't sent this item yet. Its full tooltip shows here once a RUIN member loots it or you see it in game.", 0.6, 0.6, 0.6, true)
                        GameTooltip:Show()
                    end
                end)
                row:SetScript("OnLeave", function(self) if (self.link or self.itemName or self.tipLines) and GameTooltip then GameTooltip:Hide() end end)
                row:SetScript("OnMouseUp", function(self, button)
                    if self.action then self.action()
                    elseif self.quest then
                        local PF = R:GetModule("Pathfinder")
                        if PF and PF.ShowQuestOnMap then PF:ShowQuestOnMap(self.quest) end
                    elseif self.link then M.ShowItem(self.link, button) end
                end)
                self.rows[i] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
            row.text:SetWidth(width - 8)
            row.text:SetText(line[1])
            row.link = line.link
            row.itemName, row.itemInfo = not line.link and line.name or nil, line.info
            row.quest, row.action, row.tipLines = line.quest, line.action, line.tip
            local blank = line[1] == " "
            local h = blank and 6 or math.max(14, row.text:GetStringHeight() or 14)
            row:SetHeight(h)
            row:Show()
            y = y + h + (blank and 0 or 6)
        end
        for i = #lines + 1, #self.rows do self.rows[i]:Hide() end
        child:SetHeight(math.max(10, y))
        if W.FitScrollBar then W.FitScrollBar(sf) end   -- no scroll bar when it all fits
    end
    return obj
end

local function specOptions()
    local opts = { "Auto" }
    for _, s in ipairs(ns.SpecOrder[myClass() or ""] or {}) do opts[#opts + 1] = s end
    return opts
end

-- Journal: dungeons and raids behind a Dungeons / Raids switch. Pick one on
-- the left; the right shows run planning (posted to RUIN Muster) and the
-- entry's bosses and the drops RUIN members have looted there.
local function journalEntries()
    if ui.jmode == "Raids" then return ns.Raids or {}, ui.raid or 1 end
    return ns.Dungeons or {}, ui.selected or 1
end

local function buildJournal(page)
    ui.jmode = ui.jmode or "Dungeons"
    ui.modeBtns = {}
    for i, mode in ipairs({ "Dungeons", "Raids" }) do
        local b = W.Button(page, mode, 82, function() ui.jmode = mode; refreshPage() end)
        b:SetPoint("TOPLEFT", (i - 1) * 86, 0)
        ui.modeBtns[mode] = b
    end
    -- item tooltip line settings (the upgrade line uses your spec's stat weights)
    ui.tipCheck = W.Check(page, "Tooltip upgrade line", function() return db.tooltip end, function(v) db.tooltip = v end)
    ui.tipCheck.tip = "Item tooltips say how an item compares with what you wear, weighed for your spec (spell power and other Equip: lines count)."
    ui.tipCheck:SetPoint("BOTTOMLEFT", 0, 2)
    ui.specCycle = W.Cycle(page, 172, specOptions(), function() return db.spec end, function(v) db.spec = v end, "Weights: ")
    ui.specCycle.tipTitle = "Which spec's stat weights the upgrade line uses (Auto = your talents)"
    ui.specCycle:SetPoint("BOTTOMLEFT", 0, 30)
    ui.entries = W.List(page, 28, function(row)
        row.btn = W.Button(row, "", 168)
        row.btn:SetPoint("LEFT", 0, 0)
    end, function(row, e, i)
        local _, sel = journalEntries()
        row.btn:SetText(e.name)
        if i == sel then row.btn:LockHighlight() else row.btn:UnlockHighlight() end
        row.btn:SetScript("OnClick", function()
            if ui.jmode == "Raids" then
                ui.raid = i
                ui.raidSize = e.size <= 20 and e.size or 20
            else
                ui.selected = i
            end
            refreshPage()
        end)
    end)
    ui.entries.frame:SetPoint("TOPLEFT", 0, -32)
    ui.entries.frame:SetPoint("BOTTOMLEFT", 0, 62)
    ui.entries.frame:SetWidth(176)

    local card = W.Card(page)
    card:SetPoint("TOPLEFT", 200, 0)
    card:SetPoint("RIGHT", page, "RIGHT", -4, 0)
    card:SetHeight(112)
    ui.planHeader = W.Header(card, "Plan a joint RUIN run")
    ui.planHeader:SetPoint("TOPLEFT", 8, -6)
    ui.runWhen = W.WhenPicker(card)
    ui.runWhen:SetPoint("TOPLEFT", 54, -28)
    local wl = W.Label(card, C.dim .. "Starts|r", "GameFontHighlightSmall")
    wl:SetPoint("RIGHT", ui.runWhen, "LEFT", -8, 0)
    ui.raidSize = ui.raidSize or 20
    ui.sizeBtn = W.Cycle(card, 96, { 10, 20, 40 }, function() return ui.raidSize end, function(v) ui.raidSize = v end, "Size: ")
    ui.sizeBtn:SetPoint("TOPLEFT", 54, -58)
    ui.sizeBtn.tipTitle = "How many players"
    ui.sizeFixed = W.Label(card, C.dim .. "5 players: 1 tank, 1 healer, 3 DPS|r", "GameFontHighlightSmall")
    ui.sizeFixed:SetPoint("TOPLEFT", 56, -63)
    local sl = W.Label(card, C.dim .. "Group|r", "GameFontHighlightSmall")
    sl:SetPoint("TOPLEFT", 10, -63)
    ui.runPost = W.Button(card, "Post in Muster", 120, function()
        local list, sel = journalEntries()
        local entry = list[sel]
        local at, err = ui.runWhen:GetTime()
        if not at then return M:Print("Check the start time: " .. tostring(err) .. ".") end
        if at < GetServerTime() - 60 then return M:Print("That start time has already passed.") end
        if entry and M:PlanRun(entry, at, ui.raidSize, ui.jmode == "Raids") then refreshPage() end
    end)
    ui.runPost:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -56)
    ui.questRoute = W.Button(card, "Quest route", 104, function()
        local list, sel = journalEntries()
        local entry = list[sel] or list[1]
        local PF = R:GetModule("Pathfinder")
        if entry and PF and PF.OpenDungeonRoute then PF:OpenDungeonRoute(entry.name) end
    end)
    ui.questRoute:SetPoint("RIGHT", ui.runPost, "LEFT", -6, 0)
    ui.questRoute.tip = "Open a RUIN Pathfinder route through every quest of this dungeon for your character, with the quests that unlock them."
    ui.runs = W.Label(card, "", "GameFontHighlightSmall")
    ui.runs:SetPoint("TOPLEFT", 10, -88)
    ui.runs:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    ui.runs:SetWordWrap(false)

    ui.detail = detailList(page)
    ui.detail.frame:SetPoint("TOPLEFT", 200, -120)
    ui.detail.frame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -24, 0)
end

local function refreshJournal()
    local raids = ui.jmode == "Raids"
    for mode, b in pairs(ui.modeBtns) do
        if mode == ui.jmode then b:LockHighlight() else b:UnlockHighlight() end
    end
    local list, sel = journalEntries()
    ui.entries:SetItems(list)
    local entry = list[sel] or list[1]
    ui.detail:SetItems(entry and journalLines(entry, raids) or {})
    ui.sizeBtn:SetShown(raids)
    ui.sizeFixed:SetShown(not raids)
    if raids then ui.sizeBtn.Refresh() end
    ui.tipCheck:Refresh()
    ui.specCycle.Refresh()
    local mu = R:GetModule("Muster")
    ui.runPost:SetEnabled(mu ~= nil)
    local PF = R:GetModule("Pathfinder")
    ui.questRoute:SetEnabled(PF ~= nil and PF.OpenDungeonRoute ~= nil and entry ~= nil and PF:DungeonEntry(entry.name) ~= nil)
    local runs = {}
    if mu and mu.GetUpcoming and entry then
        for _, ev in ipairs(mu:GetUpcoming()) do
            if ev.title:lower():find(entry.name:lower(), 1, true) then
                runs[#runs + 1] = ("%s (%d signed)"):format(W.WhenText(ev.at), ev.signed)
            end
        end
    end
    ui.runs:SetText(not mu and (C.dim .. "Install RUIN Muster to schedule runs and take sign-ups.|r")
        or (#runs > 0 and (C.good .. "Upcoming: |r" .. table.concat(runs, ",  ")) or (C.dim .. "No run scheduled yet.|r")))
end

local function buildPage(panel)
    ui.panel = panel
    ui.tabs = W.SubTabs(panel, { "Macros", "Journal" }, function() refreshPage() end)
    if ns.Macros then ns.Macros.Build(ui.tabs.pages[1]) end
    buildJournal(ui.tabs.pages[2])

    refreshPage = function()
        if not ui.panel:IsVisible() then return end
        local tab = ui.tabs.selected
        if tab == 1 then
            if ns.Macros then ns.Macros.Refresh() end
        elseif tab == 2 then
            refreshJournal()
        end
    end
    panel:SetScript("OnShow", function() refreshPage() end)
    ui.tabs:Select(1)
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
-- Another addon (a loot database) adds a boss loot list. See Loot.lua.
-- Looks up a dungeon or raid by name, ignoring case, punctuation and a leading "The".
local function normName(s)
    s = tostring(s or ""):lower():gsub("[^%a%d']+", " ")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^the ", ""))
end
function M:FindDungeon(name)
    local want = normName(name)
    if want == "" then return nil end
    for _, list in ipairs({ ns.Dungeons or {}, ns.Raids or {} }) do
        for _, dg in ipairs(list) do
            if normName(dg.name) == want then return dg end
        end
    end
    return nil
end
-- Codex's short name for a dungeon ("The Deadmines" -> "DM"), for RUIN Core's
-- party dungeon signal. nil when Codex doesn't know it.
function M:DungeonShort(name)
    local dg = self:FindDungeon(name)
    return dg and dg.id and tostring(dg.id):upper() or nil
end
-- Where the entrance is ("Moonbrook, Westfall"), when Codex knows it.
function M:DungeonWhere(name)
    local dg = self:FindDungeon(name)
    return dg and dg.where or nil
end

function M:AddLoot(instance, data)
    local ok, err = ns.Loot.Add(instance, data)
    if ok then refreshPage() end
    return ok, err
end

function M:OnEnable()
    if type(RUIN_CodexDB) ~= "table" then RUIN_CodexDB = {} end
    db = RUIN_CodexDB
    for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end
    -- Gear Path and best-in-slot lists moved out of Codex (a gear addon will handle them)
    db.bis, db.pathSolo, db.pathGroup, db.pathSort, db.onlyUpgrades = nil, nil, nil, nil, nil
    ns.CodexDB = function() return db end
    ns.CodexHelpers = { myClass = myClass, mySpec = mySpec, CLASSES = CLASSES }
    if ns.Macros then ns.Macros.Init(self) end
    -- a loot data addon can fill RUIN_CodexLoot = { [instance] = data, ... } before Codex loads
    if type(RUIN_CodexLoot) == "table" then
        for inst, data in pairs(RUIN_CodexLoot) do ns.Loot.Add(inst, data) end
    end

    self:Listen("DROP", "OnDrop")
    self:Listen("DROPQ", "OnDropAsk")
    self:Listen("DROPS", "OnDrops")
    self:Listen("KILL", "OnKill")
    self:Listen("MOBS", "OnMobs")
    self:Listen("TALLY", "OnTally")
    pcall(self.RegisterEvent, self, "ENCOUNTER_END", onEncounterEnd)
    pcall(self.RegisterEvent, self, "BOSS_KILL", function(_, _, name) onBossDown(name) end)
    -- Core skips the combat log on Retail, where it belongs to Blizzard's UI
    pcall(self.RegisterEvent, self, "COMBAT_LOG_EVENT_UNFILTERED", onCombatLog)
    pcall(self.RegisterEvent, self, "LOOT_OPENED", onLootOpened)
    pcall(self.RegisterEvent, self, "ENCOUNTER_LOOT_RECEIVED", onEncounterLoot)
    R:Subscribe("CHANNELS_CHANGED", function()
        C_Timer.After(15, function() if R:IsConnected() then self:Send("DROPQ", { n = knownCount() }, "ORG", nil, R.PRIORITY.BULK) end end)
    end)
    self:AddTab("Codex", buildPage)
    self:RegisterEvent("CHAT_MSG_LOOT", onLoot)
    R:Subscribe("Muster:EVENTS", function() refreshPage() end)

    -- Item names arrive from the server a moment after they're first asked for.
    local pending = false
    R:Subscribe("ITEMS_LOADED", function()
        if pending then return end
        pending = true
        C_Timer.After(0.2, function() pending = false; refreshPage() end)
    end)

    -- Opening Codex inside a dungeon jumps to that dungeon's entry.
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        local inst = GetInstanceInfo and GetInstanceInfo()
        for i, dg in ipairs(ns.Dungeons) do if dg.name == inst then ui.selected = i; ui.jmode = "Dungeons" end end
        for i, r in ipairs(ns.Raids) do if r.name == inst then ui.raid = i; ui.jmode = "Raids" end end
        flushMobs()     -- leaving a dungeon sends its mob loot now
    end)
end

function RUIN_Codex_Open() M:OpenTab() end
BINDING_HEADER_RUIN_CODEX = "RUIN Codex"
BINDING_NAME_RUIN_CODEX_OPEN = "Open Codex"

-- /codex [dungeon or raid name] | journal | raids | macros | commands | spec <name|auto>
SLASH_RUINCODEX1 = "/codex"
SlashCmdList.RUINCODEX = function(msg)
    msg = (msg or ""):lower()
    local cmd, rest = msg:match("^(%S*)%s*(.*)$")
    local tab = 1
    if cmd == "journal" or cmd == "dungeons" then tab = 2; if cmd == "dungeons" then ui.jmode = "Dungeons" end
    elseif cmd == "raids" or cmd == "raid" then tab = 2; ui.jmode = "Raids"
    elseif cmd == "macros" or cmd == "macro" then tab = 1; if ns.Macros then ns.Macros.SetMode("macros") end
    elseif cmd == "commands" or cmd == "cmds" then tab = 1; if ns.Macros then ns.Macros.SetMode("commands") end
    elseif cmd == "path" or cmd == "gear" or cmd == "bis" or cmd == "upgrades" then
        return M:Print("Gear Path and best-in-slot lists have left Codex; RUIN will work with a gear addon for them. Item tooltips still show the upgrade line.")
    elseif cmd == "spec" then
        local pick = "Auto"
        for _, s in ipairs(ns.SpecOrder[myClass() or ""] or {}) do if s:lower() == rest then pick = s end end
        db.spec = pick
        M:Print("Codex weights: " .. (pick == "Auto" and ("auto (" .. tostring(mySpec()) .. ")") or pick) .. ".")
        return
    elseif msg ~= "" then
        for i, dg in ipairs(ns.Dungeons) do
            if dg.name:lower():find(msg, 1, true) or dg.id == msg then ui.selected = i; ui.jmode = "Dungeons"; tab = 2 end
        end
        for i, r in ipairs(ns.Raids) do
            if r.name:lower():find(msg, 1, true) or r.id == msg then ui.raid = i; ui.jmode = "Raids"; tab = 2 end
        end
    end
    M:OpenTab()
    if ui.tabs then ui.tabs:Select(tab) end
    refreshPage()
end
