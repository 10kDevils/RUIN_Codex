-- RUIN Codex: new ranks onto your action bars
-- Learning a new rank of a spell at a class trainer leaves the old rank on
-- your action bars. After you learn something at a trainer, a small prompt
-- shows how many buttons have a higher rank you now know; one click puts the
-- highest rank on each of them. Macros and items aren't touched, and nothing
-- changes in combat (the game doesn't allow it): the button waits until
-- you're out. /codex ranks checks your bars at any time.
local ADDON, ns = ...
local R = RUIN_API
if not R or (R.apiLevel or 1) < 9 then return end
local W = R.Widgets
local C = W.COLORS

local RU = {}
ns.RankUp = RU

local M                     -- the Codex module, set by Init
local function db() return ns.CodexDB and ns.CodexDB() or {} end

---------------------------------------------------------------------------
-- Spells you know, highest rank by name
---------------------------------------------------------------------------
local function rankNumber(text)
    return tonumber(tostring(text or ""):match("(%d+)"))
end

local function spellName(id)
    if C_Spell and C_Spell.GetSpellName then
        local ok, n = pcall(C_Spell.GetSpellName, id)
        if ok and type(n) == "string" then return n end
    end
    if GetSpellInfo then
        local n = GetSpellInfo(id)
        if type(n) == "string" then return n end
    end
end

local function spellRank(id)
    local f = (C_Spell and C_Spell.GetSpellSubtext) or rawget(_G, "GetSpellSubtext")
    if f then
        local ok, t = pcall(f, id)
        if ok then return rankNumber(t) end
    end
end

-- name -> { id, rank } for the highest rank of every spell in your spellbook
function RU.KnownBest()
    local best = {}
    local order = 0
    local function note(id, name, sub)
        if not (id and name) or (issecretvalue and (issecretvalue(id) or issecretvalue(name))) then return end
        order = order + 1
        local rank = rankNumber(sub) or spellRank(id)
        local cur = best[name]
        -- the spellbook lists ranks lowest first: with no rank text, the later one wins
        if not cur or (rank and cur.rank and rank > cur.rank) or (not rank and not cur.rank and order > cur.order)
            or (rank and not cur.rank) then
            best[name] = { id = id, rank = rank, order = order }
        end
    end
    local SB = rawget(_G, "C_SpellBook")
    if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemInfo then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell or 1
        for line = 1, SB.GetNumSpellBookSkillLines() or 0 do
            local ok, info = pcall(SB.GetSpellBookSkillLineInfo, line)
            if ok and type(info) == "table" then
                local first = (info.itemIndexOffset or 0) + 1
                for i = first, first + (info.numSpellBookItems or 0) - 1 do
                    local ok2, it = pcall(SB.GetSpellBookItemInfo, i, bank)
                    if ok2 and type(it) == "table" and it.itemType == spellType and not it.isPassive then
                        note(it.spellID or it.actionID, it.name, it.subName)
                    end
                end
            end
        end
        return best
    end
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
        local bookType = rawget(_G, "BOOKTYPE_SPELL") or "spell"
        for tab = 1, GetNumSpellTabs() or 0 do
            local _, _, offset, num = GetSpellTabInfo(tab)
            for i = (offset or 0) + 1, (offset or 0) + (num or 0) do
                local kind, id = GetSpellBookItemInfo(i, bookType)
                if kind == "SPELL" and id then
                    local name, sub = GetSpellBookItemName and GetSpellBookItemName(i, bookType)
                    note(id, name or spellName(id), sub)
                end
            end
        end
    end
    return best
end

---------------------------------------------------------------------------
-- Buttons that hold a lower rank
---------------------------------------------------------------------------
local function lastSlot()
    return (R.client == "retail") and 180 or 120
end

-- { { slot, from = id, to = id, name, fromRank, toRank }, ... }
function RU.Changes()
    local out = {}
    if not GetActionInfo then return out end
    local best = RU.KnownBest()
    for slot = 1, lastSlot() do
        local ok, kind, id = pcall(GetActionInfo, slot)
        if ok and kind == "spell" and type(id) == "number" and not (issecretvalue and issecretvalue(id)) then
            local name = spellName(id)
            local b = name and best[name]
            if b and b.id ~= id then
                local have = spellRank(id)
                -- only ever up: a lower rank kept on purpose stays lower than the best, which is the point
                if b.rank and have and b.rank > have then
                    out[#out + 1] = { slot = slot, from = id, to = b.id, name = name, fromRank = have, toRank = b.rank }
                end
            end
        end
    end
    return out
end

-- Put the new ranks on the bars. Returns how many buttons changed.
function RU.Apply()
    if InCombatLockdown and InCombatLockdown() then return 0, "combat" end
    local pickup = (C_Spell and C_Spell.PickupSpell) or rawget(_G, "PickupSpell")
    if not (pickup and PlaceAction and ClearCursor) then return 0, "api" end
    local n = 0
    for _, ch in ipairs(RU.Changes()) do
        ClearCursor()
        local ok = pcall(pickup, ch.to)
        if ok and (not GetCursorInfo or GetCursorInfo() == "spell") then
            pcall(PlaceAction, ch.slot)
            n = n + 1
        end
        ClearCursor()
    end
    return n
end

---------------------------------------------------------------------------
-- The prompt
---------------------------------------------------------------------------
local f

local function summary(changes)
    local byName, names = {}, {}
    for _, ch in ipairs(changes) do
        local e = byName[ch.name]
        if not e then
            e = { name = ch.name, to = ch.toRank, n = 0 }
            byName[ch.name] = e
            names[#names + 1] = e
        end
        e.n = e.n + 1
    end
    table.sort(names, function(a, b) return a.name < b.name end)
    return names
end

local function paint()
    if not f then return end
    local changes = RU.Changes()
    if #changes == 0 then f:Hide(); return end
    local list = summary(changes)
    local parts = {}
    for i, e in ipairs(list) do
        if i > 3 then parts[#parts + 1] = ("and %d more"):format(#list - 3); break end
        parts[#parts + 1] = ("%s (Rank %d)"):format(e.name, e.to)
    end
    f.text:SetText(("%d action %s can use ranks you've learned: %s."):format(#changes,
        #changes == 1 and "button" or "buttons", table.concat(parts, ", ")))
    local tip = {}
    for _, e in ipairs(list) do
        tip[#tip + 1] = ("%s to Rank %d%s"):format(e.name, e.to, e.n > 1 and (" (" .. e.n .. " buttons)") or "")
    end
    f.go.tip = "Puts the highest rank you know on these buttons:\n" .. table.concat(tip, "\n")
    local combat = InCombatLockdown and InCombatLockdown()
    f.go:SetEnabled(not combat)
    f.go:SetText(combat and "Leave combat first" or "Update action bars")
    local h = 33 + 12 + (f.text:GetStringHeight() or 28) + 12 + 24 + 12
    f:SetHeight(h)
    f:Show()
end

local function build()
    if f then return f end
    local store = db()
    f = W.HudFrame("RUIN_CodexRankUp", "Codex", store, "rankUpPos", { "TOP", UIParent, "TOP", 0, -160 })
    f:SetSize(320, 130)
    f:SetFrameStrata("DIALOG")
    local top = W.HudHeader(f, "New ranks learned")
    local close = W.CloseButton(f, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", -6, -6)
    f.text = W.Label(f, "", "GameFontHighlightSmall")
    f.text:SetPoint("TOPLEFT", 12, -top - 10)
    f.text:SetPoint("RIGHT", f, "RIGHT", -12, 0)
    f.text:SetJustifyH("LEFT")
    f.text:SetWordWrap(true)
    f.go = W.Button(f, "Update action bars", 170, function()
        local n, why = RU.Apply()
        if why == "combat" then paint(); return end
        if n > 0 and M then M:Print(("Updated %d action %s to your newest ranks."):format(n, n == 1 and "button" or "buttons")) end
        paint()
        if f:IsShown() and #RU.Changes() == 0 then f:Hide() end
    end)
    f.go:SetPoint("BOTTOM", 0, 12)
    f:Hide()
    return f
end

-- Look at your bars and show the prompt when something can move up a rank.
-- manual: from /codex ranks, which also says when everything is current.
function RU.Check(manual)
    build()
    local changes = RU.Changes()
    if #changes == 0 then
        f:Hide()
        if manual and M then M:Print("Your action bars already have the highest ranks you know.") end
        return
    end
    paint()
end

---------------------------------------------------------------------------
-- Watching the trainer
---------------------------------------------------------------------------
local trainerOpen, lastTrainer = false, 0
local checkQueued = false
local function queueCheck()
    if checkQueued or not C_Timer then return end
    checkQueued = true
    -- the spellbook updates a moment after the learn event
    C_Timer.After(1, function() checkQueued = false; RU.Check(false) end)
end

local function learned()
    if trainerOpen or (GetTime and GetTime() - lastTrainer < 30) then queueCheck() end
end

function RU.Init(module)
    M = module
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "TRAINER_SHOW", "TRAINER_CLOSED", "LEARNED_SPELL_IN_TAB", "LEARNED_SPELL_IN_SKILL_LINE",
                         "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", function(_, e)
        if e == "TRAINER_SHOW" then trainerOpen = true
        elseif e == "TRAINER_CLOSED" then
            trainerOpen = false
            lastTrainer = GetTime and GetTime() or 0
        elseif e == "LEARNED_SPELL_IN_TAB" or e == "LEARNED_SPELL_IN_SKILL_LINE" then learned()
        elseif (e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_REGEN_DISABLED") and f and f:IsShown() then paint() end
    end)
end
