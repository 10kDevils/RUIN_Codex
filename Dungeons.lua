-- RUIN Codex dungeon data (sample)
-- Level ranges and bosses are from WoW Classic. WoW Forever has changed
-- level ranges and added dungeons (Hall of Thanes, Ruins of Lordaeron), so
-- this is placeholder data to test the experience. Boss loot lists live in
-- loot data files (Loot.lua, LootSample.lua); Codex also learns drops from
-- what RUIN members actually loot.
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
    {
        id = "hot", name = "Hall of Thanes", levels = "13-18", where = "Old Ironforge, Ironforge (new in WoW Forever)",
        bosses = {
            { "Faldrim Anvilmar", "No tips recorded yet." },
            { "Durgen Dirgehammer", "Last boss; his head is needed for Old Ironforge Incursion." },
        },
    },
    {
        id = "rol", name = "Ruins of Lordaeron", levels = "?", where = "New in WoW Forever",
        bosses = { { "(unknown)", "No data yet. Drops learned by RUIN members will appear below." } },
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
