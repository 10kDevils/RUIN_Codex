-- RUIN Codex: Best in Slot
-- Your character in the middle, and for every slot the best piece you can
-- get and wear at your level: dungeon and raid loot from the Journal's lists
-- (boss drops, trash, dungeon quest rewards Ruinous Forever Planner knows),
-- weapons and armour from quests you can still do (QuestData/QuestRewards.lua),
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
G.QUEST_WINDOW = 8         -- quest rewards from quests up to this many levels below you

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
local LEFT = { 1, 2, 3, 15, 5, 9, 16, 17 }
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
    -- quest rewards you can still earn: a quest you can pick up now (your
    -- side, your class, not done yet) up to QUEST_WINDOW levels below you,
    -- whose reward your class can use. Older quests' gear is long outgrown.
    local QR, QQ = ns.QuestRewards, ns.QuestRewardQuests
    if QR and QQ then
        local cm = M()
        local fac = UnitFactionGroup and UnitFactionGroup("player")
        local side = fac == "Alliance" and 1 or fac == "Horde" and 2 or 0
        local classId = UnitClass and select(3, UnitClass("player"))
        local cbit = classId and bit and bit.lshift(1, classId - 1)
        local isDone = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or rawget(_G, "IsQuestFlaggedCompleted")
        local areaName = C_Map and C_Map.GetAreaInfo
        for id, r in pairs(QR) do
            if not (cm and cm.CanUseKind) or cm.CanUseKind(r[2], r[3]) ~= false then
                for k = 4, #r do
                    local qid = r[k]
                    local q = QQ[qid]
                    local ql = q and (q[2] > 0 and q[2] or q[3]) or 0
                    if q and (q[1] ~= "") and (q[4] == 0 or q[4] == side)
                        and (q[5] == 0 or not cbit or bit.band(q[5], cbit) ~= 0)
                        and q[3] <= level and ql >= level - G.QUEST_WINDOW and (r[1] == 0 or r[1] <= level)
                        and not (isDone and isDone(qid)) then
                        local zone = q[6] and q[6] > 0 and areaName and areaName(q[6])
                        add(id, "Quest reward: " .. q[1] .. (zone and (", " .. zone) or ""))
                        break
                    end
                end
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

local askedAt, GIVE_UP = {}, 20     -- item id -> when it was first asked for; seconds to wait

