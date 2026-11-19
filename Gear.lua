-- RUIN Codex: Best in Slot
-- Your character in the middle, and for every slot the best piece you can
-- get and wear at your level: dungeon and raid loot from the Journal's lists
-- (boss drops, trash, dungeon quest rewards Ruinous Forever Planner knows),
-- plus what you're wearing now. An item counts when your class can use it
-- and its required level is yours or lower. Pieces are scored by Ruinous
-- Forever Planner when it's installed, else by Codex's stat weights for your
-- spec. Two-handers are weighed against the best main hand and off hand
-- together.
local ADDON, ns = ...
local R = RUIN_API
if not R or (R.apiLevel or 1) < 9 then return end
local W = R.Widgets
local C = W.COLORS

local GetItemInfo = function(...)
    local f = GetItemInfo or (C_Item and C_Item.GetItemInfo)
    if f then return f(...) end
end

local G = {}
ns.Gear = G

local function M() return ns.Codex end

---------------------------------------------------------------------------
-- Slots
---------------------------------------------------------------------------
-- inventory slot id -> the game's slot name (for its empty-slot picture) and a label
local SLOT_INFO = {
    [1] = { "HeadSlot", "Head" }, [2] = { "NeckSlot", "Neck" }, [3] = { "ShoulderSlot", "Shoulders" },
    [15] = { "BackSlot", "Back" }, [5] = { "ChestSlot", "Chest" }, [9] = { "WristSlot", "Wrists" },
    [10] = { "HandsSlot", "Hands" }, [6] = { "WaistSlot", "Waist" }, [7] = { "LegsSlot", "Legs" },
    [8] = { "FeetSlot", "Feet" }, [11] = { "Finger0Slot", "Ring" }, [12] = { "Finger1Slot", "Ring" },
    [13] = { "Trinket0Slot", "Trinket" }, [14] = { "Trinket1Slot", "Trinket" },
    [16] = { "MainHandSlot", "Main Hand" }, [17] = { "SecondaryHandSlot", "Off Hand" }, [18] = { "RangedSlot", "Ranged" },
}
local LEFT = { 1, 2, 3, 15, 5, 9 }
local RIGHT = { 10, 6, 7, 8, 11, 12, 13, 14 }
G.LEFT, G.RIGHT = LEFT, RIGHT

-- which group an equip location competes in
local SINGLE = { INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5, INVTYPE_ROBE = 5,
                 INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
                 INVTYPE_CLOAK = 15 }
local function groupOf(loc)
    if SINGLE[loc] then return SINGLE[loc] end
    if loc == "INVTYPE_FINGER" then return "ring" end
    if loc == "INVTYPE_TRINKET" then return "trinket" end
    if loc == "INVTYPE_2HWEAPON" then return "2h" end
    if loc == "INVTYPE_WEAPON" then return "1h" end
    if loc == "INVTYPE_WEAPONMAINHAND" then return "mh" end
    if loc == "INVTYPE_WEAPONOFFHAND" then return "ohw" end
    if loc == "INVTYPE_SHIELD" or loc == "INVTYPE_HOLDABLE" then return "oh" end
    if loc == "INVTYPE_RANGED" or loc == "INVTYPE_RANGEDRIGHT" or loc == "INVTYPE_THROWN" or loc == "INVTYPE_RELIC" then
        -- no ranged slot on this client: bows and guns go in the main hand, two-handed
        local S = M() and M().SLOTS
        if S and S.INVTYPE_RANGED and S.INVTYPE_RANGED[1] ~= 18 then
            return loc == "INVTYPE_RELIC" and nil or "2h"
        end
        return "ranged"
    end
    return nil
end
G.GroupOf = groupOf
function G.HasRangedSlot()
    local S = M() and M().SLOTS
    return not (S and S.INVTYPE_RANGED and S.INVTYPE_RANGED[1] ~= 18)
end

---------------------------------------------------------------------------
-- Scoring
---------------------------------------------------------------------------
local function planner()
    local P = rawget(_G, "RuinousForeverPlanner")
    if type(P) == "table" and type(P.ItemDetails) == "function" and type(P.WeightedStatScore) == "function" then return P end
