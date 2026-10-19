-- RUIN Codex: the starter macro library.
-- Every macro here was written for RUIN (standard, generic patterns; nothing is copied from another
-- addon or website). The Macros page checks each one: name 16 characters or fewer, text 255 or fewer,
-- no code-running commands. {drink}, {food}, {healthstone}, {bandage}, {potion:heal} and {potion:mana}
-- are filled in with the best matching item in your bags when you add the macro.
local ADDON, ns = ...

local HELP = "[@mouseover,help,nodead][help,nodead][@player]"   -- heal: mouseover, else target, else yourself
local HARM = "[@mouseover,harm,nodead][]"                       -- enemy: mouseover, else target
local TRINKETS = "\n/use 13\n/use 14"

local list = {}
-- class, spec (nil = any), tag, name, body, note, required spells
local function m(class, spec, tag, name, body, note, req)
    list[#list + 1] = { c = class, s = spec, tag = tag, n = name, body = body, note = note, req = req }
end

-- Shared ----------------------------------------------------------------
m("ALL", nil, "Quality of life", "Eat & Drink", "#showtooltip {drink}\n/use {drink}\n/use {food}",
    "Eat and drink with one press. Uses the best food and drink in your bags.")
m("ALL", nil, "Combat", "Both Trinkets", "#showtooltip\n/use 13\n/use 14",
    "Uses both trinkets together.")
m("ALL", nil, "Combat", "Stone + Potion", "#showtooltip {healthstone}\n/use {healthstone}\n/use {potion:heal}",
    "Healthstone and healing potion share no cooldown, so one press uses both.")
m("ALL", nil, "Quality of life", "Bandage Self", "#showtooltip {bandage}\n/use [@player] {bandage}",
    "Bandages yourself without changing your target.")
m("ALL", nil, "Combat", "Mana Potion", "#showtooltip {potion:mana}\n/use {potion:mana}",
    "Drinks the best mana potion in your bags.")

-- Warrior ---------------------------------------------------------------
m("WARRIOR", nil, "Combat", "Charge/Intercept", "#showtooltip\n/cast [stance:1] Charge; [stance:3] Intercept",
    "Charge in Battle Stance, Intercept in Berserker Stance.", { "Charge" })
m("WARRIOR", nil, "Combat", "Pummel/Bash", "#showtooltip\n/cast [stance:3] Pummel; [stance:1/2] Shield Bash",
    "Interrupt with whichever your stance allows. Shield Bash needs a shield.", { "Pummel" })
m("WARRIOR", "Protection", "Combat", "Sunder", "#showtooltip Sunder Armor\n/startattack\n/cast Sunder Armor",
    "Starts auto attack and applies Sunder Armor.", { "Sunder Armor" })
m("WARRIOR", "Protection", "Combat", "Taunt", "#showtooltip\n/cast [stance:2] Taunt; [stance:1] Mocking Blow",
    "Taunt in Defensive Stance, Mocking Blow in Battle Stance.", { "Taunt" })
m("WARRIOR", nil, "Combat", "Rage Start", "#showtooltip Bloodrage\n/cast Bloodrage\n/cast Battle Shout",
    "Bloodrage for a rage kick, then Battle Shout.", { "Bloodrage" })
m("WARRIOR", nil, "Combat", "Heroic/Cleave", "#showtooltip\n/cast [modifier:shift] Cleave; Heroic Strike",
    "Heroic Strike by default, Cleave while holding Shift.", { "Heroic Strike" })
m("WARRIOR", nil, "Combat", "Execute", "#showtooltip Execute\n/startattack\n/cast Execute",
    "Starts auto attack and uses Execute when the target is low.", { "Execute" })
m("WARRIOR", nil, "Utility", "Hamstring Mo", "#showtooltip Hamstring\n/cast " .. HARM .. " Hamstring",
    "Hamstring your mouseover enemy, or your target.", { "Hamstring" })
m("WARRIOR", nil, "Utility", "Stance Cycle", "#showtooltip\n/cast [stance:1] Defensive Stance; [stance:2] Berserker Stance; Battle Stance",
    "One key steps through Battle, Defensive and Berserker.", { "Defensive Stance" })
m("WARRIOR", "Protection", "Combat", "Block+Revenge", "#showtooltip Shield Block\n/cast Shield Block\n/cast Revenge",
    "Raises your block, then Revenge if it is ready.", { "Shield Block" })
m("WARRIOR", "Arms", "Combat", "Overpower", "#showtooltip Overpower\n/cast [stance:1] Overpower",
    "Overpower only in Battle Stance, where it works.", { "Overpower" })
m("WARRIOR", "Fury", "Combat", "Reckless Burst", "#showtooltip Recklessness\n/cast [stance:3] Recklessness" .. TRINKETS,
    "Recklessness in Berserker Stance plus both trinkets.", { "Recklessness" })

-- Paladin ---------------------------------------------------------------
m("PALADIN", "Holy", "Combat", "Holy Light Mo", "#showtooltip Holy Light\n/cast " .. HELP .. " Holy Light",
    "Big heal on your mouseover, then target, then yourself.", { "Holy Light" })
m("PALADIN", "Holy", "Combat", "Flash Light Mo", "#showtooltip Flash of Light\n/cast " .. HELP .. " Flash of Light",
    "Fast heal on your mouseover, then target, then yourself.", { "Flash of Light" })
m("PALADIN", nil, "Combat", "Seal Swap", "#showtooltip\n/cast [modifier:shift] Seal of the Crusader; Seal of Righteousness",
    "Seal of Righteousness, or Seal of the Crusader while holding Shift.", { "Seal of Righteousness" })
m("PALADIN", "Holy", "Utility", "Cleanse Mo", "#showtooltip Cleanse\n/cast " .. HELP .. " Cleanse",
    "Cleanse your mouseover, then target, then yourself.", { "Cleanse" })
m("PALADIN", nil, "Utility", "Hammer Mo", "#showtooltip Hammer of Justice\n/cast " .. HARM .. " Hammer of Justice",
    "Stun your mouseover enemy, or your target.", { "Hammer of Justice" })
m("PALADIN", nil, "Combat", "Lay on Hands", "#showtooltip Lay on Hands\n/cast " .. HELP .. " Lay on Hands",
    "Lay on Hands on your mouseover, then target, then yourself.", { "Lay on Hands" })
m("PALADIN", nil, "Utility", "Freedom Mo", "#showtooltip Blessing of Freedom\n/cast " .. HELP .. " Blessing of Freedom",
    "Free an ally from roots and slows.", { "Blessing of Freedom" })
m("PALADIN", nil, "Utility", "Protection Mo", "#showtooltip Blessing of Protection\n/cast [@mouseover,help,nodead][help,nodead] Blessing of Protection",
    "Protect your mouseover ally or target from physical damage.", { "Blessing of Protection" })
m("PALADIN", "Protection", "Combat", "Shield+Consecr", "#showtooltip Holy Shield\n/cast Holy Shield\n/cast Consecration",
    "Holy Shield and Consecration together for threat.", { "Holy Shield" })
m("PALADIN", "Retribution", "Combat", "Judge", "#showtooltip Judgement\n/startattack\n/cast Judgement",
    "Starts auto attack and judges your seal.", { "Judgement" })
m("PALADIN", "Retribution", "Combat", "Ret Burst", "#showtooltip Seal of Command\n/cast Seal of Command" .. TRINKETS,
    "Seal of Command and both trinkets.", { "Seal of Command" })
m("PALADIN", nil, "Utility", "Redeem Mo", "#showtooltip Redemption\n/cast [@mouseover,help,dead][help,dead] Redemption",
    "Resurrect your mouseover or target out of combat.", { "Redemption" })

-- Hunter ----------------------------------------------------------------
m("HUNTER", nil, "Combat", "Mark & Attack", "#showtooltip Hunter's Mark\n/petattack\n/cast Hunter's Mark",
    "Sends your pet in and marks the target.", { "Hunter's Mark" })
m("HUNTER", nil, "Combat", "Feign Death", "#showtooltip Feign Death\n/stopcasting\n/cast Feign Death",
    "Cancels what you are casting and feigns death.", { "Feign Death" })
m("HUNTER", nil, "Quality of life", "Pet Care", "#showtooltip\n/cast [@pet,dead] Revive Pet; [nopet] Call Pet; Mend Pet",
    "Revive a dead pet, call a missing one, otherwise heal it.", { "Call Pet" })
m("HUNTER", nil, "Utility", "Aspect Swap", "#showtooltip\n/cast [combat] Aspect of the Hawk; Aspect of the Cheetah",
    "Hawk in a fight, Cheetah out of one.", { "Aspect of the Hawk" })
m("HUNTER", nil, "Combat", "Sting Mo", "#showtooltip Serpent Sting\n/cast " .. HARM .. " Serpent Sting",
    "Sting your mouseover enemy, or your target.", { "Serpent Sting" })
m("HUNTER", nil, "Utility", "Concussive Mo", "#showtooltip Concussive Shot\n/cast " .. HARM .. " Concussive Shot",
    "Slow your mouseover enemy, or your target.", { "Concussive Shot" })
m("HUNTER", nil, "Utility", "Trap Swap", "#showtooltip\n/cast [modifier:shift] Frost Trap; Freezing Trap",
    "Freezing Trap, or Frost Trap while holding Shift.", { "Freezing Trap" })
m("HUNTER", nil, "Utility", "Scatter Mo", "#showtooltip Scatter Shot\n/cast " .. HARM .. " Scatter Shot",
    "Scatter Shot your mouseover enemy, or your target.", { "Scatter Shot" })
m("HUNTER", "Beast Mastery", "Combat", "Rapid Burst", "#showtooltip Rapid Fire\n/cast Rapid Fire" .. TRINKETS,
    "Rapid Fire and both trinkets.", { "Rapid Fire" })
m("HUNTER", "Survival", "Combat", "Melee Weave", "#showtooltip Raptor Strike\n/startattack\n/cast Raptor Strike",
    "Starts auto attack and uses Raptor Strike when you are in melee.", { "Raptor Strike" })
m("HUNTER", nil, "Utility", "Tranq Mo", "#showtooltip Tranquilizing Shot\n/cast " .. HARM .. " Tranquilizing Shot",
    "Remove an enrage from your mouseover enemy, or your target.", { "Tranquilizing Shot" })
m("HUNTER", "Marksmanship", "Combat", "Arcane Mo", "#showtooltip Arcane Shot\n/cast " .. HARM .. " Arcane Shot",
    "Arcane Shot at your mouseover enemy, or your target.", { "Arcane Shot" })

-- Rogue -----------------------------------------------------------------
m("ROGUE", nil, "Combat", "Kick Mo", "#showtooltip Kick\n/cast " .. HARM .. " Kick",
    "Interrupt your mouseover enemy, or your target.", { "Kick" })
m("ROGUE", nil, "Combat", "Stealth Open", "#showtooltip\n/cast [nostealth] Stealth; [stealth] Cheap Shot",
    "First press stealths, the next opens with Cheap Shot.", { "Cheap Shot" })
m("ROGUE", "Subtlety", "Combat", "Ambush/Backstab", "#showtooltip\n/startattack\n/cast [stealth] Ambush; Backstab",
    "Ambush from stealth, Backstab otherwise.", { "Backstab" })
m("ROGUE", nil, "Combat", "Finisher", "#showtooltip\n/cast [modifier:shift] Slice and Dice; Eviscerate",
    "Eviscerate, or Slice and Dice while holding Shift.", { "Eviscerate" })
m("ROGUE", nil, "Utility", "Kidney Mo", "#showtooltip Kidney Shot\n/cast " .. HARM .. " Kidney Shot",
    "Stun your mouseover enemy, or your target.", { "Kidney Shot" })
m("ROGUE", nil, "Utility", "Sap Mo", "#showtooltip Sap\n/cast " .. HARM .. " Sap",
    "Sap your mouseover enemy, or your target.", { "Sap" })
m("ROGUE", nil, "Combat", "Evade/Vanish", "#showtooltip\n/cast [modifier:shift] Vanish; Evasion",
    "Evasion, or Vanish while holding Shift.", { "Evasion" })
m("ROGUE", "Combat", "Combat", "Burst Cooldowns", "#showtooltip Adrenaline Rush\n/cast Adrenaline Rush" .. TRINKETS,
    "Adrenaline Rush and both trinkets.", { "Adrenaline Rush" })
m("ROGUE", "Combat", "Combat", "Flurry+Rush", "#showtooltip Blade Flurry\n/cast Blade Flurry\n/cast Adrenaline Rush",
    "Blade Flurry and Adrenaline Rush together.", { "Blade Flurry" })
m("ROGUE", nil, "Utility", "Blind Mo", "#showtooltip Blind\n/cast " .. HARM .. " Blind",
    "Blind your mouseover enemy, or your target.", { "Blind" })
m("ROGUE", nil, "Quality of life", "Pick Pocket", "#showtooltip Pick Pocket\n/cast [stealth] Pick Pocket",
    "Pick Pocket, only while stealthed.", { "Pick Pocket" })
m("ROGUE", "Assassination", "Combat", "Cold Blood", "#showtooltip Cold Blood\n/cast Cold Blood\n/cast Eviscerate",
    "Cold Blood into Eviscerate.", { "Cold Blood" })

-- Priest ----------------------------------------------------------------
m("PRIEST", nil, "Combat", "Greater Heal Mo", "#showtooltip Greater Heal\n/cast " .. HELP .. " Greater Heal",
    "Big heal on your mouseover, then target, then yourself.", { "Greater Heal" })
m("PRIEST", nil, "Combat", "Flash Heal Mo", "#showtooltip Flash Heal\n/cast " .. HELP .. " Flash Heal",
    "Fast heal on your mouseover, then target, then yourself.", { "Flash Heal" })
m("PRIEST", nil, "Combat", "Renew Mo", "#showtooltip Renew\n/cast " .. HELP .. " Renew",
    "Renew on your mouseover, then target, then yourself.", { "Renew" })
m("PRIEST", nil, "Combat", "Shield Mo", "#showtooltip Power Word: Shield\n/cast " .. HELP .. " Power Word: Shield",
    "Shield your mouseover, then target, then yourself.", { "Power Word: Shield" })
m("PRIEST", nil, "Utility", "Dispel Mo", "#showtooltip Dispel Magic\n/cast [@mouseover,exists,nodead][] Dispel Magic",
    "Dispel your mouseover, or your target. Works on friends and enemies.", { "Dispel Magic" })
m("PRIEST", "Shadow", "Combat", "Pain Mo", "#showtooltip Shadow Word: Pain\n/cast " .. HARM .. " Shadow Word: Pain",
    "Shadow Word: Pain on your mouseover enemy, or your target.", { "Shadow Word: Pain" })
m("PRIEST", "Shadow", "Combat", "Safe Flay", "#showtooltip Mind Flay\n/cast [nochanneling:Mind Flay] Mind Flay",
    "Will not restart Mind Flay while it is channeling.", { "Mind Flay" })
m("PRIEST", nil, "Quality of life", "Fortitude Mo", "#showtooltip Power Word: Fortitude\n/cast " .. HELP .. " Power Word: Fortitude",
    "Buff your mouseover, then target, then yourself.", { "Power Word: Fortitude" })
m("PRIEST", nil, "Utility", "Resurrect Mo", "#showtooltip Resurrection\n/cast [@mouseover,help,dead][help,dead] Resurrection",
    "Resurrect your mouseover or target out of combat.", { "Resurrection" })
m("PRIEST", nil, "Utility", "Shackle Mo", "#showtooltip Shackle Undead\n/cast " .. HARM .. " Shackle Undead",
    "Shackle your mouseover undead, or your target.", { "Shackle Undead" })
m("PRIEST", nil, "Utility", "Cure Mo", "#showtooltip Abolish Disease\n/cast " .. HELP .. " Abolish Disease",
    "Remove a disease from your mouseover, target or yourself.", { "Abolish Disease" })
m("PRIEST", "Shadow", "Quality of life", "Shadowform", "#showtooltip Shadowform\n/cast [nocombat] Shadowform",
    "Takes Shadowform when you are not in combat.", { "Shadowform" })

-- Shaman ----------------------------------------------------------------
m("SHAMAN", "Restoration", "Combat", "Healing Wave Mo", "#showtooltip Healing Wave\n/cast " .. HELP .. " Healing Wave",
    "Big heal on your mouseover, then target, then yourself.", { "Healing Wave" })
m("SHAMAN", "Restoration", "Combat", "Lesser Wave Mo", "#showtooltip Lesser Healing Wave\n/cast " .. HELP .. " Lesser Healing Wave",
    "Fast heal on your mouseover, then target, then yourself.", { "Lesser Healing Wave" })
m("SHAMAN", "Restoration", "Combat", "Chain Heal Mo", "#showtooltip Chain Heal\n/cast " .. HELP .. " Chain Heal",
    "Chain Heal starting on your mouseover, then target, then yourself.", { "Chain Heal" })
m("SHAMAN", nil, "Combat", "Shock Stop", "#showtooltip Earth Shock\n/stopcasting\n/cast " .. HARM .. " Earth Shock",
    "Cancels your cast and interrupts with Earth Shock.", { "Earth Shock" })
m("SHAMAN", nil, "Combat", "Flame Shock Mo", "#showtooltip Flame Shock\n/cast " .. HARM .. " Flame Shock",
    "Flame Shock on your mouseover enemy, or your target.", { "Flame Shock" })
m("SHAMAN", nil, "Utility", "Purge Mo", "#showtooltip Purge\n/cast " .. HARM .. " Purge",
    "Purge your mouseover enemy, or your target.", { "Purge" })
m("SHAMAN", nil, "Utility", "Cure Mo", "#showtooltip Cure Poison\n/cast [@mouseover,help,nodead,modifier:shift] Cure Disease; [@mouseover,help,nodead] Cure Poison",
    "Cure Poison on your mouseover ally, or Cure Disease while holding Shift.", { "Cure Poison" })
m("SHAMAN", nil, "Quality of life", "Ghost Wolf", "#showtooltip Ghost Wolf\n/cancelform [form]\n/cast [noform] Ghost Wolf",
    "Press to turn into a wolf, press again to turn back.", { "Ghost Wolf" })
m("SHAMAN", nil, "Utility", "Earth Totem", "#showtooltip\n/cast [modifier:shift] Strength of Earth Totem; Stoneskin Totem",
    "Stoneskin Totem, or Strength of Earth Totem while holding Shift.", { "Stoneskin Totem" })
m("SHAMAN", nil, "Utility", "Grounding", "#showtooltip Grounding Totem\n/cast Grounding Totem",
    "Drops Grounding Totem to take a harmful spell.", { "Grounding Totem" })
m("SHAMAN", "Enhancement", "Combat", "Stormstrike", "#showtooltip Stormstrike\n/startattack\n/cast Stormstrike",
    "Starts auto attack and uses Stormstrike.", { "Stormstrike" })
m("SHAMAN", "Restoration", "Combat", "Swift Heal", "#showtooltip Nature's Swiftness\n/cast Nature's Swiftness\n/cast " .. HELP .. " Healing Wave",
    "Nature's Swiftness into an instant Healing Wave.", { "Nature's Swiftness" })

-- Mage ------------------------------------------------------------------
m("MAGE", "Frost", "Combat", "Stop+Frostbolt", "#showtooltip Frostbolt\n/stopcasting\n/cast Frostbolt",
    "Cancels the current cast and starts a fresh Frostbolt.", { "Frostbolt" })
m("MAGE", "Fire", "Combat", "Stop+Fireball", "#showtooltip Fireball\n/stopcasting\n/cast Fireball",
    "Cancels the current cast and starts a fresh Fireball.", { "Fireball" })
m("MAGE", nil, "Combat", "Counterspell Mo", "#showtooltip Counterspell\n/cast " .. HARM .. " Counterspell",
    "Interrupt your mouseover enemy, or your target.", { "Counterspell" })
m("MAGE", nil, "Utility", "Polymorph Mo", "#showtooltip Polymorph\n/cast " .. HARM .. " Polymorph",
    "Polymorph your mouseover enemy, or your target.", { "Polymorph" })
m("MAGE", nil, "Utility", "Decurse Mo", "#showtooltip Remove Curse\n/cast " .. HELP .. " Remove Curse",
    "Remove a curse from your mouseover, target or yourself.", { "Remove Curse" })
m("MAGE", nil, "Combat", "Nova+Blink", "#showtooltip Frost Nova\n/cast Frost Nova\n/cast Blink",
    "Freezes enemies in place, then blinks away.", { "Frost Nova" })
m("MAGE", nil, "Combat", "Mana Burst", "#showtooltip Evocation\n/use {potion:mana}\n/cast Evocation",
    "Drinks a mana potion, then starts Evocation.", { "Evocation" })
m("MAGE", nil, "Combat", "Ice Block", "#showtooltip Ice Block\n/stopcasting\n/cast Ice Block",
    "Cancels the current cast and Ice Blocks.", { "Ice Block" })
m("MAGE", "Fire", "Combat", "Instant Pyro", "#showtooltip Pyroblast\n/cast Presence of Mind\n/cast Pyroblast",
    "Presence of Mind into Pyroblast.", { "Pyroblast" })
m("MAGE", "Arcane", "Combat", "Arcane Burst", "#showtooltip Arcane Power\n/cast Arcane Power\n/cast Presence of Mind" .. TRINKETS,
    "Arcane Power, Presence of Mind and both trinkets.", { "Arcane Power" })
m("MAGE", "Fire", "Combat", "Combustion", "#showtooltip Combustion\n/cast Combustion" .. TRINKETS,
    "Combustion and both trinkets.", { "Combustion" })
m("MAGE", nil, "Quality of life", "Armor Swap", "#showtooltip\n/cast [modifier:shift] Frost Armor; Ice Armor",
    "Ice Armor, or Frost Armor while holding Shift.", { "Ice Armor" })

-- Warlock ---------------------------------------------------------------
m("WARLOCK", nil, "Utility", "Fear Mo", "#showtooltip Fear\n/cast " .. HARM .. " Fear",
    "Fear your mouseover enemy, or your target.", { "Fear" })
m("WARLOCK", nil, "Utility", "Banish Mo", "#showtooltip Banish\n/cast " .. HARM .. " Banish",
    "Banish your mouseover demon or elemental, or your target.", { "Banish" })
m("WARLOCK", nil, "Combat", "Curse Swap", "#showtooltip\n/cast [modifier:shift] Curse of the Elements; [modifier:ctrl] Curse of Weakness; Curse of Agony",
    "Curse of Agony, Elements with Shift, Weakness with Ctrl.", { "Curse of Agony" })
m("WARLOCK", "Affliction", "Combat", "Corruption Mo", "#showtooltip Corruption\n/cast " .. HARM .. " Corruption",
    "Corruption on your mouseover enemy, or your target.", { "Corruption" })
m("WARLOCK", "Destruction", "Combat", "Immolate Mo", "#showtooltip Immolate\n/cast " .. HARM .. " Immolate",
    "Immolate your mouseover enemy, or your target.", { "Immolate" })
m("WARLOCK", nil, "Quality of life", "Pet Control", "#showtooltip\n/petattack [harm,nodead]\n/petfollow [noharm]",
    "Pet attacks an enemy target, or follows you otherwise.")
m("WARLOCK", nil, "Combat", "Coil Panic", "#showtooltip Death Coil\n/stopcasting\n/cast Death Coil",
    "Cancels the current cast and uses Death Coil.", { "Death Coil" })
m("WARLOCK", "Destruction", "Combat", "Stop+Shadowbolt", "#showtooltip Shadow Bolt\n/stopcasting\n/cast Shadow Bolt",
    "Cancels the current cast and starts a fresh Shadow Bolt.", { "Shadow Bolt" })
m("WARLOCK", nil, "Quality of life", "Summon Pet", "#showtooltip\n/cast [nopet,modifier:shift] Summon Voidwalker; [nopet] Summon Imp; Health Funnel",
    "Summons your pet, or channels Health Funnel into it.", { "Summon Imp" })
m("WARLOCK", "Destruction", "Combat", "Shadowburn Mo", "#showtooltip Shadowburn\n/cast " .. HARM .. " Shadowburn",
    "Shadowburn your mouseover enemy, or your target.", { "Shadowburn" })
m("WARLOCK", "Demonology", "Utility", "Enslave Mo", "#showtooltip Enslave Demon\n/cast " .. HARM .. " Enslave Demon",
    "Enslave your mouseover demon, or your target.", { "Enslave Demon" })
m("WARLOCK", "Affliction", "Combat", "Siphon Mo", "#showtooltip Siphon Life\n/cast " .. HARM .. " Siphon Life",
    "Siphon Life on your mouseover enemy, or your target.", { "Siphon Life" })

-- Druid -----------------------------------------------------------------
m("DRUID", "Restoration", "Combat", "Rejuv Mo", "#showtooltip Rejuvenation\n/cast " .. HELP .. " Rejuvenation",
    "Rejuvenation on your mouseover, then target, then yourself.", { "Rejuvenation" })
m("DRUID", "Restoration", "Combat", "Regrowth Mo", "#showtooltip Regrowth\n/cast " .. HELP .. " Regrowth",
    "Regrowth on your mouseover, then target, then yourself.", { "Regrowth" })
m("DRUID", "Restoration", "Combat", "Touch Mo", "#showtooltip Healing Touch\n/cast " .. HELP .. " Healing Touch",
    "Healing Touch on your mouseover, then target, then yourself.", { "Healing Touch" })
m("DRUID", "Restoration", "Combat", "Swift Touch", "#showtooltip Nature's Swiftness\n/cast Nature's Swiftness\n/cast " .. HELP .. " Healing Touch",
    "Nature's Swiftness into an instant Healing Touch.", { "Nature's Swiftness" })
m("DRUID", nil, "Utility", "Decurse Mo", "#showtooltip Remove Curse\n/cast " .. HELP .. " Remove Curse",
    "Remove a curse from your mouseover, target or yourself.", { "Remove Curse" })
m("DRUID", nil, "Utility", "Innervate Mo", "#showtooltip Innervate\n/cast " .. HELP .. " Innervate",
    "Innervate your mouseover, then target, then yourself.", { "Innervate" })
m("DRUID", "Feral (cat)", "Quality of life", "Cat Toggle", "#showtooltip Cat Form\n/cast [noform:3] Cat Form\n/cancelform [form:3]",
    "Press for Cat Form, press again to leave it.", { "Cat Form" })
m("DRUID", "Feral (bear)", "Combat", "Bear Maul", "#showtooltip Maul\n/startattack\n/cast Maul",
    "Starts auto attack and uses Maul.", { "Maul" })
m("DRUID", "Feral (cat)", "Combat", "Prowl/Pounce", "#showtooltip\n/cast [nostealth] Prowl; [stealth] Pounce",
    "Prowl first, then Pounce from stealth.", { "Prowl" })
m("DRUID", "Feral (cat)", "Combat", "Cat Finisher", "#showtooltip\n/cast [modifier:shift] Rip; Ferocious Bite",
    "Ferocious Bite, or Rip while holding Shift.", { "Ferocious Bite" })
m("DRUID", nil, "Utility", "Roots Mo", "#showtooltip Entangling Roots\n/cast " .. HARM .. " Entangling Roots",
    "Root your mouseover enemy, or your target.", { "Entangling Roots" })
m("DRUID", "Balance", "Combat", "Moonfire/Wrath", "#showtooltip\n/cast [modifier:shift] Moonfire; Wrath",
    "Wrath, or Moonfire while holding Shift.", { "Wrath" })

-- Ids: class and name, lowercase, so a macro keeps its identity ("mage-stop-frostbolt").
for _, rec in ipairs(list) do
    rec.id = (rec.c .. "-" .. rec.n):lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    rec.rev = 1
    rec.by = "RUIN"
    rec.seed = true
end

ns.MacroSeed = list