-- one candidate's facts, or nil when it can't be worn now (or isn't loaded)
local function judge(c, level, key)
    local cm = M()
    local name, link, quality, _, minLevel, _, _, _, loc = GetItemInfo(c.link or c.id)
    if not name then
        -- some IDs in the loot lists are items this server doesn't have: after
        -- a while with no answer, stop waiting for them
        local now = GetTime and GetTime() or 0
        local first = askedAt[c.id]
        if not first then first = now; askedAt[c.id] = now end
        asked(c.id)
        if now - first > GIVE_UP then return nil end
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

---------------------------------------------------------------------------
-- Drawing helpers: gradients, gold trim, diamonds
---------------------------------------------------------------------------
local GOLD = { 0.86, 0.69, 0.38 }
local GOLD_HI = { 1.00, 0.86, 0.55 }

-- Vertical: from the bottom color to the top; horizontal: left to right.
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

local function solid(parent, layer, sub, c, a)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
    t:SetColorTexture(c[1], c[2], c[3], a or 1)
    return t
end

-- a small diamond (a square turned 45 degrees), with an optional jewel inside
local function diamond(parent, size, c, a, layer)
    local d = solid(parent, layer or "OVERLAY", 2, c, a)
    d:SetSize(size, size)
    if d.SetRotation then pcall(d.SetRotation, d, math.rad(45)) end
    return d
end
local function jewel(parent, size, accent, layer)
    local outer = diamond(parent, size, GOLD, 1, layer)
    local inner = diamond(parent, math.max(2, size - 5), accent, 1, layer)
    inner:SetDrawLayer(layer or "OVERLAY", 3)
    inner:SetPoint("CENTER", outer, "CENTER")
    outer.inner = inner
    return outer
end

-- a gold line that fades out both ways from its middle, with a jewel there
local function flourish(parent, width, accent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, 12)
    local l = f:CreateTexture(nil, "ARTWORK")
    l:SetHeight(1)
    l:SetPoint("LEFT", 0, 0)
    l:SetPoint("RIGHT", f, "CENTER", -6, 0)
    gradient(l, "HORIZONTAL", { GOLD[1], GOLD[2], GOLD[3], 0 }, { GOLD[1], GOLD[2], GOLD[3], 0.9 })
    local r = f:CreateTexture(nil, "ARTWORK")
    r:SetHeight(1)
    r:SetPoint("LEFT", f, "CENTER", 6, 0)
    r:SetPoint("RIGHT", 0, 0)
    gradient(r, "HORIZONTAL", { GOLD[1], GOLD[2], GOLD[3], 0.9 }, { GOLD[1], GOLD[2], GOLD[3], 0 })
    local j = jewel(f, 9, accent)
    j:SetPoint("CENTER")
    return f
end

-- a rectangle of 1px lines inside f, inset by n, in color c
local function trim(f, n, c, a, layer, sub)
    local lines = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = solid(f, layer or "BORDER", sub or 1, c, a)
        if side == "TOP" or side == "BOTTOM" then
            t:SetHeight(1)
            t:SetPoint(side .. "LEFT", n, side == "TOP" and -n or n)
            t:SetPoint(side .. "RIGHT", -n, side == "TOP" and -n or n)
        else
            t:SetWidth(1)
            t:SetPoint("TOP" .. side, side == "LEFT" and n or -n, -n)
            t:SetPoint("BOTTOM" .. side, side == "LEFT" and n or -n, n)
        end
        lines[side] = t
    end
    return lines
end

-- gold corner pieces: an L of heavier lines with a jewel at the point
local function corners(f, accent)
    local len, w = 22, 2
    for _, c in ipairs({ { "TOPLEFT", 1, -1 }, { "TOPRIGHT", -1, -1 }, { "BOTTOMLEFT", 1, 1 }, { "BOTTOMRIGHT", -1, 1 } }) do
        local pt, sx, sy = c[1], c[2], c[3]
        local h = solid(f, "OVERLAY", 1, GOLD_HI, 1)
        h:SetSize(len, w)
        h:SetPoint(pt, f, pt, -sx * 2, -sy * 2)
        local v = solid(f, "OVERLAY", 1, GOLD_HI, 1)
        v:SetSize(w, len)
        v:SetPoint(pt, f, pt, -sx * 2, -sy * 2)
        local j = jewel(f, 9, accent)
        j:SetPoint("CENTER", f, pt, -sx * 1, -sy * 1)
    end
end

---------------------------------------------------------------------------
-- The stage: your race's dressing room scenery, lit from below in Codex's
-- color, framed in gold
---------------------------------------------------------------------------
local function accentOf(page)
    local ok, scheme = pcall(W.SchemeOf, page)
    return (ok and scheme and scheme.accent) or W.PALETTE.glow or { 0.62, 0.46, 0.92 }
end

-- The stage: no box and no scenery behind the character, just light. A soft
-- beam falls from the jewel under the banner, a glow sits behind the
-- character, and an arcane circle in Codex's color turns slowly on the floor
-- under the feet, with a soft shadow where they stand. The textures are
-- Codex's own (Media/), drawn white and tinted here.
local MEDIA = "Interface\\AddOns\\RUIN_Codex\\Media\\"
local FEET = 0.19        -- a model's feet stand this far up its frame

-- turn a square texture by angle a (radians) in its own space, so a circle
-- squashed into an ellipse still turns like a disc seen at an angle
local function turn(t, a)
    local s, c = math.sin(a), math.cos(a)
    local function p(x, y) return 0.5 + x * c - y * s, 0.5 + x * s + y * c end
    local ulx, uly = p(-0.5, -0.5)
    local llx, lly = p(-0.5, 0.5)
    local urx, ury = p(0.5, -0.5)
    local lrx, lry = p(0.5, 0.5)
    t:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

local function buildStage(page, ac)
    local scene = CreateFrame("Frame", nil, page)
    local r, g, b = ac[1], ac[2], ac[3]
    local light = CreateFrame("Frame", nil, scene)
    light:SetAllPoints()
    scene.shade = light
    local feet = CreateFrame("Frame", nil, light)
    feet:SetSize(1, 1)
    scene.feet = feet
    local function tex(file, sub, blend)
        local t = light:CreateTexture(nil, "ARTWORK", nil, sub)
        t:SetTexture(MEDIA .. file)
        t:SetBlendMode(blend or "ADD")
        return t
    end
    -- the beam, from the top of the stage down to the floor
    local beam = tex("Beam", -6)
    beam:SetPoint("TOP", scene, "TOP", 0, 2)
    beam:SetPoint("BOTTOM", feet, "CENTER", 0, -24)
    beam:SetWidth(300)
    beam:SetVertexColor(r, g, b, 0.32)
    scene.beam = beam
    -- a glow behind the character
    local halo = tex("Glow", -5)
    halo:SetSize(350, 350)
    scene.halo = halo
    halo:SetVertexColor(r, g, b, 0.23)
    -- the circle on the floor, and light pooled in it
    local runes = tex("Runes", -4)
    runes:SetSize(300, 84)
    runes:SetPoint("CENTER", feet, "CENTER", 0, 0)
    runes:SetVertexColor(math.min(1, r * 1.1), math.min(1, g * 1.1), math.min(1, b * 1.1), 0.9)
    local pool = tex("Glow", -3)
    pool:SetSize(250, 58)
    pool:SetPoint("CENTER", feet, "CENTER", 0, 0)
    pool:SetVertexColor(r, g, b, 0.36)
    local shadow = tex("Glow", -2, "BLEND")
    shadow:SetSize(100, 22)
    shadow:SetPoint("CENTER", feet, "CENTER", 0, 1)
    shadow:SetVertexColor(0, 0, 0, 0.85)
    -- the circle turns, slowly, while the tab is open
    local angle = 0.2
    turn(runes, angle)
    light:SetScript("OnUpdate", function(_, elapsed)
        angle = (angle + (elapsed or 0) * 0.06) % (math.pi * 2)
        turn(runes, angle)
    end)
    return scene
end

---------------------------------------------------------------------------
-- Slots
---------------------------------------------------------------------------
local function setFrameColor(holder, r, g, b, a)
    for _, e in pairs(holder.skinEdges or {}) do e:SetColorTexture(r, g, b, a or 1) end
end

local function slotWidget(parent, slot, side, ac)
    local holder = CreateFrame("Button", nil, parent)
    holder:SetSize(42, 42)
    W.Skin(holder, "bg", 1, "line")
    holder.slot = slot
    holder.side = side
    holder.icon = holder:CreateTexture(nil, "ARTWORK")
    holder.icon:SetPoint("TOPLEFT", 3, -3)
    holder.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    holder.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    holder.inner = trim(holder, 2, { 0, 0, 0 }, 0.9, "OVERLAY", 1)
    holder.glow = holder:CreateTexture(nil, "OVERLAY", nil, 2)
    holder.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    holder.glow:SetBlendMode("ADD")
    holder.glow:SetSize(76, 76)
    holder.glow:SetPoint("CENTER")
    holder.glow:Hide()
    holder:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    -- the upgrade badge on the icon's corner
    holder.badge = holder:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    holder.badge:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -2, 3)
    -- a check on the corner when the piece you wear is already your best
    holder.bis = holder:CreateTexture(nil, "OVERLAY", nil, 4)
    holder.bis:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    holder.bis:SetSize(18, 18)
    holder.bis:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 4, 4)
    holder.bis:Hide()
    holder.bisRing = holder:CreateTexture(nil, "OVERLAY", nil, 3)
    holder.bisRing:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    holder.bisRing:SetVertexColor(0, 0, 0, 0.75)
    holder.bisRing:SetSize(20, 20)
    holder.bisRing:SetPoint("CENTER", holder.bis, "CENTER")
    holder.bisRing:Hide()
    -- a band of light behind the words, fading away from the icon
    local strip = holder:CreateTexture(nil, "BACKGROUND", nil, -6)
    strip:SetHeight(42)
    local r, g, b = ac[1], ac[2], ac[3]
    local W_STRIP = side == "bottom" and 170 or 210
    if side == "right" then
        strip:SetPoint("RIGHT", holder, "LEFT", 0, 0)
        strip:SetWidth(W_STRIP)
        gradient(strip, "HORIZONTAL", { r, g, b, 0 }, { r, g, b, 0.16 })
    else
        strip:SetPoint("LEFT", holder, "RIGHT", 0, 0)
        strip:SetWidth(W_STRIP)
        gradient(strip, "HORIZONTAL", { r, g, b, 0.16 }, { r, g, b, 0 })
    end
    holder.strip = strip
    -- slot name in small capitals, the item, and where it comes from
    holder.cap = holder:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    holder.name = W.Label(holder, "", "GameFontNormal")
    holder.sub = W.Label(holder, "", "GameFontHighlightSmall")
    local width = side == "bottom" and 150 or 190
    for _, fs in ipairs({ holder.cap, holder.name, holder.sub }) do
        fs:SetWordWrap(false)
        fs:SetWidth(width)
    end
    holder.cap:SetText(((SLOT_INFO[slot] and SLOT_INFO[slot][2]) or ""):upper())
    holder.cap:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 0.75)
    -- the three lines sit centred in the band: the item's name on the
    -- middle, its slot just above and where it comes from just below
    if side == "right" then
        holder.name:SetPoint("RIGHT", holder, "LEFT", -11, 1)
        holder.cap:SetPoint("BOTTOMRIGHT", holder.name, "TOPRIGHT", 0, 2)
        holder.sub:SetPoint("TOPRIGHT", holder.name, "BOTTOMRIGHT", 0, -2)
        for _, fs in ipairs({ holder.cap, holder.name, holder.sub }) do fs:SetJustifyH("RIGHT") end
    else
        holder.name:SetPoint("LEFT", holder, "RIGHT", 11, 1)
        holder.cap:SetPoint("BOTTOMLEFT", holder.name, "TOPLEFT", 0, 2)
        holder.sub:SetPoint("TOPLEFT", holder.name, "BOTTOMLEFT", 0, -2)
        for _, fs in ipairs({ holder.cap, holder.name, holder.sub }) do fs:SetJustifyH("LEFT") end
    end
    holder:SetScript("OnEnter", function(self)
        local e = self.entry
        if not (e and GameTooltip) then return end
        GameTooltip:SetOwner(self, side == "right" and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
        pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
        -- one line in Codex's voice; where a drop comes from is already in the
        -- item's tooltip, so only sources it doesn't show (quests, trash) follow
        for i, line in ipairs(self.tipLines or {}) do
            if i == 1 then GameTooltip:AddLine(line, GOLD[1], GOLD[2], GOLD[3], true)
            else GameTooltip:AddLine(line, 0.8, 0.8, 0.8, true) end
        end
        GameTooltip:Show()
    end)
    holder:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    holder:SetScript("OnClick", function(self, button)
        local cm = M()
        if self.entry and cm and cm.ShowItem then cm.ShowItem(self.entry.link, button) end
    end)
    return holder
end

-- what you wear in a slot, in the same shape as a best-in-slot entry
local function wornEntry(slot)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
    local id = link and tonumber(link:match("item:(%d+)"))
    if not id then return nil end
    local name, _, quality = GetItemInfo(link)
    return { id = id, link = link, name = name or (link:match("%[(.-)%]")) or "item", quality = quality or 1, src = { "Equipped" }, worn = true }
end

local function wornScore(slot)
    local e = wornEntry(slot)
    if not e then return 0 end
    return scoreOf(e.id, e.link, scoreKey()) or 0
end

local function isWorn(id)
    if not (id and GetInventoryItemLink) then return false end
    for slot in pairs(SLOT_INFO) do
        local l = GetInventoryItemLink("player", slot)
        if l and tonumber(l:match("item:(%d+)")) == id then return true end
    end
    return false
end

-- an item in a slot: icon, quality frame and glow
local function showItem(b, e)
    if e then
        b.icon:SetTexture(itemIcon(e.id) or emptyTexture(b.slot))
        b.icon:SetDesaturated(false)
        b.icon:SetAlpha(1)
        local r, g, bl = qualityRGB(e.quality)
        setFrameColor(b, r, g, bl, (e.quality or 1) >= 2 and 1 or 0.6)
        b.glow:SetVertexColor(r, g, bl, 0.55)
        b.glow:SetShown((e.quality or 1) >= 3)
        b.name:SetText(qualityColor(e.quality) .. e.name .. "|r")
    else
        b.icon:SetTexture(emptyTexture(b.slot))
        b.icon:SetDesaturated(true)
        b.icon:SetAlpha(0.6)
        setFrameColor(b, GOLD[1], GOLD[2], GOLD[3], 0.35)
        b.glow:Hide()
    end
end

-- "+12%", "NEW" or nothing, for the best piece against what you wear
local function upgradeBadge(slot, e)
    if not e or isWorn(e.id) then return "" end
    local have = wornScore(slot)
    if have <= 0 then return C.good .. "NEW|r" end
    local pct = math.floor((e.score - have) / have * 100 + 0.5)
    if pct < 1 then return "" end
    return C.good .. "+" .. pct .. "%|r"
end

local function setBisMark(b, on)
    b.bis:SetShown(on and true or false)
    b.bisRing:SetShown(on and true or false)
end

-- "Best in slot" view
local function paintBest(b, res)
    local e = res and res.slots[b.slot]
    b.entry = e
    showItem(b, e)
    setBisMark(b, e and isWorn(e.id))
    b.tipLines = nil
    if e then
        local lines = { isWorn(e.id) and "Codex: your best in slot, and you're wearing it" or "Codex: your best in slot" }
        for _, src in ipairs(e.src or {}) do
            if src:find("^Quest reward") or src:find("^Trash in") then lines[#lines + 1] = src end
        end
        b.tipLines = lines
    end
    if e then
        b.badge:SetText(upgradeBadge(b.slot, e))
        if isWorn(e.id) then
            b.sub:SetText(C.good .. "Equipped|r")
        else
            b.sub:SetText(C.dim .. table.concat(e.src, "; ") .. "|r")
        end
        return
    end
    b.badge:SetText("")
    if b.slot == 17 and res and res.slots.twoHand then
        b.name:SetText(C.dim .. "Two-hander equipped|r")
        b.sub:SetText(C.dim .. "Your main hand takes both hands|r")
    elseif b.slot == 18 and not G.HasRangedSlot() then
        b.name:SetText(C.dim .. "No ranged slot|r")
        b.sub:SetText(C.dim .. "Ranged weapons go in the main hand|r")
    else
        b.name:SetText(C.dim .. (res and "Nothing found yet" or "") .. "|r")
        b.sub:SetText("")
    end
end

-- "Your gear" view: what you wear, and the best piece beside it
local function paintWorn(b, res)
    local e = wornEntry(b.slot)
    local top = res and res.slots[b.slot]
    b.entry = e
    showItem(b, e)
    b.badge:SetText("")
    setBisMark(b, e and top and (top.id == e.id or isWorn(top.id)))
    if top and e and (top.id == e.id or isWorn(top.id)) then
        b.tipLines = { "Codex: your best in slot" }
    elseif top then
        b.tipLines = { "Codex: your best in slot is " .. top.name, table.concat(top.src or {}, "; ") }
    else
        b.tipLines = nil
    end
    if not e then
        b.name:SetText(C.dim .. "Empty|r")
        b.sub:SetText(top and (C.dim .. "Best: |r" .. qualityColor(top.quality) .. top.name .. "|r") or "")
        return
    end
    if top and (top.id == e.id or isWorn(top.id)) then
        b.sub:SetText(C.good .. "Best in slot|r")
    elseif top then
        b.sub:SetText(C.dim .. "Best: |r" .. qualityColor(top.quality) .. top.name .. "|r")
        b.badge:SetText(upgradeBadge(b.slot, top))
    else
        b.sub:SetText(C.good .. "Equipped|r")
    end
end

---------------------------------------------------------------------------
-- The model
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- Building the page
---------------------------------------------------------------------------
local TOP = 82           -- where the slots start, under the banner
local ROW_MIN, ROW_MAX = 40, 50

local function classInfo()
    local cname, class = "", nil
    if UnitClass then cname, class = UnitClass("player") end
    local race = UnitRace and UnitRace("player") or ""
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return cname or "", race or "", c
end

-- the two columns share the page's height: rows as tall as fit, 40 to 50
local function layoutSlots()
    local page = ui.page
    local h = page and page:GetHeight() or 0
    local row = h > 0 and math.floor((h - TOP - 6) / 8) or 46
    row = math.max(ROW_MIN, math.min(ROW_MAX, row))
    local size = math.min(42, row - 6)
    local band = math.min(size + 8, row - 3)
    for i, slot in ipairs(LEFT) do
        local b = ui.slots[slot]
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -TOP - (i - 1) * row)
        b:SetSize(size, size)
        b.strip:SetHeight(band)
    end
    for i, slot in ipairs(RIGHT) do
        local b = ui.slots[slot]
        b:ClearAllPoints()
        b:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -TOP - (i - 1) * row)
        b:SetSize(size, size)
        b.strip:SetHeight(band)
    end
    local rb = ui.slots[18]
    if rb then
        rb:SetSize(size, size)
        rb.strip:SetHeight(band)
    end
