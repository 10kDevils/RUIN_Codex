-- RUIN Codex: what an item actually gives, for scoring upgrades.
-- The item API (GetItemStats) misses most "Equip:" bonuses on Classic-style
-- items, such as "Equip: Increases damage and healing done by magical spells
-- and effects by up to 12." Codex therefore also reads the item's tooltip and
-- turns those lines into stats. When both sources report the same stat, the
-- larger value is kept, so nothing is counted twice.
--
-- Keys (see Weights.lua): STR AGI STA INT SPI AP RAP FAP SP HEAL SP_<SCHOOL>
-- CRIT HIT HASTE EXP MP5 DEF DODGE PARRY BLOCK BV ARMOR DPS
-- SP is bonus spell damage, HEAL bonus healing. "Damage and healing" gives
-- both; "+49 Shadow Damage" gives SP_SHADOW.
local ADDON, ns = ...

local IS = {}
ns.ItemStats = IS

-- Forever's rating per 1% at level 60 (WoWSims Forever's constants), used to
-- turn Classic-style "+1% crit" lines into the rating Forever's own items use.
IS.RATING = { CRIT = 14, HIT = 10, HASTE = 10, EXP = 10, DODGE = 12, PARRY = 15, BLOCK = 5 }

local SCHOOLS = { arcane = "ARCANE", fire = "FIRE", frost = "FROST", nature = "NATURE", shadow = "SHADOW", holy = "HOLY" }
IS.SCHOOLS = SCHOOLS

local function num(s) return tonumber((tostring(s or ""):gsub(",", ""))) end

local function add(t, key, value)
    value = num(value)
    if value and value > 0 then t[key] = (t[key] or 0) + value end
end

local function pct(t, key, value)
    value = num(value)
    if value and value > 0 then t[key] = (t[key] or 0) + value * IS.RATING[key] end
end

-- One tooltip line (any case, with or without "Equip:") -> stats it gives.
-- Returns true when the line was understood.
function IS.ParseLine(line, t)
    if type(line) ~= "string" then return false end
    local s = line:lower():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.$", "")
    s = s:gsub("^equip:%s*", "")
    local a, b

    -- spell damage and healing
    a = s:match("^increases damage and healing done by magical spells and effects by up to ([%d,]+)$")
        or s:match("^increases spell power by ([%d,]+)$") or s:match("^increases your spell power by ([%d,]+)$")
        or s:match("^%+([%d,]+) spell power$") or s:match("^%+([%d,]+) spell damage and healing$")
        or s:match("^increases damage and healing by up to ([%d,]+)$")
    if a then add(t, "SP", a); add(t, "HEAL", a); return true end
    a, b = s:match("^increases healing done by up to ([%d,]+) and damage done by up to ([%d,]+) for all magical spells and effects$")
    if a then add(t, "HEAL", a); add(t, "SP", b); return true end
    a = s:match("^increases healing done by spells and effects by up to ([%d,]+)$")
        or s:match("^increases healing done by up to ([%d,]+)$") or s:match("^%+([%d,]+) healing spells$")
        or s:match("^%+([%d,]+) healing$")
    if a then add(t, "HEAL", a); return true end
    a = s:match("^increases damage done by magical spells and effects by up to ([%d,]+)$")
        or s:match("^%+([%d,]+) spell damage$")
    if a then add(t, "SP", a); return true end
    -- one school: "Increases damage done by Shadow spells and effects by up to 7",
    -- "+49 Shadow Damage", "+7 Shadow Spell Damage"
    local school
    school, a = s:match("^increases damage done by (%a+) spells and effects by up to ([%d,]+)$")
    if not school then a, school = s:match("^%+([%d,]+) (%a+) spell damage$") end
    if not school then a, school = s:match("^%+([%d,]+) (%a+) damage$") end
    if school and SCHOOLS[school] then add(t, "SP_" .. SCHOOLS[school], a); return true end

    -- crit and hit, spells or melee (Forever uses one stat for both)
    a = s:match("^improves your chance to get a critical strike with spells by ([%d%.]+)%%$")
        or s:match("^improves your chance to get a critical strike by ([%d%.]+)%%$")
        or s:match("^increases your critical strike chance by ([%d%.]+)%%$")
    if a then pct(t, "CRIT", a); return true end
    a = s:match("^improves your chance to hit with spells by ([%d%.]+)%%$")
        or s:match("^improves your chance to hit by ([%d%.]+)%%$")
        or s:match("^increases your chance to hit by ([%d%.]+)%%$")
    if a then pct(t, "HIT", a); return true end
    a = s:match("^increases your attack and casting speed by ([%d%.]+)%%$")
    if a then pct(t, "HASTE", a); return true end

    -- attack power
    a = s:match("^%+([%d,]+) attack power in cat, bear,.-forms only$")
    if a then add(t, "FAP", a); return true end
    a = s:match("^%+([%d,]+) ranged attack power$") or s:match("^increases ranged attack power by ([%d,]+)$")
    if a then add(t, "RAP", a); return true end
    a = s:match("^%+([%d,]+) attack power$") or s:match("^increases attack power by ([%d,]+)$")
    if a then add(t, "AP", a); return true end

    -- mana and health regeneration
    a = s:match("^restores ([%d,]+) mana per 5 sec$") or s:match("^%+([%d,]+) mana every 5 sec$")
        or s:match("^%+([%d,]+) mana per 5 sec$")
    if a then add(t, "MP5", a); return true end

    -- defense
    a = s:match("^increased defense %+([%d,]+)$") or s:match("^%+([%d,]+) defense$")
    if a then add(t, "DEF", a); return true end
    a = s:match("^increases your chance to dodge an attack by ([%d%.]+)%%$")
    if a then pct(t, "DODGE", a); return true end
    a = s:match("^increases your chance to parry an attack by ([%d%.]+)%%$")
    if a then pct(t, "PARRY", a); return true end
    a = s:match("^increases your chance to block attacks with a shield by ([%d%.]+)%%$")
    if a then pct(t, "BLOCK", a); return true end
    a = s:match("^increases the block value of your shield by ([%d,]+)$")
    if a then add(t, "BV", a); return true end
    return false
