-- RUIN Codex dungeon data
-- The classic dungeons' level ranges and bosses are WoW Classic's (a sample
-- until RUIN records Forever's). WoW Forever's nine new dungeons, from Hall of
-- Thanes to Shaper's Terrace, come from the launch databases of 2026-11-05
-- (forever = "2026-11-05"): levels, entrance, bosses in kill order with tips,
-- dungeon quests, attunement, set bonuses and quest XP where published.
-- status: how complete the public record was (complete, strong, partial,
-- story_only, minimal). Boss loot lives in the loot files (LootForever.lua);
-- Codex also learns drops from what RUIN members actually loot.
local ADDON, ns = ...

ns.Dungeons = {
    {
        id = "rfc", name = "Ragefire Chasm", levels = "13-18", where = "Cleft of Shadow, Orgrimmar",
        bosses = {
            { "Oggleflint", "Cleaves; turn him away from the group." },
            { "Taragaman the Hungerer", "Fire Nova and an uppercut knockback. Healers stay out of melee range." },
            { "Jergosh the Invoker", "Curses and Immolate. Remove the curse if you can." },
            { "Bazzalan", "Poisons the tank. Cure poison or out-heal it." },
        },
    },
    {
        id = "wc", name = "Wailing Caverns", levels = "17-24", where = "Northern Barrens",
        bosses = {
            { "Lady Anacondra", "Casts Sleep and heals herself. Interrupt the heal." },
            { "Lord Cobrahn", "Turns into a serpent and poisons." },
            { "Lord Pythas", "Lightning bolts and Sleep; interrupt." },
            { "Lord Serpentis", "Heals himself; interrupt or burst him down." },
            { "Mutanus the Devourer", "Appears after you escort the Disciple of Naralex, which needs all four Fanglords dead." },
        },
    },
    {
        id = "dm", name = "The Deadmines", levels = "17-26", where = "Moonbrook, Westfall",
        bosses = {
            { "Rhahk'Zor", "Hits hard; first boss inside." },
            { "Sneed's Shredder", "Sneed jumps out when the shredder dies. Kill him too." },
            { "Gilnid", "In the foundry with smelter adds." },
            { "Mr. Smite", "Stuns the group and switches weapons as his health drops." },
            { "Captain Greenskin", "On the ship deck with pirates." },
            { "Edwin VanCleef", "Calls Blackguards to help when wounded. Save cooldowns for the adds." },
        },
    },
    {
        id = "sfk", name = "Shadowfang Keep", levels = "22-30", where = "Silverpine Forest",
        bosses = {
            { "Rethilgore", "Prisoners in the courtyard open the way." },
            { "Razorclaw the Butcher", "Plain melee boss." },
            { "Baron Silverlaine", "Veil of Shadow lowers healing on the tank." },
            { "Commander Springvale", "Heals himself and stuns. Interrupt the heal." },
            { "Odo the Blindwatcher", "Gets stronger as his pack falls; kill quickly." },
            { "Archmage Arugal", "Teleports around the room and turns players into worgen." },
        },
    },
    -- WoW Forever's new dungeons: launch data, 2026-11-05 (Boss & Loot Watch and Launch Snapshot)
    {
        id = "hot", name = "Hall of Thanes", levels = "13-18", where = "Beneath Ironforge / Dun Morogh", forever = "2026-11-05",
        bosses = {
            { "Faldrim Anvilmar", "Anvilmar's Curse: about 20% attack/cast speed reduction on tank (dispel/remove curse); Mind Blast: interruptible." },
            { "Magmatus", "Combust: 360-degree AoE - move out; Bloodhound Runts: disease increasing damage taken; Dark Iron Summoners: interrupt Fireballs; Dark Iron Engineers: dynamite AoE; Sap/Polymorph strong." },
            { "Plunder", "Golem encounter; clear nearby trash." },
            { "Durgen Dirgehammer", "Final boss; head for An Ancient Grudge quest." },
        },
        quests = { "The Restless Dead", "Important Heirlooms", "An Ancient Grudge (needs Dark Iron Map from Ironband's)", "Old Ironforge Incursion", "The Treaty of Understanding" },
        status = "complete",
    },
    {
        id = "rol", name = "Ruins of Lordaeron", levels = "15-20", where = "Ruins above Undercity, Tirisfal Glades", forever = "2026-11-05",
        bosses = {
            { "Witherfang", "Leech Poison on tank - dispel; Kill small spiders first." },
            { "The Baron", "Dangerous Knock Away on tank; Stun prioritization." },
            { "The Abandoned", "Appears after add waves." },
            { "Bjork", "No tips recorded yet." },
            { "Rath'mael", "Flamestrike ground effect - move; Necromancer." },
            { "Viktor the Vile", "Optional / easy to miss after waves." },
            { "Lordaeron Captain", "Rare additional encounter." },
        },
        set = { name = "Rotmender's Raiment", pieces = 5, bonuses = { { "2", "+5 Shadow Resistance" }, { "3", "+10 Intellect" }, { "4", "Mana <15% -> restore 200 mana over 10s (2x in Haunted/Wasteland); 5 min ICD" } } },
        notes = { "Nov 5 hotfix: two Horde dungeon quests now require a prior chain" },
        status = "complete",
    },
    {
        id = "exc", name = "Excavation Site: Wetlands", levels = "24-31", where = "Wetlands, above Whelgar's Excavation", forever = "2026-11-05",
        bosses = {
            { "Saltspine", "Level 28. Tendon Rip (heavy slow on tank); Dust Storm: -25% hit within 10 yd - casters stay out of melee; Clear nearby crocolisk packs first." },
            { "Shadetooth", "Hardest fight: raptor packs in grass + pre-boss wave - clear before pull; Rend / Terrifying Roar / Enrage at about 30% - save stuns; Can be slowed and stunned." },
            { "Highland Horror", "Listed by ForeverChanges; details still thin in public guides." },
            { "Relic Guardian", "Level 31. Activate via Archival Panel; Drops Titan Relic quest starter." },
        },
        questXP = "Alliance about 7 quests = 39,300 XP; Horde about 4 quests = 22,800 XP (ForeverChanges)",
        status = "complete",
    },
    {
        id = "dal", name = "City of Dalaran", levels = "28-33", where = "Alterac Mountains (violet dome)", forever = "2026-11-05",
        bosses = {
            { "Atrexis the Grave Knight", "Unholy Frenzy +75% attack speed 20s (purge/dispel); Skeletons spawn; Disarm tank about 6s." },
            { "Lyn the Ignored", "Shadow Bolt Volley (30 yd)." },
            { "Arcane Anomaly", "Focal Blast: long arcane beam." },
            { "Arcanic Enigma", "No tips recorded yet." },
            { "Unstable Sentinel", "No tips recorded yet." },
            { "Mana Devourer", "Debilitate AoE + mana drain; Drain Vitality." },
            { "Fel Ancient", "Fel Timbers ground effects; Entangle roots." },
            { "Shade of the Archmage", "Mass Polymorph when mana low then Evocation; Do not leave room or boss resets." },
        },
        attunement = { alliance = "An Alarming Request / related from Emissary Jacques in Southshore (sources vary on exact chain)", horde = "Key to the City / Prison Break-In from Magus Wordeen Voidglare in Tarren Mill", note = "One attuned member often enough for the group" },
        set = { name = "Violet Sorcerer's Vestments", pieces = 5, bonuses = { { "2", "+5 Arcane Resistance" }, { "3", "+10 Spirit" }, { "4", "Chance on damaging spell: 15% of mana regen continues while casting for 15s" } } },
        questXP = "4 quests each faction = 37,600 XP (about 1 level at 28)",
        status = "strong",
    },
    {
        id = "drowned", name = "The Drowned City", levels = "35-40", where = "Off Stranglethorn coast (west of Grom'gol area); underwater entrance", forever = "2026-11-05",
        bosses = {
            { "Zul'Alai", "Boss 1. Mechanics and loot not published yet." },
            { "Captain Dreadrise", "Boss 3. Mechanics and loot not published yet." },
            { "Min'loth the Serpent", "Boss 5. Mechanics and loot not published yet." },
        },
        notes = { "Troll city risen from the sea; naga, murlocs, pirates", "Underwater corridors; open-air ruins with weather", "Boss drop tables not fully published; item stats often hidden until looted" },
        status = "partial",
    },
    {
        id = "kroldok", name = "Krol'dok Stronghold", levels = "40-45", where = "Riverglades (new zone, EK east coast)", forever = "2026-11-05",
        bosses = {
        },
        notes = { "Twilight's Hammer ogre fortress", "Outdoor-feeling dungeon; bridge wave encounter with hole in bridge", "Krol'dok Battlegear set referenced but stats hidden", "No full public loot table yet" },
        status = "story_only",
    },
    {
        id = "alcaz", name = "Alcaz Prison", levels = "48-53", where = "Alcaz Island, Dustwallow Marsh", forever = "2026-11-05",
        bosses = {
        },
        notes = { "Defias vs naga conflict theme", "Rumored connection to Varian Wrynn lore", "Loot/quests largely unpublished" },
        status = "minimal",
    },
    {
        id = "blackmaw", name = "Blackmaw Hold", levels = "55-60", where = "Northern Azshara, behind furbolg gates", forever = "2026-11-05",
        bosses = {
        },
        notes = { "Furbolg city fighting corruption; multiple routes", "May connect toward Barrow Deeps raid", "No public boss list or loot table yet (ForeverChanges: 0 bosses / 0 drops recorded)" },
        status = "minimal",
    },
    {
        id = "shaper", name = "Shaper's Terrace", levels = "58-60", where = "Northern Un'Goro Crater", forever = "2026-11-05",
        bosses = {
        },
        notes = { "Titan facility", "Power crystals gathered in Un'Goro used at consoles inside", "No public boss/loot table yet" },
        status = "minimal",
    },
}

-- Rough stat weights per class, only to make the tooltip line meaningful in
-- the proof of concept. Real weights would be per spec and tuned for
-- Forever's stats (Haste, Expertise, unified Hit/Crit).
ns.Weights = {
    WARRIOR = { STR = 1.0, AGI = 0.6, STA = 0.5, CRIT = 0.8, HIT = 0.8, HASTE = 0.6, AP = 0.45, ARMOR = 0.01 },
    ROGUE   = { AGI = 1.0, STR = 0.4, STA = 0.4, CRIT = 0.8, HIT = 0.9, HASTE = 0.7, AP = 0.45 },
    HUNTER  = { AGI = 1.0, INT = 0.3, STA = 0.4, CRIT = 0.8, HIT = 0.9, HASTE = 0.6, AP = 0.45 },
    MAGE    = { INT = 1.0, SPI = 0.4, STA = 0.4, SP = 0.9, CRIT = 0.7, HIT = 0.9, HASTE = 0.7 },
    WARLOCK = { INT = 0.9, SPI = 0.3, STA = 0.6, SP = 1.0, CRIT = 0.6, HIT = 0.9, HASTE = 0.7 },
    PRIEST  = { INT = 1.0, SPI = 0.8, STA = 0.4, SP = 0.9, CRIT = 0.5, HASTE = 0.6 },
    PALADIN = { STR = 0.8, INT = 0.7, STA = 0.5, SP = 0.6, CRIT = 0.7, HIT = 0.6, AP = 0.35, ARMOR = 0.01 },
    SHAMAN  = { INT = 0.8, AGI = 0.5, STR = 0.5, STA = 0.4, SP = 0.7, CRIT = 0.7, HASTE = 0.6, AP = 0.35 },
    DRUID   = { AGI = 0.7, INT = 0.7, STR = 0.5, STA = 0.5, SP = 0.6, CRIT = 0.6, AP = 0.35, ARMOR = 0.01 },
}

-- Raids for the Raids page and raid planning (sample). Boss lists are WoW
-- Classic's; WoW Forever's raid sizes (joint 10- and 20-player raids) and
-- new raids may differ, so the size here is only the planner's default.
ns.Raids = {
    {
        id = "zg", name = "Zul'Gurub", size = 20, where = "Stranglethorn Vale",
        bosses = {
            { "High Priestess Jeklik", "Bat phase: spread out and kill the bats fast." },
            { "High Priest Venoxis", "Snake phase: poison clouds, keep moving." },
            { "High Priestess Mar'li", "Spider adds and poison bolt volley; AoE the spiders." },
            { "Bloodlord Mandokir", "Don't move when he's watching you. Kill the raptor first." },
            { "High Priest Thekal", "Kill all three within ten seconds of each other." },
            { "Hakkar", "Use the Blood Siphon trick: poisoned players remove Corrupted Blood." },
        },
    },
    {
        id = "aq20", name = "Ruins of Ahn'Qiraj", size = 20, where = "Silithus",
        bosses = {
            { "Kurinnaxx", "Mortal Wound stacks: two tanks swap. Avoid the sand traps." },
            { "General Rajaxx", "Waves of adds before the general; hold together." },
            { "Moam", "Drain his mana before he explodes; kill the elementals fast." },
            { "Buru the Gorger", "Kite him into the eggs; burn him at 20%." },
            { "Ayamiss the Hunter", "Kill the larva before it sacrifices someone." },
            { "Ossirian the Unscarred", "Lead him over crystals to strip his immunity." },
        },
    },
    {
        id = "ony", name = "Onyxia's Lair", size = 40, where = "Dustwallow Marsh",
        bosses = {
            { "Onyxia", "Phase 2: kill whelps, don't stand under her. Phase 3: avoid the eruption cracks; tank faces her away." },
        },
    },
    {
        id = "mc", name = "Molten Core", size = 40, where = "Blackrock Mountain",
        bosses = {
            { "Lucifron", "Decurse and dispel Impending Doom." },
            { "Magmadar", "Fear ward or tremor totem; tranq shot the frenzy." },
            { "Gehennas", "Decurse; heal through rain of fire." },
            { "Garr", "Banish the adds; tank the rest away from the raid." },
            { "Baron Geddon", "Living Bomb: run away from the raid." },
            { "Shazzrah", "Hunters kite; decurse." },
            { "Sulfuron Harbinger", "Interrupt the priests' heals." },
            { "Golemagg the Incinerator", "Two tanks on the core hounds; don't let him reach 0 stacks." },
            { "Majordomo Executus", "Spell reflect and damage shields: watch your casts." },
            { "Ragnaros", "Melee steps back before Wrath; kill the sons." },
        },
    },
}
