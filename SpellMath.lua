-- RUIN Codex: spell math on spell tooltips.
--
-- At the bottom of every damage or healing spell's tooltip:
--   left:  the mana (or rage, energy...) each expected point of damage or
--          healing costs
--   right: the expected damage or healing per second
-- "Expected" counts your critical strike chance for the spell's school and
-- the extra a critical does (half again for spells; on WoW Forever damage
-- and healing over time can crit too). The amounts come from the spell's own description, so
-- it works for cast, instant, channeled and periodic spells alike.
local R = RUIN_API
if not R then return end
local M = R:GetModule("Codex")
if not M then return end
local W = R.Widgets
local C = W.COLORS

local GCD = 1.5          -- an instant spell still costs the global cooldown
local CRIT_MULT = 1.5    -- a spell critical does half again
local SCHOOL = { physical = 1, holy = 2, fire = 3, nature = 4, frost = 5, shadow = 6, arcane = 7 }
local POWER_NAME = { [0] = "mana", [1] = "rage", [2] = "focus", [3] = "energy", [6] = "runic power" }

local function num(s) return tonumber((tostring(s or ""):gsub(",", ""))) end

-- The amounts in a description: direct (average of "X to Y", or "X"),
-- periodic (total, over how long), and whether it heals.
function M.ParseSpellText(text)
    text = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("\n", " ")
    local low = text:lower()
    local out = { heal = false }
    -- heals: says heal, and isn't a "N Fire damage" spell (heal-over-time
    -- text reads "Heals the target of N damage over T sec")
    out.heal = (low:find("heal") and (not low:find("%d+ %a+ damage") or low:find("heals? the target of"))) and true or false
    -- what school, from "N Fire damage" (healing is Holy/Nature: crit chance from the best of them)
    local school = low:match("%d+ (%a+) damage")
    out.school = SCHOOL[school or ""]

    -- periodic: "N (School) damage over T sec", "N damage every S sec for T sec",
    -- "N ... each second for T sec", "N health every S sec ... Lasts T sec"
    local pTotal, pTime
    local a, t = low:match("(%d[%d,]*) %a* ?damage over (%d+%.?%d*) sec")
    if not a then a, t = low:match("of (%d[%d,]*) damage over (%d+%.?%d*) sec") end      -- "Heals the target of 45 damage over 15 sec"
    if not a then a, t = low:match("(%d[%d,]*) health over (%d+%.?%d*) sec") end
    if not a then a, t = low:match("for (%d[%d,]*) over (%d+%.?%d*) sec") end
    if a then pTotal, pTime = num(a), num(t) end
    if not pTotal then
        local each, every, dur = low:match("(%d[%d,]*) %a* ?%a* every (%d+%.?%d*) sec.-(%d+%.?%d*) sec")
        if each then pTotal, pTime = num(each) * math.floor(num(dur) / num(every) + 0.5), num(dur) end
    end
    if not pTotal then
        local each, dur = low:match("(%d[%d,]*) %a* ?damage each second for (%d+%.?%d*) sec")
        if each then pTotal, pTime = num(each) * num(dur), num(dur) end
    end
    out.periodic, out.periodicTime = pTotal, pTime

    -- direct: "X to Y" first; else "causes N School damage" (not the periodic one)
    local lo, hi = low:match("(%d[%d,]*) to (%d[%d,]*)")
    if lo then
        out.direct = (num(lo) + num(hi)) / 2
    else
        local d = low:match("causes? (%d[%d,]*) %a* ?damage")
        if d and not (pTotal and num(d) == pTotal) then out.direct = num(d) end
        if not d then
            local h = low:match("heals? .-for (%d[%d,]*)")
            if h and not (pTotal and num(h) == pTotal) then out.direct = num(h) end
        end
    end
    if out.direct or out.periodic then return out end
end

-- What the tooltip says about casting: "Instant", "1.5 sec cast", "Channeled".
local function castInfo(tooltip, spellID)
    local castMs, channeled = nil, false
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if info and info.castTime then castMs = info.castTime end
    local name = tooltip and tooltip.GetName and tooltip:GetName()
    if name then
        for i = 1, math.min(tooltip:NumLines() or 0, 8) do
            for _, side in ipairs({ "Left", "Right" }) do
                local fs = _G[name .. "Text" .. side .. i]
                local t = fs and fs:GetText()
                if type(t) == "string" then
                    if t:find("Channeled") then channeled = true end
                    local secs = t:match("(%d+%.?%d*) sec cast")
                    if secs and not castMs then castMs = tonumber(secs) * 1000 end
                    if t:find("^Instant") and not castMs then castMs = 0 end
                end
            end
        end
    end
    return (castMs or 0) / 1000, channeled
end

local function description(tooltip, spellID)
    local d = (C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(spellID))
        or (GetSpellDescription and GetSpellDescription(spellID))
    if type(d) == "string" and d ~= "" then return d end
    -- else the tooltip's last long line
    local name = tooltip and tooltip.GetName and tooltip:GetName()
    if not name then return nil end
    for i = tooltip:NumLines() or 0, 1, -1 do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and fs:GetText()
        if type(t) == "string" and #t > 30 then return t end
    end
