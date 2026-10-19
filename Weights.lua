-- RUIN Codex stat weights, per class and spec
-- Points per point of each stat, relative within a spec (main stat = 1.0).
-- Written for WoW Forever's stat set: Haste and Expertise exist, and Hit and
-- Crit are single stats for both melee and spells. These are a reasoned
-- starting point, not simulation output: RUIN theorycrafters can tune them,
-- and officers' best-in-slot lists override them where it matters.
--
-- Keys: STR AGI STA INT SPI AP SP HEAL CRIT HIT HASTE EXP MP5 DEF DODGE PARRY
--       BLOCK BV ARMOR DPS (weapon damage per second)
local ADDON, ns = ...

ns.SpecWeights = {
    WARRIOR = {
        Arms        = { STR = 1.0, AGI = 0.55, STA = 0.2, AP = 0.45, CRIT = 0.85, HIT = 0.95, HASTE = 0.7, EXP = 0.9, ARMOR = 0.005, DPS = 3.0 },
        Fury        = { STR = 1.0, AGI = 0.5, STA = 0.2, AP = 0.45, CRIT = 0.9, HIT = 1.0, HASTE = 0.75, EXP = 0.9, ARMOR = 0.005, DPS = 2.4 },
        Protection  = { STA = 1.0, STR = 0.5, AGI = 0.6, DEF = 1.0, DODGE = 0.8, PARRY = 0.75, BLOCK = 0.55, BV = 0.3, ARMOR = 0.06, HIT = 0.45, EXP = 0.55, AP = 0.2, DPS = 1.0 },
    },
    PALADIN = {
        Holy        = { INT = 1.0, SPI = 0.4, STA = 0.2, HEAL = 0.9, SP = 0.8, CRIT = 0.75, HASTE = 0.7, MP5 = 1.2 },
        Protection  = { STA = 1.0, STR = 0.45, AGI = 0.4, INT = 0.2, DEF = 1.0, DODGE = 0.75, PARRY = 0.7, BLOCK = 0.6, BV = 0.35, SP = 0.4, ARMOR = 0.06, HIT = 0.4, EXP = 0.5 },
        Retribution = { STR = 1.0, AGI = 0.45, INT = 0.15, STA = 0.2, AP = 0.45, SP = 0.2, CRIT = 0.85, HIT = 0.95, HASTE = 0.6, EXP = 0.85, DPS = 3.0 },
    },
    HUNTER = {
        ["Beast Mastery"] = { AGI = 1.0, INT = 0.25, STA = 0.2, AP = 0.45, CRIT = 0.75, HIT = 1.0, HASTE = 0.8, DPS = 1.8 },
        Marksmanship      = { AGI = 1.0, INT = 0.25, STA = 0.2, AP = 0.45, CRIT = 0.85, HIT = 1.0, HASTE = 0.75, DPS = 2.2 },
        Survival          = { AGI = 1.05, INT = 0.25, STA = 0.2, AP = 0.4, CRIT = 0.85, HIT = 1.0, HASTE = 0.7, DPS = 1.8 },
    },
    ROGUE = {
        Assassination = { AGI = 1.0, STR = 0.4, STA = 0.2, AP = 0.45, CRIT = 0.8, HIT = 1.0, HASTE = 0.8, EXP = 0.9, DPS = 2.0 },
        Combat        = { AGI = 1.0, STR = 0.45, STA = 0.2, AP = 0.45, CRIT = 0.85, HIT = 1.05, HASTE = 0.85, EXP = 1.0, DPS = 2.6 },
        Subtlety      = { AGI = 1.0, STR = 0.4, STA = 0.25, AP = 0.45, CRIT = 0.85, HIT = 0.95, HASTE = 0.7, EXP = 0.85, DPS = 2.2 },
    },
    PRIEST = {
        Discipline = { INT = 1.0, SPI = 0.6, STA = 0.25, HEAL = 0.85, SP = 0.8, CRIT = 0.7, HASTE = 0.65, MP5 = 1.1 },
        Holy       = { INT = 0.9, SPI = 0.85, STA = 0.2, HEAL = 0.95, SP = 0.8, CRIT = 0.65, HASTE = 0.7, MP5 = 1.0 },
        Shadow     = { INT = 0.6, SPI = 0.35, STA = 0.3, SP = 1.0, CRIT = 0.6, HIT = 1.05, HASTE = 0.85 },
    },
    SHAMAN = {
        Elemental   = { INT = 0.6, SPI = 0.2, STA = 0.2, SP = 1.0, CRIT = 0.85, HIT = 1.0, HASTE = 0.8, MP5 = 0.6 },
        Enhancement = { STR = 0.9, AGI = 0.8, INT = 0.25, STA = 0.2, AP = 0.45, SP = 0.2, CRIT = 0.85, HIT = 1.0, HASTE = 0.85, EXP = 0.85, DPS = 3.0 },
        Restoration = { INT = 1.0, SPI = 0.4, STA = 0.2, HEAL = 0.9, SP = 0.8, CRIT = 0.6, HASTE = 0.75, MP5 = 1.3 },
    },
    MAGE = {
        Arcane = { INT = 0.75, SPI = 0.35, STA = 0.2, SP = 1.0, CRIT = 0.75, HIT = 1.0, HASTE = 0.85, MP5 = 0.4 },
        Fire   = { INT = 0.6, SPI = 0.2, STA = 0.2, SP = 1.0, CRIT = 0.95, HIT = 1.05, HASTE = 0.8 },
        Frost  = { INT = 0.55, SPI = 0.2, STA = 0.25, SP = 1.0, CRIT = 0.8, HIT = 1.05, HASTE = 0.8 },
    },
    WARLOCK = {
        Affliction  = { INT = 0.5, SPI = 0.25, STA = 0.4, SP = 1.0, CRIT = 0.55, HIT = 1.05, HASTE = 0.85 },
        Demonology  = { INT = 0.5, SPI = 0.2, STA = 0.5, SP = 1.0, CRIT = 0.65, HIT = 1.0, HASTE = 0.8 },
        Destruction = { INT = 0.5, SPI = 0.15, STA = 0.35, SP = 1.0, CRIT = 0.85, HIT = 1.05, HASTE = 0.85 },
    },
    DRUID = {
        Balance          = { INT = 0.65, SPI = 0.3, STA = 0.2, SP = 1.0, CRIT = 0.8, HIT = 1.0, HASTE = 0.8, MP5 = 0.5 },
        ["Feral (cat)"]  = { AGI = 1.0, STR = 0.75, STA = 0.2, AP = 0.45, CRIT = 0.85, HIT = 1.0, HASTE = 0.6, EXP = 0.85 },
        ["Feral (bear)"] = { STA = 1.0, AGI = 0.8, STR = 0.35, DEF = 0.85, DODGE = 0.9, ARMOR = 0.09, HIT = 0.35, EXP = 0.5, AP = 0.15 },
        Restoration      = { INT = 0.9, SPI = 0.8, STA = 0.2, HEAL = 0.95, SP = 0.8, CRIT = 0.5, HASTE = 0.75, MP5 = 1.1 },
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