end

local scores = {}          -- spec key -> { [id] = score or false }
local function scoreKey()
    local cm = M()
    local spec = cm and cm.MySpec and cm.MySpec() or "?"
    local lvl = UnitLevel and UnitLevel("player") or 0
    return (planner() and "rfp:" or "codex:") .. tostring(spec) .. ":" .. tostring(lvl)
end
local function scoreOf(id, link, key)
    local t = scores[key]
    if not t then t = {}; scores[key] = t end
    local v = t[id]
    if v ~= nil then return v or nil end
    local s
    local P = planner()
    if P then
        local ok, d = pcall(P.ItemDetails, link)
        if ok and type(d) == "table" and type(d.stats) == "table" then
            local ok2, n = pcall(P.WeightedStatScore, d.stats)
            if ok2 and type(n) == "number" then s = n end
        end
    end
    if s == nil then
        local cm = M()
        local ok, n = pcall(cm.Score, link)
        if ok and type(n) == "number" then s = n end
    end
    t[id] = s or false
    return s
end
function G.Forget() scores = {} end

---------------------------------------------------------------------------
-- Where items come from
---------------------------------------------------------------------------
local function lowLevel(dg) return tonumber((dg.levels or ""):match("^(%d+)")) or 0 end

-- every candidate: { id, src = { "Boss, Dungeon", ... } }
local function gather(level)
    local out, seen = {}, {}
    local function add(id, src)
        id = tonumber(id)
        if not id then return end
        local c = seen[id]
        if c then
            if #c.src < 3 then c.src[#c.src + 1] = src end
            return
        end
        c = { id = id, src = { src } }
        seen[id] = c
        out[#out + 1] = c
    end
    local loot = ns.Loot and ns.Loot.For
    for _, list in ipairs({ ns.Dungeons or {}, ns.Raids or {} }) do
        for _, dg in ipairs(list) do
            -- a place far above you has nothing you can wear yet
            if lowLevel(dg) <= level + 3 and loot then
                local ok, d = pcall(loot, dg)
                if ok and type(d) == "table" then
                    for _, b in ipairs(d.bosses or {}) do
                        for _, it in ipairs(b.items or {}) do
                            if it.id and not it.quest then add(it.id, tostring(b.name) .. ", " .. dg.name) end
                        end
                    end
                    for _, it in ipairs(d.trash or {}) do
                        if it.id and not it.quest then add(it.id, "Trash in " .. dg.name) end
                    end
                end
            end
        end
    end
    -- dungeon quest rewards and drops Ruinous Forever Planner lists
    local P = rawget(_G, "RuinousForeverPlanner")
    local ed = type(P) == "table" and type(P.EfficiencyData) == "table" and P.EfficiencyData.dungeons
    for _, d in ipairs(type(ed) == "table" and ed or {}) do
        if (tonumber(d.min) or 0) <= level + 3 then
            for _, it in ipairs(type(d.items) == "table" and d.items or {}) do
                local where = tostring(d.name or "a dungeon")
                if it.questID then add(it.id, "Quest reward, " .. where)
                elseif it.boss then add(it.id, tostring(it.boss) .. ", " .. where)
                else add(it.id, where) end
            end
        end
    end
    -- what you wear counts too: it's yours already
    if GetInventoryItemLink then
        for slot in pairs(SLOT_INFO) do
            local l = GetInventoryItemLink("player", slot)
            local id = l and tonumber(l:match("item:(%d+)"))
            if id then
                add(id, "Equipped")
                seen[id].link = l
                seen[id].worn = true
            end
        end
    end
    return out
end
G.Gather = gather

---------------------------------------------------------------------------
-- Picking the best
---------------------------------------------------------------------------
local state = { running = false, dirty = false, result = nil, waiting = 0 }
G.state = state
local CHUNK = 60

local function asked(id)
    if R.Items and R.Items.IsCached and not R.Items.IsCached(id) then
        if R.Items.Request then R.Items.Request(id) end
        return true
    end
    return false
end

-- one candidate's facts, or nil when it can't be worn now (or isn't loaded)
local function judge(c, level, key)
    local cm = M()
    local name, link, quality, _, minLevel, _, _, _, loc = GetItemInfo(c.link or c.id)
    if not name then
        asked(c.id)
        return nil, true
    end
    if not c.worn then
        if (tonumber(minLevel) or 0) > level then return nil end
        if (tonumber(quality) or 0) < 1 then return nil end
        if cm.CanUse(c.id) ~= true then return nil end
    end
    local group = groupOf(loc)
    if not group then return nil end
    local s = scoreOf(c.id, c.link or link, key)
    if not s or s <= 0 then return nil end
    return { id = c.id, link = c.link or link, name = name, quality = quality, loc = loc, group = group,
             score = s, src = c.src, worn = c.worn, minLevel = minLevel }
end

local function best(list, skip)
    local top
    for _, e in ipairs(list or {}) do
        if not (skip and skip[e.id]) and (not top or e.score > top.score) then top = e end
    end
    return top
end

local function pick(byGroup)
    local cm = M()
    local out = {}
    for _, slot in pairs(SINGLE) do out[slot] = best(byGroup[slot]) end
    local r1 = best(byGroup.ring)
    out[11] = r1
    out[12] = best(byGroup.ring, r1 and { [r1.id] = true })
    local t1 = best(byGroup.trinket)
    out[13] = t1
    out[14] = best(byGroup.trinket, t1 and { [t1.id] = true })
    if G.HasRangedSlot() then out[18] = best(byGroup.ranged) end
    -- weapons: a two-hander, or the best main hand with the best off hand
    local mainList = {}
    for _, g in ipairs({ "1h", "mh" }) do for _, e in ipairs(byGroup[g] or {}) do mainList[#mainList + 1] = e end end
    local mh = best(mainList)
    local dual = cm.CanDualWield and cm.CanDualWield()
    local offList = {}
    for _, e in ipairs(byGroup.oh or {}) do offList[#offList + 1] = e end
    if dual then
        for _, g in ipairs({ "1h", "ohw" }) do for _, e in ipairs(byGroup[g] or {}) do offList[#offList + 1] = e end end
    end
    local oh = best(offList, mh and { [mh.id] = true })
    local th = best(byGroup["2h"])
    local pair = (mh and mh.score or 0) + (oh and oh.score or 0)
    if th and th.score >= pair then
        out[16], out[17], out.twoHand = th, nil, true
    else
        out[16], out[17] = mh, oh
    end
    return out
end

-- Works through every candidate a few dozen a frame, then calls done().
function G.Compute(done)
    if state.running then state.dirty = true; return end
    local cm = M()
    if not cm then return end
    if cm.DungeonLoot and cm.DungeonLoot.Start then pcall(cm.DungeonLoot.Start) end
    state.running, state.dirty = true, false
    local level = (UnitLevel and UnitLevel("player")) or 1
    local key = scoreKey()
    local cands = gather(level)
    local byGroup, waiting, i = {}, 0, 1
    state.total, state.done = #cands, 0
    local function finish()
        state.running = false
        state.result = { slots = pick(byGroup), level = level, waiting = waiting, total = #cands,
                         by = planner() and "Ruinous Forever Planner" or "Codex's stat weights",
                         spec = cm.MySpec and cm.MySpec() }
        state.waiting = waiting
        if done then pcall(done) end
        if state.dirty then C_Timer.After(0.5, function() G.Compute(done) end) end
    end
    local function step()
        local stop = math.min(i + CHUNK - 1, #cands)
        while i <= stop do
            local ok, e, pending = pcall(judge, cands[i], level, key)
            if ok and e then
                local l = byGroup[e.group] or {}
                l[#l + 1] = e
                byGroup[e.group] = l
            elseif ok and pending then
                waiting = waiting + 1
            end
            i = i + 1
        end
        state.done = i - 1
        if i <= #cands and C_Timer then C_Timer.After(0, step) else finish() end
    end
    step()
end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
local ui = {}
G.UI = ui

local QUALITY_FALLBACK = { [0] = "ff9d9d9d", "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee", "ffff8000" }
-- "|cffrrggbb" for an item quality
local function qualityColor(q)
    local h
    if R.Items and R.Items.QualityHex then
        local ok, v = pcall(R.Items.QualityHex, q)
        if ok and type(v) == "string" then h = v end
    end
    h = h or QUALITY_FALLBACK[q or 1] or "ffffffff"
    if h:sub(1, 2) ~= "|c" then h = "|c" .. h end
    return h
end
local function qualityRGB(q)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q or 1]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function itemIcon(id)
    if C_Item and C_Item.GetItemIconByID then
        local ok, t = pcall(C_Item.GetItemIconByID, id)
        if ok and t then return t end
    end
    if GetItemIcon then return GetItemIcon(id) end
    return select(10, GetItemInfo(id))
end

local function emptyTexture(slot)
    local info = SLOT_INFO[slot]
    if info and GetInventorySlotInfo then
        local ok, _, tex = pcall(GetInventorySlotInfo, info[1])
        if ok and tex then return tex end
    end
    return "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
end

-- how the best piece stands against what you wear in that slot
local function verdict(slot, e, res)
    if not e then return C.dim .. "Nothing found yet|r" end
    local worn = GetInventoryItemLink and GetInventoryItemLink("player", slot)
    local wornId = worn and tonumber(worn:match("item:(%d+)"))
    if wornId == e.id then return C.good .. "Equipped|r" end
    if e.worn then return C.dim .. "Wearing it in another slot|r" end
    return C.dim .. table.concat(e.src, "; ") .. "|r"
end

local function slotWidget(parent, slot, side)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(36, 36)
    b.slot = slot
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.edge = b:CreateTexture(nil, "OVERLAY")
    b.edge:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.edge:SetBlendMode("ADD")
    b.edge:SetSize(64, 64)
    b.edge:SetPoint("CENTER")
    b.edge:Hide()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b.name = W.Label(parent, "", "GameFontNormalSmall")
    b.sub = W.Label(parent, "", "GameFontHighlightSmall")
    for _, fs in ipairs({ b.name, b.sub }) do
        fs:SetWordWrap(false)
        fs:SetWidth(side == "bottom" and 150 or 190)
    end
    if side == "right" then
        b.name:SetPoint("TOPRIGHT", b, "TOPLEFT", -6, -2)
        b.sub:SetPoint("TOPRIGHT", b.name, "BOTTOMRIGHT", 0, -2)
        b.name:SetJustifyH("RIGHT"); b.sub:SetJustifyH("RIGHT")
    else
        b.name:SetPoint("TOPLEFT", b, "TOPRIGHT", 6, -2)
        b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -2)
        b.name:SetJustifyH("LEFT"); b.sub:SetJustifyH("LEFT")
    end
    b:SetScript("OnEnter", function(self)
        local e = self.entry
        if not (e and GameTooltip) then return end
        GameTooltip:SetOwner(self, side == "right" and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
        pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("RUIN Codex: best in slot", 0.9, 0.7, 0.4)
        for _, s in ipairs(e.src or {}) do GameTooltip:AddLine(s, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnClick", function(self, button)
        local cm = M()
        if self.entry and cm and cm.ShowItem then cm.ShowItem(self.entry.link, button) end
    end)
    return b
end

local function paintSlot(b, e, res)
    b.entry = e
    if e then
        b.icon:SetTexture(itemIcon(e.id) or emptyTexture(b.slot))
        b.icon:SetDesaturated(false)
        local r, g, bl = qualityRGB(e.quality)
        b.edge:SetVertexColor(r, g, bl, 0.8)
        b.edge:SetShown((e.quality or 1) >= 2)
        b.name:SetText(qualityColor(e.quality) .. e.name .. "|r")
        b.sub:SetText(verdict(b.slot, e, res))
    else
        b.icon:SetTexture(emptyTexture(b.slot))
        b.icon:SetDesaturated(true)
        b.edge:Hide()
        local label = SLOT_INFO[b.slot] and SLOT_INFO[b.slot][2] or ""
        if b.slot == 17 and res and res.slots.twoHand then
            b.name:SetText(C.dim .. "Off Hand|r")
            b.sub:SetText(C.dim .. "Two-hander in the main hand|r")
        elseif b.slot == 18 and not G.HasRangedSlot() then
            b.name:SetText(C.dim .. "Ranged|r")
            b.sub:SetText(C.dim .. "Goes in the main hand here|r")
        else
            b.name:SetText(C.dim .. label .. "|r")
            b.sub:SetText(C.dim .. (res and "Nothing found yet" or "") .. "|r")
        end
    end
end

-- the model wears your best pieces, or your own gear
local DRESS_ORDER = { 1, 3, 15, 5, 9, 10, 6, 7, 8, 16, 17, 18 }
local function dressModel(force)
    local m = ui.model
    if not m then return end
    local res = state.result
    local wearBis = res and ui.preview ~= "Your gear"
    local sig = "gear"
    if wearBis then
        local ids = {}
        for _, slot in ipairs(DRESS_ORDER) do local e = res.slots[slot]; ids[#ids + 1] = e and e.id or 0 end
        sig = table.concat(ids, ",")
    end
    if sig == ui.dressed and not force then return end      -- already wearing it: no reload, no flicker
    ui.dressed = sig
    if not wearBis then
        if m.Dress then pcall(m.Dress, m) end
        return
    end
    if m.Undress then pcall(m.Undress, m) end
    for _, slot in ipairs(DRESS_ORDER) do
        local e = res.slots[slot]
        if e and m.TryOn then pcall(m.TryOn, m, e.link) end
    end
end

-- A color gradient on a texture (newer clients take colors, older alphas).
-- Vertical: from the bottom color to the top one; horizontal: left to right.
local function gradient(t, orient, a, b)
    t:SetColorTexture(1, 1, 1, 1)
    if t.SetGradient and CreateColor then
        local ok = pcall(t.SetGradient, t, orient, CreateColor(a[1], a[2], a[3], a[4]), CreateColor(b[1], b[2], b[3], b[4]))
        if ok then return end
    end
    if t.SetGradientAlpha then
        t:SetGradientAlpha(orient, a[1], a[2], a[3], a[4], b[1], b[2], b[3], b[4])
    else
        t:SetColorTexture(a[1], a[2], a[3], (a[4] + b[4]) / 2)
    end
end

-- The stage behind the character: a dark panel lit from below in Codex's
-- color, darker toward the top and the sides, with a soft glowing floor line.
local function buildStage(page)
    local stage = CreateFrame("Frame", nil, page)
    stage:SetPoint("TOPLEFT", page, "TOPLEFT", 250, -36)
    stage:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -250, 58)
    W.Skin(stage, "bg", 0.9, "line")
    local ok, scheme = pcall(W.SchemeOf, page)
    local ac = (ok and scheme and scheme.accent) or W.PALETTE.glow or { 0.6, 0.45, 0.9 }
    local r, g, b = ac[1], ac[2], ac[3]
    local function layer(sub)
        local t = stage:CreateTexture(nil, "BACKGROUND", nil, sub)
        return t
    end
    -- light rising from the floor
    local rise = layer(-5)
    rise:SetPoint("BOTTOMLEFT", 1, 1)
    rise:SetPoint("BOTTOMRIGHT", -1, 1)
    rise:SetPoint("TOP", stage, "CENTER", 0, 40)
    gradient(rise, "VERTICAL", { r, g, b, 0.34 }, { r, g, b, 0 })
    -- a faint wash over the whole stage
    local wash = layer(-6)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    gradient(wash, "VERTICAL", { r * 0.35, g * 0.35, b * 0.35, 0.5 }, { 0, 0, 0, 0 })
    -- darker toward the top
    local top = layer(-4)
    top:SetPoint("TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", -1, -1)
    top:SetPoint("BOTTOM", stage, "CENTER", 0, 30)
    gradient(top, "VERTICAL", { 0, 0, 0, 0 }, { 0, 0, 0, 0.45 })
    -- and toward the sides
    local left = layer(-3)
    left:SetPoint("TOPLEFT", 1, -1)
    left:SetPoint("BOTTOMLEFT", 1, 1)
    left:SetWidth(46)
    gradient(left, "HORIZONTAL", { 0, 0, 0, 0.5 }, { 0, 0, 0, 0 })
    local right = layer(-3)
    right:SetPoint("TOPRIGHT", -1, -1)
    right:SetPoint("BOTTOMRIGHT", -1, 1)
    right:SetWidth(46)
    gradient(right, "HORIZONTAL", { 0, 0, 0, 0 }, { 0, 0, 0, 0.5 })
    -- the floor: a line of light, brightest under the character
    local floorY = 34
    local fl = stage:CreateTexture(nil, "ARTWORK")
    fl:SetHeight(1)
    fl:SetPoint("BOTTOMLEFT", stage, "BOTTOM", -120, floorY)
    fl:SetPoint("BOTTOMRIGHT", stage, "BOTTOM", 0, floorY)
    gradient(fl, "HORIZONTAL", { r, g, b, 0 }, { r, g, b, 0.9 })
    local fr = stage:CreateTexture(nil, "ARTWORK")
    fr:SetHeight(1)
    fr:SetPoint("BOTTOMLEFT", stage, "BOTTOM", 0, floorY)
    fr:SetPoint("BOTTOMRIGHT", stage, "BOTTOM", 120, floorY)
    gradient(fr, "HORIZONTAL", { r, g, b, 0.9 }, { r, g, b, 0 })
    -- a soft band of light just above the floor
    local band = stage:CreateTexture(nil, "BACKGROUND", nil, -2)
    band:SetPoint("BOTTOMLEFT", stage, "BOTTOM", -110, floorY)
    band:SetPoint("BOTTOMRIGHT", stage, "BOTTOM", 110, floorY)
    band:SetHeight(28)
    gradient(band, "VERTICAL", { r, g, b, 0.22 }, { r, g, b, 0 })
    ui.stage = stage
    return stage
end

function G.Build(page)
    ui.page = page
    ui.preview = "Wearing best in slot"
    ui.info = W.Label(page, "", "GameFontHighlightSmall")
    ui.info:SetPoint("TOPLEFT", 10, -8)
    ui.info:SetPoint("RIGHT", page, "RIGHT", -190, 0)
    ui.info:SetJustifyH("LEFT")
    ui.previewCycle = W.Cycle(page, 170, { "Wearing best in slot", "Your gear" }, function() return ui.preview end,
        function(v) ui.preview = v; G.Paint() end)
    ui.previewCycle:SetPoint("TOPRIGHT", -10, -4)
    ui.previewCycle.tip = "Show your best pieces, or what you have on now (with the best for each slot beside it)."

    ui.slots = {}
    for i, slot in ipairs(LEFT) do
        local b = slotWidget(page, slot, "left")
        b:SetPoint("TOPLEFT", 10, -36 - (i - 1) * 44)
        ui.slots[slot] = b
    end
    for i, slot in ipairs(RIGHT) do
        local b = slotWidget(page, slot, "right")
        b:SetPoint("TOPRIGHT", -10, -36 - (i - 1) * 44)
        ui.slots[slot] = b
    end
    -- weapons along the bottom
    local bottom = { 16, 17, 18 }
    for i, slot in ipairs(bottom) do
        local b = slotWidget(page, slot, "bottom")
        b:SetPoint("BOTTOM", page, "BOTTOM", (i - 2) * 200 - 70, 10)
        ui.slots[slot] = b
    end

    local stage = buildStage(page)
    local ok, m = pcall(CreateFrame, "DressUpModel", nil, page)
    if ok and m then
        m:SetPoint("TOPLEFT", stage, "TOPLEFT", 2, -2)
        m:SetPoint("BOTTOMRIGHT", stage, "BOTTOMRIGHT", -2, 2)
        m:SetFrameLevel(stage:GetFrameLevel() + 2)
        if m.SetUnit then pcall(m.SetUnit, m, "player") end
        -- shown again (the tab, the app): the game resets the model, so dress it again
        m:SetScript("OnShow", function(self)
            if self.SetUnit then pcall(self.SetUnit, self, "player") end
            if self.SetFacing then pcall(self.SetFacing, self, self.rot or 0) end
            ui.dressed = nil
            dressModel(true)
        end)
        -- drag to turn the character
        m:EnableMouse(true)
        m.rot = 0
        m:SetScript("OnMouseDown", function(self) self.turning = GetCursorPosition() end)
        m:SetScript("OnMouseUp", function(self) self.turning = nil end)
        m:SetScript("OnUpdate", function(self)
            if not self.turning then return end
            local x = GetCursorPosition()
            self.rot = (self.rot or 0) + (x - self.turning) * 0.01
            self.turning = x
            if self.SetFacing then self:SetFacing(self.rot) end
        end)
        ui.model = m
    end
    ui.hint = W.Label(page, C.dim .. "Drag to turn. Click a piece to link it.|r", "GameFontHighlightSmall")
    if ui.stage then ui.hint:SetPoint("BOTTOM", ui.stage, "BOTTOM", 0, 8) end
end

-- what you wear in a slot, in the same shape as a best-in-slot entry
local function wornEntry(slot)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
    local id = link and tonumber(link:match("item:(%d+)"))
    if not id then return nil end
    local name, _, quality = GetItemInfo(link)
    return { id = id, link = link, name = name or (link:match("%[(.-)%]")) or "item", quality = quality or 1, src = { "Equipped" }, worn = true }
end

-- "Your gear": each slot shows what you wear, and whether it's the best
local function paintWorn(b, res)
    local e = wornEntry(b.slot)
    local top = res and res.slots[b.slot]
    paintSlot(b, e, res)
    if not e then
        local label = SLOT_INFO[b.slot] and SLOT_INFO[b.slot][2] or ""
        b.name:SetText(C.dim .. label .. "|r")
        b.sub:SetText(top and (C.dim .. "Empty. Best: |r" .. qualityColor(top.quality) .. top.name .. "|r") or (C.dim .. "Empty|r"))
        return
    end
    if top and top.id == e.id then
        b.sub:SetText(C.good .. "Best in slot|r")
    elseif top then
        b.sub:SetText(C.dim .. "Best: |r" .. qualityColor(top.quality) .. top.name .. "|r")
    else
        b.sub:SetText(C.good .. "Equipped|r")
    end
end

local function paint()
    if not ui.page then return end
    local res = state.result
    local cm = M()
    if state.running and not res then
        ui.info:SetText(C.dim .. ("Looking through the loot Codex knows... %d of %d"):format(state.done or 0, state.total or 0) .. "|r")
    elseif res then
        local text = ("Best pieces you can wear at level %d%s, scored by %s."):format(res.level,
            res.spec and (" as " .. tostring(res.spec)) or "", res.by)
        if res.waiting > 0 and not ui.gaveUp then
            text = text .. C.dim .. (" Loading %d more items from the server..."):format(res.waiting) .. "|r"
        end
        ui.info:SetText(text)
    end
    local mine = ui.preview == "Your gear"
    for slot, b in pairs(ui.slots or {}) do
        if mine then paintWorn(b, res) else paintSlot(b, res and res.slots[slot] or nil, res) end
    end
    dressModel()
end
G.Paint = paint

-- Items still on their way from the server: look again in a few seconds, as
-- long as more keep arriving. Some IDs in the loot lists are items this
-- server doesn't have and never sends; after a few tries with nothing new,
-- stop asking and stop saying it's loading.
local retryQueued, lastWaiting, stalls = false, nil, 0
local MAX_STALLS = 3
function G.Refresh(fromRetry)
    if not (ui.page and ui.page:IsVisible()) then return end
    if not fromRetry then stalls, lastWaiting, ui.gaveUp = 0, nil, false end
    paint()
    G.Compute(function()
        local w = state.waiting or 0
        if lastWaiting and w >= lastWaiting then stalls = stalls + 1 else stalls = 0 end
        lastWaiting = w
        if stalls >= MAX_STALLS then ui.gaveUp = true end
        paint()
        if w > 0 and not ui.gaveUp and not retryQueued and C_Timer then
            retryQueued = true
            C_Timer.After(3, function() retryQueued = false; G.Refresh(true) end)
        end
    end)
end
