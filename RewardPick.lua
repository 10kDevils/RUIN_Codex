-- RUIN Codex: the best quest reward for you (RewardPick)
-- When a quest hands out a choice of rewards, Codex weighs each one against
-- what you wear (the same comparison as its tooltips, or Ruinous Forever
-- Planner's when it's loaded), marks the best upgrade on the reward screen
-- and says so in chat. When none is an upgrade it marks the one that sells
-- for the most instead. It never picks for you.
local ADDON, ns = ...
local R = RUIN_API
if not R then return end
local W = R.Widgets
local C = W.COLORS

local QR = {}
ns.RewardPick = QR

local function codex() return R:GetModule("Codex") end

-- the reward buttons on the quest frame (Classic's names; newer clients keep them on RewardButtons)
local function rewardButton(i)
    local f = QuestInfoRewardsFrame
    if f and f.RewardButtons and f.RewardButtons[i] then return f.RewardButtons[i] end
    return _G["QuestInfoRewardsFrameQuestInfoItem" .. i] or _G["QuestInfoItem" .. i]
end

-- Weigh the choices: { best = i, pct = number|"empty"|nil, slot, sell = i, list = { { link, pct, slot, price, usable } } }
function QR.Weigh()
    local n = GetNumQuestChoices and GetNumQuestChoices() or 0
    if n < 2 then return nil end
    local cx = codex()
    local out = { list = {} }
    local bestScore, bestPrice
    for i = 1, n do
        local link = GetQuestItemLink and GetQuestItemLink("choice", i)
        local e = { link = link }
        if link then
            local id = tonumber(link:match("item:(%d+)"))
            local usable = not (cx and cx.CanUse) or cx.CanUse(id) ~= false
            e.usable = usable
            if usable and cx and cx.Compare then
                local ok, pct, slot = pcall(cx.Compare, cx, link)
                if ok then e.pct, e.slot = pct, slot end
            end
            local okp, _, _, _, _, _, _, _, _, _, _, price = pcall(GetItemInfo, link)
            e.price = okp and tonumber(price) or 0
            -- an empty slot or a slot whose item has no stats counts as a big upgrade
            local rank = type(e.pct) == "number" and e.pct or (e.pct == "empty" or e.pct == "noscore") and 1000 or nil
            if rank and rank >= 1 and (not bestScore or rank > bestScore) then bestScore, out.best = rank, i end
            if not bestPrice or e.price > bestPrice then bestPrice, out.sell = e.price, i end
        end
        out.list[i] = e
    end
    if out.best then
        local b = out.list[out.best]
        out.pct, out.slot = b.pct, b.slot
    end
    return out
end

local marks = {}
local function mark(i, text, good)
    local b = rewardButton(i)
    if not b then return end
    local m = marks[i]
    if not m then
        m = CreateFrame("Frame", nil, b)
        m:SetSize(64, 16)
        m:SetPoint("TOPRIGHT", b, "TOPRIGHT", -2, 2)
        m:SetFrameLevel((b.GetFrameLevel and b:GetFrameLevel() or 1) + 5)
        m.bg = m:CreateTexture(nil, "BACKGROUND")
        m.bg:SetAllPoints()
        m.text = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        m.text:SetPoint("CENTER")
        marks[i] = m
    end
    if good then m.bg:SetColorTexture(0.10, 0.45, 0.12, 0.9) else m.bg:SetColorTexture(0.45, 0.36, 0.08, 0.9) end
    m.text:SetText(text)
    m:Show()
end
local function clearMarks() for _, m in pairs(marks) do m:Hide() end end

local function slotName(slot)
    if type(slot) == "string" then return slot end
    local cx = codex()
    return (cx and cx.SlotName and cx.SlotName(slot)) or "gear"
end

-- the reward screen opened
function QR.Show()
    clearMarks()
    local w = QR.Weigh()
    if not w then return nil end
    local cx = codex()
    if w.best then
        local label = type(w.pct) == "number" and ("+" .. math.floor(w.pct + 0.5) .. "%") or "NEW"
        mark(w.best, label, true)
        local link = w.list[w.best].link
        local why = type(w.pct) == "number" and ("+%d%% over your %s"):format(math.floor(w.pct + 0.5), slotName(w.slot))
            or ("nothing worn in your %s"):format(slotName(w.slot))
        if cx and cx.Print then cx:Print(("Best reward for you: %s (%s)."):format(link, why)) end
    elseif w.sell and (w.list[w.sell].price or 0) > 0 then
        mark(w.sell, "SELL", false)
        if cx and cx.Print then
            cx:Print(("No reward is an upgrade for you; %s sells for the most."):format(w.list[w.sell].link))
        end
    end
    return w
end

function QR.Init(module)
    module:RegisterEvent("QUEST_COMPLETE", function() C_Timer.After(0.1, function() pcall(QR.Show) end) end)
    module:RegisterEvent("QUEST_FINISHED", clearMarks)
end
