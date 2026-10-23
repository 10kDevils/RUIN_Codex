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

local M = R:RegisterModule("Codex", { version = "0.4.0" })
ns.Codex = M

local DEFAULTS = { drops = {}, tooltip = true, spec = "Auto", installed = {} }
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
    return ns.ItemStats.Score(stats, w, class, spec)
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
    R.Items.RememberLinks(text)
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

local function itemInfo(id)
    if not GetItemInfo then return nil end
    local name, link, quality, _, minLevel = GetItemInfo(id)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    return name, link, quality, minLevel
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

-- The journal page for one dungeon or raid: where it is, each boss with the
-- loot it drops (from loot data files), other drops, then drops RUIN members
-- looted that no list has yet.
local function journalLines(dg, isRaid)
    local loot = ns.Loot and ns.Loot.For(dg)
    local lines = {
        { W.TagText("Sample", "WoW Classic sample") .. C.dim .. "  Level ranges, boss tips and loot lists are Classic's until RUIN records Forever's. \"Looted by RUIN\" is real.|r" },
        { C.gold .. dg.name .. "|r" },
        { C.dim .. (isRaid and (dg.size .. " players") or ("Levels " .. dg.levels)) .. "  ·  " .. dg.where .. "|r" },
        { " " },
        { C.gold .. "Bosses and loot|r" },
    }
    local seen = db.drops[dg.name]
    local bosses = loot and loot.bosses or {}
    if #bosses == 0 then
        for _, b in ipairs(dg.bosses) do bosses[#bosses + 1] = { name = b[1], tip = b[2], items = {} } end
    end
    for _, b in ipairs(bosses) do
        lines[#lines + 1] = { C.white .. b.name .. "|r" .. (b.tip and ("  " .. C.dim .. b.tip .. "|r") or "") }
        for _, it in ipairs(b.items) do
            local _, link = itemInfo(it.id)
            lines[#lines + 1] = { "    " .. C.dim .. "-|r " .. itemText(it.id, it.name) .. chanceText(it) .. seenText(seen, it.id), link = link }
        end
        if loot and #b.items == 0 then lines[#lines + 1] = { "    " .. C.dim .. "- no list for this boss yet|r" } end
    end
    if loot and loot.trash and #loot.trash > 0 then
        lines[#lines + 1] = { " " }
        lines[#lines + 1] = { C.gold .. "Other drops inside|r" }
        for _, it in ipairs(loot.trash) do
            local _, link = itemInfo(it.id)
            lines[#lines + 1] = { "    " .. C.dim .. "-|r " .. itemText(it.id, it.name) .. chanceText(it) .. seenText(seen, it.id), link = link }
        end
    end
    -- what RUIN looted that no list has
    local listed = ns.Loot and ns.Loot.Listed(dg) or {}
    local extra = {}
    for id in pairs(seen or {}) do if not listed[id] then extra[#extra + 1] = id end end
    table.sort(extra, function(a, b) return (seen[a].n or 0) > (seen[b].n or 0) end)
    lines[#lines + 1] = { " " }
    lines[#lines + 1] = { C.gold .. (loot and "Also looted by RUIN members" or "Looted by RUIN members") .. "|r" }
    for _, id in ipairs(extra) do
        local _, link = itemInfo(id)
        lines[#lines + 1] = { itemText(id) .. C.dim .. "  x" .. (seen[id].n or 1) .. "|r", link = link }
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
        lines[#lines + 1] = { C.dim .. "No loot list for this one yet. Loot lists come from data files (see LootSample.lua).|r" }
    end
    return lines
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
                    if self.link and GameTooltip then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
                        GameTooltip:Show()
                    end
                end)
                row:SetScript("OnLeave", function(self) if self.link and GameTooltip then GameTooltip:Hide() end end)
                self.rows[i] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
            row.text:SetWidth(width - 8)
            row.text:SetText(line[1])
            row.link = line.link
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