end

local function manaCost(spellID)
    local costs = (C_Spell and C_Spell.GetSpellPowerCost and C_Spell.GetSpellPowerCost(spellID))
        or (GetSpellPowerCost and GetSpellPowerCost(spellID))
    if type(costs) ~= "table" then return nil end
    for _, c in ipairs(costs) do
        if c.cost and c.cost > 0 then return c.cost, POWER_NAME[c.type] or "power" end
    end
    return 0, "mana"
end

local function critChance(heal, school)
    if not GetSpellCritChance then return 0 end
    local best = 0
    if heal then
        for _, s in ipairs({ 2, 4 }) do best = math.max(best, GetSpellCritChance(s) or 0) end
    else
        best = GetSpellCritChance(school or 2) or 0
    end
    return math.max(0, math.min(100, best)) / 100
end

-- Expected damage (or healing) per cast, and per second.
function M.SpellMath(spellID, tooltip)
    local parsed = M.ParseSpellText(description(tooltip, spellID))
    if not parsed then return nil end
    local cast, channeled = castInfo(tooltip, spellID)
    local crit = critChance(parsed.heal, parsed.school)
    local direct = parsed.direct or 0
    -- on WoW Forever every part can crit: direct hits, channeled ticks and
    -- damage or healing over time alike
    local expected = (direct + (parsed.periodic or 0)) * (1 + crit * (CRIT_MULT - 1))
    if expected <= 0 then return nil end
    local seconds
    if channeled then
        seconds = math.max(parsed.periodicTime or cast, GCD)
    elseif parsed.periodic and not parsed.direct and cast == 0 then
        seconds = math.max(parsed.periodicTime or GCD, GCD)            -- a damage- or heal-over-time: per second of it
    else
        seconds = math.max(cast, GCD)
    end
    local cost, power = manaCost(spellID)
    return {
        expected = expected, perSecond = expected / seconds, heal = parsed.heal,
        cost = cost, power = power, perPoint = cost and cost > 0 and cost / expected or nil, crit = crit,
    }
end

-- The spell a macro casts: from the tooltip itself, or from the action button
-- it belongs to (GetActionInfo gives the macro, GetMacroSpell its spell).
local function macroSpell(tooltip, data)
    if tooltip.GetSpell then
        local ok, _, sid = pcall(tooltip.GetSpell, tooltip)
        if ok and type(sid) == "number" then return sid end
    end
    local macro
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    local action = owner and (owner.action or (owner.GetAttribute and owner:GetAttribute("action")))
    if type(action) == "number" and GetActionInfo then
        local kind, id = GetActionInfo(action)
        if kind == "macro" then macro = id elseif kind == "spell" then return id end
    end
    if not macro and type(data) == "table" and type(data.id) == "number" then macro = data.id end
    if macro and GetMacroSpell then
        local ok, sid = pcall(GetMacroSpell, macro)
        if ok and type(sid) == "number" then return sid end
    end
end

local function onSpellTooltip(tooltip, data, spellID)
    local sdb = M.db
    if sdb and sdb.spellMath == false then return end
    local id = spellID or (type(data) == "table" and data.id)
    if not id and tooltip.GetSpell then id = select(2, tooltip:GetSpell()) end
    if not id or (issecretvalue and issecretvalue(id)) then return end
    -- once per tooltip showing (a macro's tooltip can come through as both)
    local stamp = tostring(GetTime and GetTime() or 0) .. ":" .. tostring(id) .. ":" .. tostring(tooltip.NumLines and tooltip:NumLines() or 0)
    if tooltip.ruinSpellMath == stamp then return end
    local ok, m = pcall(M.SpellMath, id, tooltip)
    if not (ok and m) then return end
    local what = m.heal and "heal" or "damage"
    local left
    if m.perPoint then left = ("%s%.2f %s per %s|r"):format(C.gold, m.perPoint, m.power, what)
    elseif m.cost == 0 then left = C.gold .. "No cost|r"
    else left = " " end
    local right = ("%s%.1f %s|r"):format(C.gold, m.perSecond, m.heal and "HPS" or "DPS")
    tooltip:AddDoubleLine(left, right)
    tooltip.ruinSpellMath = tostring(GetTime and GetTime() or 0) .. ":" .. tostring(id) .. ":" .. tostring(tooltip.NumLines and tooltip:NumLines() or 0)
end
M.OnSpellTooltip = onSpellTooltip

-- a spell on an action bar inside a macro: the tooltip is the macro's
local function onMacroTooltip(tooltip, data)
    local ok, sid = pcall(macroSpell, tooltip, data)
    if ok and sid and not (issecretvalue and issecretvalue(sid)) then onSpellTooltip(tooltip, nil, sid) end
end
M.OnMacroTooltip = onMacroTooltip

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, onSpellTooltip)
    if Enum.TooltipDataType.Macro then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, onMacroTooltip)
    end
elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetSpell", onSpellTooltip)
end
