-- RUIN Codex stat weights, per class and spec
-- Points per point of each stat, relative within a spec (main stat = 1.0).
-- Written for WoW Forever's stat set: Haste and Expertise exist, and Hit and
-- Crit are single stats for both melee and spells. These are a reasoned
-- starting point, not simulation output: RUIN theorycrafters can tune them.
--
-- Keys: STR AGI STA INT SPI AP SP HEAL CRIT HIT HASTE EXP MP5 DEF DODGE PARRY
--       BLOCK BV ARMOR DPS (a melee weapon's damage per second)
--       RDPS (a ranged weapon's damage per second: bows, guns, crossbows,
--       thrown and wands. Hunters weigh it above their melee DPS; casters
--       weigh their wand; warriors and rogues only pull with it)
-- SP is spell damage and HEAL is healing: "damage and healing done by magical
-- spells" counts as both, so healers weigh SP low (it's only their damage)
-- and HEAL high. School damage (SP_SHADOW ...), ranged attack power (RAP) and
-- feral attack power (FAP) are scored in ItemStats.lua for the specs that use them.
local ADDON, ns = ...

ns.SpecWeights = {
    -- Physical specs: 1 Strength is 2 attack power for warriors, paladins and
    -- shamans (1 for rogues, hunters and cats), and a weapon's damage per
    -- second is worth 14 attack power. Ratings: 14 crit, 10 hit, 10 haste,
    -- 10 expertise per 1%.
    WARRIOR = {
        Arms        = { STR = 1.0, AGI = 0.5, STA = 0.15, AP = 0.5, CRIT = 0.75, HIT = 1.0, HASTE = 0.7, EXP = 0.9, ARMOR = 0.003, DPS = 7.0, RDPS = 0.3 },
        Fury        = { STR = 1.0, AGI = 0.5, STA = 0.15, AP = 0.5, CRIT = 0.8, HIT = 1.05, HASTE = 0.75, EXP = 0.95, ARMOR = 0.003, DPS = 6.0, RDPS = 0.3 },
        Protection  = { STA = 1.0, STR = 0.45, AGI = 0.55, DEF = 1.0, DODGE = 0.8, PARRY = 0.75, BLOCK = 0.5, BV = 0.3, ARMOR = 0.06, HIT = 0.45, EXP = 0.55, AP = 0.2, DPS = 1.5, RDPS = 0.2 },
    },
    PALADIN = {
        Holy        = { HEAL = 1.0, INT = 0.6, SPI = 0.1, STA = 0.15, SP = 0.1, CRIT = 0.6, HASTE = 0.5, MP5 = 1.6 },
        Protection  = { STA = 1.0, STR = 0.4, AGI = 0.4, INT = 0.2, DEF = 1.0, DODGE = 0.75, PARRY = 0.7, BLOCK = 0.55, BV = 0.35, SP = 0.4, ARMOR = 0.06, HIT = 0.4, EXP = 0.5, DPS = 1.5 },
        Retribution = { STR = 1.0, AGI = 0.5, INT = 0.15, STA = 0.15, AP = 0.5, SP = 0.15, CRIT = 0.75, HIT = 1.0, HASTE = 0.6, EXP = 0.85, ARMOR = 0.003, DPS = 6.5 },
    },
    HUNTER = {
        ["Beast Mastery"] = { AGI = 1.0, INT = 0.2, STA = 0.15, AP = 0.5, CRIT = 0.7, HIT = 1.0, HASTE = 0.75, DPS = 0.5, RDPS = 6.5 },
        Marksmanship      = { AGI = 1.0, INT = 0.2, STA = 0.15, AP = 0.5, CRIT = 0.8, HIT = 1.0, HASTE = 0.7, DPS = 0.5, RDPS = 7.0 },
        Survival          = { AGI = 1.0, INT = 0.2, STA = 0.15, AP = 0.45, CRIT = 0.8, HIT = 1.0, HASTE = 0.65, DPS = 0.7, RDPS = 6.5 },
    },
    ROGUE = {
        Assassination = { AGI = 1.0, STR = 0.55, STA = 0.15, AP = 0.55, CRIT = 0.75, HIT = 1.0, HASTE = 0.75, EXP = 0.9, DPS = 6.0, RDPS = 0.3 },
        Combat        = { AGI = 1.0, STR = 0.55, STA = 0.15, AP = 0.55, CRIT = 0.75, HIT = 1.05, HASTE = 0.8, EXP = 1.0, DPS = 7.0, RDPS = 0.3 },
        Subtlety      = { AGI = 1.0, STR = 0.55, STA = 0.2, AP = 0.55, CRIT = 0.8, HIT = 0.95, HASTE = 0.7, EXP = 0.85, DPS = 6.0, RDPS = 0.3 },
    },
    -- Casters: spell power is 1. Intellect is mana and a little crit, worth
    -- well under a point of spell power; wands count while leveling.
    PRIEST = {
        Discipline = { HEAL = 1.0, INT = 0.5, SPI = 0.3, STA = 0.15, SP = 0.15, CRIT = 0.4, HASTE = 0.5, MP5 = 1.5, RDPS = 1.0 },
        Holy       = { HEAL = 1.0, INT = 0.45, SPI = 0.45, STA = 0.15, SP = 0.1, CRIT = 0.45, HASTE = 0.5, MP5 = 1.5, RDPS = 1.0 },
        Shadow     = { SP = 1.0, INT = 0.35, SPI = 0.25, STA = 0.15, CRIT = 0.35, HIT = 1.0, HASTE = 0.7, MP5 = 0.6, RDPS = 1.5 },
    },
    SHAMAN = {
        Elemental   = { SP = 1.0, INT = 0.4, SPI = 0.1, STA = 0.15, CRIT = 0.65, HIT = 1.0, HASTE = 0.7, MP5 = 0.8 },
        Enhancement = { STR = 1.0, AGI = 0.6, INT = 0.15, STA = 0.15, AP = 0.5, SP = 0.1, CRIT = 0.75, HIT = 1.0, HASTE = 0.8, EXP = 0.85, ARMOR = 0.003, DPS = 6.0 },
        Restoration = { HEAL = 1.0, INT = 0.5, SPI = 0.15, STA = 0.15, SP = 0.1, CRIT = 0.45, HASTE = 0.55, MP5 = 1.7 },
    },
    MAGE = {
        Arcane = { SP = 1.0, INT = 0.5, SPI = 0.25, STA = 0.15, CRIT = 0.55, HIT = 1.0, HASTE = 0.75, MP5 = 0.5, RDPS = 1.5 },
        Fire   = { SP = 1.0, INT = 0.4, SPI = 0.15, STA = 0.15, CRIT = 0.7, HIT = 1.05, HASTE = 0.7, MP5 = 0.4, RDPS = 1.5 },
        Frost  = { SP = 1.0, INT = 0.35, SPI = 0.15, STA = 0.15, CRIT = 0.6, HIT = 1.05, HASTE = 0.7, MP5 = 0.4, RDPS = 1.5 },
    },
    WARLOCK = {
        Affliction  = { SP = 1.0, INT = 0.3, SPI = 0.15, STA = 0.3, CRIT = 0.25, HIT = 1.05, HASTE = 0.75, MP5 = 0.3, RDPS = 1.5 },
        Demonology  = { SP = 1.0, INT = 0.3, SPI = 0.1, STA = 0.35, CRIT = 0.4, HIT = 1.0, HASTE = 0.7, MP5 = 0.3, RDPS = 1.5 },
        Destruction = { SP = 1.0, INT = 0.3, SPI = 0.1, STA = 0.25, CRIT = 0.65, HIT = 1.05, HASTE = 0.75, MP5 = 0.3, RDPS = 1.5 },
    },
    DRUID = {
        Balance          = { SP = 1.0, INT = 0.4, SPI = 0.15, STA = 0.15, CRIT = 0.55, HIT = 1.0, HASTE = 0.7, MP5 = 0.8 },
        ["Feral (cat)"]  = { AGI = 1.0, STR = 0.9, STA = 0.15, AP = 0.45, CRIT = 0.75, HIT = 1.0, HASTE = 0.55, EXP = 0.85 },
        ["Feral (bear)"] = { STA = 1.0, AGI = 0.8, STR = 0.35, DEF = 0.85, DODGE = 0.9, ARMOR = 0.09, HIT = 0.35, EXP = 0.5, AP = 0.15 },
        Restoration      = { HEAL = 1.0, INT = 0.45, SPI = 0.4, STA = 0.15, SP = 0.1, CRIT = 0.35, HASTE = 0.55, MP5 = 1.5 },
    },
}

-- Spec order per class (the order talent trees and the spec picker use).
ns.SpecOrder = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER  = { "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE   = { "Assassination", "Combat", "Subtlety" },
    PRIEST  = { "Discipline", "Holy", "Shadow" },
    SHAMAN  = { "Elemental", "Enhancement", "Restoration" },
    MAGE    = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    DRUID   = { "Balance", "Feral (cat)", "Feral (bear)", "Restoration" },
}

-- Talent tree names that map onto a spec above.
ns.SpecAlias = { ["Feral Combat"] = "Feral (cat)", Feral = "Feral (cat)", Guardian = "Feral (bear)",
                 ["Beast Mastery"] = "Beast Mastery", Outlaw = "Combat" }

-- Item stat keys (from GetItemStats) to the short names above.
ns.StatMap = {
    ITEM_MOD_STRENGTH_SHORT = "STR", ITEM_MOD_AGILITY_SHORT = "AGI", ITEM_MOD_STAMINA_SHORT = "STA",
    ITEM_MOD_INTELLECT_SHORT = "INT", ITEM_MOD_SPIRIT_SHORT = "SPI",
    ITEM_MOD_ATTACK_POWER_SHORT = "AP", ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "AP",
    ITEM_MOD_SPELL_POWER_SHORT = "SP", ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "SP",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "HEAL",
    -- Forever folds melee and spell Hit and Crit into one stat each.
    ITEM_MOD_CRIT_RATING_SHORT = "CRIT", ITEM_MOD_CRIT_SPELL_RATING_SHORT = "CRIT", ITEM_MOD_CRIT_MELEE_RATING_SHORT = "CRIT",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT = "CRIT",
    ITEM_MOD_HIT_RATING_SHORT = "HIT", ITEM_MOD_HIT_SPELL_RATING_SHORT = "HIT", ITEM_MOD_HIT_MELEE_RATING_SHORT = "HIT",
    ITEM_MOD_HIT_RANGED_RATING_SHORT = "HIT",
    ITEM_MOD_HASTE_RATING_SHORT = "HASTE", ITEM_MOD_HASTE_SPELL_RATING_SHORT = "HASTE",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "EXP",
    ITEM_MOD_MANA_REGENERATION_SHORT = "MP5", ITEM_MOD_POWER_REGEN0_SHORT = "MP5",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "DEF", ITEM_MOD_DODGE_RATING_SHORT = "DODGE",
    ITEM_MOD_PARRY_RATING_SHORT = "PARRY", ITEM_MOD_BLOCK_RATING_SHORT = "BLOCK", ITEM_MOD_BLOCK_VALUE_SHORT = "BV",
    RESISTANCE0_NAME = "ARMOR", ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "DPS",
}