end

function G.Build(page)
    ui.page = page
    ui.preview = "Wearing best in slot"
    local ac = accentOf(page)
    ui.accent = ac

    -- the scene goes first, under everything
    local scene = buildStage(page, ac)
    scene:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -TOP + 10)
    scene:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    scene:SetFrameLevel(page:GetFrameLevel())
    ui.stage = scene

    -- banner: your name, level, race and spec, and how close your gear is
    ui.nameText = page:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    ui.nameText:SetPoint("TOPLEFT", 14, -8)
    ui.nameText:SetTextColor(GOLD_HI[1], GOLD_HI[2], GOLD_HI[3])
    ui.title = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.title:SetPoint("TOPLEFT", ui.nameText, "BOTTOMLEFT", 1, -3)
    ui.info = W.Label(page, "", "GameFontHighlightSmall")
    ui.info:SetPoint("TOPLEFT", ui.title, "BOTTOMLEFT", 0, -3)
    ui.info:SetPoint("RIGHT", page, "CENTER", 60, 0)
    ui.info:SetJustifyH("LEFT")
    ui.info:SetWordWrap(false)

    ui.previewCycle = W.Cycle(page, 190, { "Wearing best in slot", "Your gear" }, function() return ui.preview end,
        function(v) ui.preview = v; G.Paint() end)
    ui.previewCycle:SetPoint("TOPRIGHT", -12, -8)
    ui.previewCycle.tip = "Show your best pieces, or what you have on now (with the best for each slot beside it)."
    ui.ratingLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.ratingLabel:SetPoint("TOPRIGHT", ui.previewCycle, "BOTTOMRIGHT", 0, -8)
    ui.ratingLabel:SetJustifyH("RIGHT")
    ui.rating = W.Progress(page, 190, 8)
    ui.rating:SetPoint("TOPRIGHT", ui.ratingLabel, "BOTTOMRIGHT", 0, -4)
    for _, e in pairs(ui.rating.skinEdges or {}) do e:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.7) end
    ui.rating.fill:SetColorTexture(ac[1], ac[2], ac[3], 1)
    ui.rating.SetColor = function() end
    ui.ratingHi = ui.rating:CreateTexture(nil, "OVERLAY")
    ui.ratingHi:SetPoint("TOPLEFT", ui.rating.fill, "TOPLEFT")
    ui.ratingHi:SetPoint("TOPRIGHT", ui.rating.fill, "TOPRIGHT")
    ui.ratingHi:SetHeight(3)
    gradient(ui.ratingHi, "VERTICAL", { 1, 1, 1, 0 }, { 1, 1, 1, 0.35 })

    local rule = flourish(page, 520, ac)
    rule:SetPoint("TOP", page, "TOP", 0, -TOP + 12)
    rule:SetPoint("LEFT", page, "LEFT", 10, 0)
    rule:SetPoint("RIGHT", page, "RIGHT", -10, 0)
    rule:SetFrameLevel(scene:GetFrameLevel() + 6)

    -- the character, in the middle between the columns
    local ok, m = pcall(CreateFrame, "DressUpModel", nil, page)
    if ok and m then
        m:SetPoint("TOPLEFT", scene, "TOPLEFT", 262, -6)
        m:SetPoint("BOTTOMRIGHT", scene, "BOTTOMRIGHT", -262, 30)
        m:SetFrameLevel(scene.shade:GetFrameLevel() + 1)
        -- the floor under the feet, wherever the frame's size puts them
        local function placeFeet()
            local h = m:GetHeight() or 0
            scene.feet:ClearAllPoints()
            scene.feet:SetPoint("CENTER", m, "BOTTOM", 0, h * FEET)
            scene.halo:ClearAllPoints()
            scene.halo:SetPoint("CENTER", m, "BOTTOM", 0, h * 0.62)
        end
        placeFeet()
        m:HookScript("OnSizeChanged", placeFeet)
        if m.SetUnit then pcall(m.SetUnit, m, "player") end
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
        m:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:AddLine("Drag to turn your character.", 1, 1, 1)
            GameTooltip:AddLine("Click a piece around it to link it.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        m:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        ui.model = m
    end

    -- the slots, over the scene
    ui.slots = {}
    for _, slot in ipairs(LEFT) do
        local b = slotWidget(page, slot, "left", ac)
        b:SetFrameLevel(scene:GetFrameLevel() + 4)
        ui.slots[slot] = b
    end
    for _, slot in ipairs(RIGHT) do
        local b = slotWidget(page, slot, "right", ac)
        b:SetFrameLevel(scene:GetFrameLevel() + 4)
        ui.slots[slot] = b
    end
    -- the ranged slot under the character, where the client has one
    if G.HasRangedSlot() then
        local b = slotWidget(page, 18, "bottom", ac)
        b:SetPoint("BOTTOM", page, "BOTTOM", -84, 4)
        b:SetFrameLevel(scene:GetFrameLevel() + 4)
        ui.slots[18] = b
    end
    layoutSlots()
    page:HookScript("OnSizeChanged", layoutSlots)
end

---------------------------------------------------------------------------
-- Painting
---------------------------------------------------------------------------
local function paintBanner(res)
    local cname, race, cc = classInfo()
    local me = UnitName and UnitName("player") or ""
    ui.nameText:SetText(me)
    local spec = res and res.spec or (M() and M().MySpec and M().MySpec())
    local level = (UnitLevel and UnitLevel("player")) or 0
    local hex = cc and cc.colorStr or "ffffffff"
    ui.title:SetText(("Level %d %s  |c%s%s%s|r"):format(level, race, hex, spec and (tostring(spec) .. " ") or "", cname))

    local text
    if state.running and not res then
        text = C.dim .. ("Looking through the loot Codex knows... %d of %d|r"):format(state.done or 0, state.total or 0)
    elseif res then
        text = C.dim .. "Dungeon and raid loot you can wear now, scored by " .. res.by .. ".|r"
        if (state.waiting or 0) > 0 then text = text .. C.dim .. (" Loading %d items...|r"):format(state.waiting) end
    else
        text = ""
    end
    ui.info:SetText(text)

    -- how close your gear is: your pieces' score against the best pieces'
    local have, best, owned, slots = 0, 0, 0, 0
    if res then
        for slot in pairs(SLOT_INFO) do
            local e = res.slots[slot]
            if e then
                slots = slots + 1
                best = best + e.score
                have = have + math.min(wornScore(slot), e.score)
                if isWorn(e.id) then owned = owned + 1 end
            end
        end
    end
    local pct = best > 0 and have / best or 0
    ui.rating:SetValue(pct)
    ui.ratingLabel:SetText(res and ("%sGear %d%% of your best|r  %s%d of %d pieces|r"):format(C.gold or "", math.floor(pct * 100 + 0.5),
        C.dim, owned, slots) or "")
end

local function paint()
    if not ui.page then return end
    local res = state.result
    paintBanner(res)
    local mine = ui.preview == "Your gear"
    for _, b in pairs(ui.slots or {}) do
        if mine then paintWorn(b, res) else paintBest(b, res) end
    end
    dressModel()
end
G.Paint = paint

-- Items still on their way from the server: look again in a few seconds
-- until they've come (items the server never sends stop counting after a
-- while, see judge).
local retryQueued = false
function G.Refresh()
    if not (ui.page and ui.page:IsVisible()) then return end
    paint()
    G.Compute(function()
        paint()
        if (state.waiting or 0) > 0 and not retryQueued and C_Timer then
            retryQueued = true
            C_Timer.After(3, function() retryQueued = false; G.Refresh() end)
        end
    end)
end