end

-- Item API keys -> stat keys. Spell power from the API counts for damage and
-- healing; per-school damage keys become SP_<SCHOOL>.
local function fromApi(raw, t)
    for key, value in pairs(raw or {}) do
        if key == "ITEM_MOD_SPELL_POWER_SHORT" or key == "ITEM_MOD_SPELL_POWER" then
            add(t, "SP", value); add(t, "HEAL", value)
        else
            local school = key:match("^ITEM_MOD_(%u+)_DAMAGE_SHORT$") or key:match("^ITEM_MOD_(%u+)_DAMAGE_DONE_SHORT$")
            local mapped = ns.StatMap[key]
            if mapped then
                add(t, mapped, value)
            elseif school and SCHOOLS[school:lower()] then
                add(t, "SP_" .. school, value)
            end
        end
    end
end

-- Tooltip text lines for an item link (left column), skipping secret values.
local scanner
local function tooltipLines(link)
    local out = {}
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok and type(data) == "table" and type(data.lines) == "table" then
            for _, l in ipairs(data.lines) do
                local text = l.leftText
                if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then out[#out + 1] = text end
            end
            return out
        end
    end
    if not CreateFrame then return out end
    if not scanner then
        local ok, f = pcall(CreateFrame, "GameTooltip", "RUIN_CodexScanTooltip", nil, "GameTooltipTemplate")
        if not ok or not f then return out end
        scanner = f
    end
    pcall(scanner.SetOwner, scanner, WorldFrame or UIParent, "ANCHOR_NONE")
    pcall(scanner.ClearLines, scanner)
    pcall(scanner.SetHyperlink, scanner, link)
    local n = scanner.NumLines and scanner:NumLines() or 0
    for i = 1, (tonumber(n) or 0) do
        local fs = _G["RUIN_CodexScanTooltipTextLeft" .. i]
        local text = fs and fs.GetText and fs:GetText()
        if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then out[#out + 1] = text end
    end
    return out
end
IS.TooltipLines = tooltipLines

-- Everything an item gives: { STR = 5, SP = 12, HEAL = 12, ... }, plus
-- whether the tooltip added anything the API didn't report.
local cache = setmetatable({}, { __mode = "k" })
local cacheByLink = {}
local cached = 0

function IS.Read(link)
    if type(link) ~= "string" then return nil end
    local hit = cacheByLink[link]
    if hit then return hit.stats, hit.extra end
    local api
    if C_Item and C_Item.GetItemStats then api = C_Item.GetItemStats(link)
    elseif GetItemStats then api = GetItemStats(link) end
    local stats = {}
    fromApi(api, stats)
    local lines = tooltipLines(link)
    local fromTip = {}
    for i = 2, #lines do IS.ParseLine(lines[i], fromTip) end
    local extra = false
    for key, value in pairs(fromTip) do
        if (stats[key] or 0) < value then stats[key] = value; extra = true end
    end
    if not api and #lines == 0 then return nil end      -- item not loaded yet; ask again later
    if #lines > 1 then
        if cached > 2000 then cacheByLink, cached = {}, 0 end
        cacheByLink[link] = { stats = stats, extra = extra }
        cached = cached + 1
    end
    return stats, extra
end

function IS.Forget() cacheByLink, cached = {}, 0 end

-- How much a spec values damage of one school, relative to its spell power
-- weight (1 = its main school). Specs not listed ignore school damage.
ns.SpecSchools = {
    PRIEST  = { Shadow = { SHADOW = 1 }, Discipline = { HOLY = 0.3 }, Holy = { HOLY = 0.3 } },
    WARLOCK = { Affliction = { SHADOW = 1, FIRE = 0.3 }, Demonology = { SHADOW = 1, FIRE = 0.5 },
                Destruction = { FIRE = 1, SHADOW = 0.7 } },
    MAGE    = { Arcane = { ARCANE = 1, FROST = 0.3, FIRE = 0.3 }, Fire = { FIRE = 1, ARCANE = 0.2 },
                Frost = { FROST = 1, ARCANE = 0.2 } },
    SHAMAN  = { Elemental = { NATURE = 1, FIRE = 0.5, FROST = 0.3 }, Enhancement = { NATURE = 0.5, FIRE = 0.3, FROST = 0.3 } },
    DRUID   = { Balance = { NATURE = 1, ARCANE = 1 } },
    PALADIN = { Retribution = { HOLY = 1 }, Protection = { HOLY = 1 } },
}

-- Score: sum of stat x weight. School damage counts as spell power for the
-- spec's schools; ranged and feral attack power count for the specs that use them.
function IS.Score(stats, weights, class, spec)
    if not stats or not weights then return nil end
    local s = 0
    local schools = ns.SpecSchools[class or ""] and ns.SpecSchools[class][spec or ""] or nil
    for key, value in pairs(stats) do
        local w = weights[key]
        if not w then
            local school = key:match("^SP_(%u+)$")
            if school then
                w = (weights.SP or 0) * ((schools and schools[school]) or 0)
            elseif key == "RAP" and class == "HUNTER" then
                w = weights.AP
            elseif key == "FAP" and class == "DRUID" and spec and spec:find("Feral") then
                w = weights.AP
            end
        end
        if w then s = s + w * value end
    end
    return s
end
