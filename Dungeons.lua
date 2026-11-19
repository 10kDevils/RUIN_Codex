-- RUIN Codex dungeon data
-- The classic dungeons' level ranges and bosses are WoW Classic's (a sample
-- until RUIN records Forever's). WoW Forever's nine new dungeons, from Hall of
-- Thanes to Shaper's Terrace, come from the launch databases of 2026-11-05 and
-- the Gear, Boss & Loot Watch of 2026-11-19 with QuestieDB's WoW Forever
-- database (forever = the date): levels, entrance, bosses in kill order with tips,
-- dungeon quests, attunement, set bonuses and quest XP where published.
-- status: how complete the public record was (complete, strong, partial,
-- story_only, minimal). Boss loot lives in the loot files (LootForever.lua);
-- Codex also learns drops from what RUIN members actually loot.
local ADDON, ns = ...

ns.Dungeons = {
    {
        id = "rfc", name = "Ragefire Chasm", areas = { 2437 }, levels = "13-18", where = "Cleft of Shadow, Orgrimmar",
        bosses = {
            { "Oggleflint", "Cleaves; turn him away from the group." },
            { "Taragaman the Hungerer", "Fire Nova and an uppercut knockback. Healers stay out of melee range." },
            { "Jergosh the Invoker", "Curses and Immolate. Remove the curse if you can." },
            { "Bazzalan", "Poisons the tank. Cure poison or out-heal it." },
        },
    },
    {
        id = "wc", name = "Wailing Caverns", areas = { 718 }, levels = "17-24", where = "Northern Barrens",
        bosses = {
            { "Lady Anacondra", "Casts Sleep and heals herself. Interrupt the heal." },
            { "Lord Cobrahn", "Turns into a serpent and poisons." },
            { "Lord Pythas", "Lightning bolts and Sleep; interrupt." },
            { "Lord Serpentis", "Heals himself; interrupt or burst him down." },
            { "Kresh", "A giant turtle in the water; slow but tough." },
            { "Skum", "Deep in the caves with the thunder lizards." },
            { "Verdan the Everliving", "Spawns during the Naralex event; knocks the group down." },
            { "Mutanus the Devourer", "Appears after you escort the Disciple of Naralex, which needs all four Fanglords dead." },
        },
    },
    {
        id = "dm", name = "The Deadmines", areas = { 1581, 10029 }, levels = "17-26", where = "Moonbrook, Westfall",
        bosses = {
            { "Rhahk'Zor", "Hits hard; first boss inside." },
            { "Sneed's Shredder", "Sneed jumps out when the shredder dies. Kill him too." },
            { "Gilnid", "In the foundry with smelter adds." },
            { "Mr. Smite", "Stuns the group and switches weapons as his health drops." },
            { "Captain Greenskin", "On the ship deck with pirates." },
            { "Cookie", "The ship's cook, on deck before VanCleef." },
            { "Edwin VanCleef", "Calls Blackguards to help when wounded. Save cooldowns for the adds." },
        },
    },
    {
        id = "sfk", name = "Shadowfang Keep", areas = { 209, 10014, 10015, 10016, 10017, 10018, 10019 }, levels = "22-30", where = "Silverpine Forest",
        bosses = {
            { "Rethilgore", "Prisoners in the courtyard open the way." },
            { "Razorclaw the Butcher", "Plain melee boss." },
            { "Baron Silverlaine", "Veil of Shadow lowers healing on the tank." },
            { "Commander Springvale", "Heals himself and stuns. Interrupt the heal." },
            { "Odo the Blindwatcher", "Gets stronger as his pack falls; kill quickly." },
            { "Fenrus the Devourer", "Worg boss; Voidwalkers appear when he dies." },
            { "Wolf Master Nandos", "Comes with his worgs; kill the worgs first." },
            { "Archmage Arugal", "Teleports around the room and turns players into worgen." },
        },
    },
    -- The rest of the classic dungeons, by level: entrances and bosses (WoW
    -- Classic). Loot lists come when the data does; RUIN's own drop and kill
    -- tracking works for them now, and their quests come from RUIN Pathfinder.
    {
        id = "stocks", name = "The Stockade", areas = { 717 }, levels = "24-32", where = "Stormwind City, between the Mage Quarter and Old Town",
        bosses = {
            { "Targorr the Dread", "Enrages at low health; burn him down." },
            { "Kam Deepfury", "Defensive stance and shield bash." },
            { "Hamhock", "Chain lightning and bloodlust. Interrupt and spread out." },
            { "Bazil Thredd", "Smoke bomb stuns the group." },
            { "Dextren Ward", "Fear and a curse that drains mana." },
            { "Bruegal Ironknuckle", "Rare: not every run." },
        },
    },
    {
        id = "bfd", name = "Blackfathom Deeps", areas = { 719, 10020, 10021 }, levels = "24-32", where = "Zoram Strand, Ashenvale",
        bosses = {
            { "Ghamoo-ra", "A giant turtle with a thick shell; slow fight." },
            { "Lady Sarevess", "Slows and shoots; tank her away from the casters." },
            { "Gelihast", "Murloc adds; Shadow Bolt and net." },
            { "Lorgus Jett", "Patrols with Blackfathom cultists; not always there." },
            { "Baron Aquanis", "Spawned at the fountain for the Strange Water Globe quest." },
            { "Twilight Lord Kelris", "Puts a player to sleep. Light the shrines to reach Aku'mai." },
            { "Old Serra'kis", "Swims in the flooded room; hits the whole group." },
            { "Aku'mai", "Frenzies and poisons. Dispel and keep healers in range." },
        },
    },
    {
        id = "gnomer", name = "Gnomeregan", areas = { 721, 133, 10030, 10031, 10032 }, levels = "29-38", where = "Dun Morogh, west of Ironforge",
        bosses = {
            { "Grubbis", "Appears with Chomper during Emi Shortfuse's escort." },
            { "Viscous Fallout", "Poison; resistances help." },
            { "Electrocutioner 6000", "Chain lightning. Has the Workshop Key." },
            { "Crowd Pummeler 9-60", "Knocks the group back; keep him away from walls." },
            { "Dark Iron Ambassador", "Rare in the engine room." },
            { "Mekgineer Thermaplugg", "Bombs pop out of the wall vents. Press the buttons to stop them." },
        },
    },
    {
        id = "rfk", name = "Razorfen Kraul", areas = { 491, 1717 }, levels = "29-38", where = "Southern Barrens",
        bosses = {
            { "Roogug", "Calls earth elementals." },
            { "Aggem Thorncurse", "Heals and summons a boar." },
            { "Death Speaker Jargba", "Mind control; break it fast." },
            { "Overlord Ramtusk", "Hard melee hits." },
            { "Agathelos the Raging", "Knocks back and enrages." },
            { "Charlga Razorflank", "Heals her adds and herself; interrupt." },
        },
    },
    -- Scarlet Monastery's four wings, each its own run. group is the whole
    -- monastery: the quest database and Pathfinder know it by that name.
    {
        id = "smgy", name = "Scarlet Monastery Graveyard", short = "SM: Graveyard", group = "Scarlet Monastery", wing = "Graveyard",
        areas = { 796, 6109, 6386, 10008, 10009, 10010 }, levels = "30-37", where = "Tirisfal Glades, north of Brill: the door on the left of the courtyard",
        bosses = {
            { "Interrogator Vishas", "Shadow Word: Pain on the tank; he yells at 60% and 30%." },
            { "Bloodmage Thalnos", "Fire and shadow spells, Flame Spike on the ground. Interrupt and step out." },
            { "Ironspine", "Rare. Poisons the tank; cure it." },
            { "Azshir the Sleepless", "Rare. Silences and fears; stay close so the fear doesn't pull adds." },
            { "Fallen Champion", "Rare. Hits hard; tank him away from the casters." },
        },
    },
    {
        id = "smlib", name = "Scarlet Monastery Library", short = "SM: Library", group = "Scarlet Monastery", wing = "Library",
        areas = { 796, 6109, 6386, 10008, 10009, 10010 }, levels = "33-40", where = "Tirisfal Glades, north of Brill: the second door in the courtyard",
        bosses = {
            { "Houndmaster Loksey", "Comes with three hounds and Bloodlusts them. Kill or crowd-control the dogs." },
            { "Arcanist Doan", "When he casts Arcane Bubble, run: Detonation follows. Silence him if you can." },
        },
    },
    {
        id = "smarm", name = "Scarlet Monastery Armory", short = "SM: Armory", group = "Scarlet Monastery", wing = "Armory",
        areas = { 796, 6109, 6386, 10008, 10009, 10010 }, levels = "36-43", where = "Tirisfal Glades, north of Brill: through the Library wing (needs the Scarlet Key)",
        bosses = {
            { "Herod", "Whirlwind: the tank holds, everyone else steps back. Scarlet Trainees rush in when he dies." },
        },
    },
    {
        id = "smcath", name = "Scarlet Monastery Cathedral", short = "SM: Cathedral", group = "Scarlet Monastery", wing = "Cathedral",
        areas = { 796, 6109, 6386, 10008, 10009, 10010 }, levels = "38-46", where = "Tirisfal Glades, north of Brill: through the Library wing (needs the Scarlet Key)",
        bosses = {
            { "High Inquisitor Fairbanks", "Hidden in the side room of the chapel. Dispel his curses and Power Word: Shield." },
            { "Scarlet Commander Mograine", "Pulls the whole chapel if you're careless. Whitemane revives him; save cooldowns." },
            { "High Inquisitor Whitemane", "Puts the group to sleep and resurrects Mograine. Interrupt her heals." },
        },
    },
    {
        id = "rfd", name = "Razorfen Downs", areas = { 722 }, levels = "37-46", where = "Southern Barrens, near Thousand Needles",
        bosses = {
            { "Tuten'kash", "Spider boss called by the gong." },
            { "Mordresh Fire Eye", "Fire Nova; keep casters spread." },
            { "Glutton", "Enrages at half health." },
            { "Amnennar the Coldbringer", "Frost Nova and Frost Spectres at 50% and 25%." },
        },
    },
    {
        id = "ulda", name = "Uldaman", areas = { 1337, 1517, 10033 }, levels = "41-51", where = "Badlands",
        bosses = {
            { "Revelosh", "Lightning; trogg adds." },
            { "Baelog", "The Lost Dwarves: Baelog, Eric and Olaf together." },
            { "Ironaya", "Knocks the tank back and stomps." },
            { "Obsidian Sentinel", "Splits into shards; kill them as they come." },
            { "Ancient Stone Keeper", "Earth damage around him." },
            { "Galgann Firehammer", "Fire Nova and Flame Shock." },
            { "Grimlok", "Shrinks the tank; lightning." },
            { "Archaedas", "Wakes the stone guardians as he loses health. Kill the adds." },
        },
    },
    {
        id = "zf", name = "Zul'Farrak", areas = { 1176, 978 }, levels = "44-54", where = "Tanaris",
        bosses = {
            { "Antu'sul", "Basilisk adds and healing ward; kill the ward." },
            { "Theka the Martyr", "Becomes immune to physical or magic; switch damage type." },
            { "Witch Doctor Zum'rah", "Zombies rise from the graves; heals with a ward." },
            { "Nekrum Gutchewer", "Comes with Shadowpriest Sezz'ziz at the top of the stairs." },
            { "Sergeant Bly", "The stairs event: free the prisoners, then fight waves of trolls." },
            { "Hydromancer Velratha", "Drops the mallet bits for Gahz'rilla." },
            { "Gahz'rilla", "Summoned with the Mallet of Zul'Farrak. Ice blast and slam." },
            { "Chief Ukorz Sandscalp", "With Ruuzlu. Cleave and enrage." },
        },
    },
    {
        id = "mara", name = "Maraudon", areas = { 2100, 10000 }, levels = "46-55", where = "Desolace",
        bosses = {
            { "Noxxion", "Poison; splits into adds." },
            { "Razorlash", "Knockback and puncture." },
            { "Lord Vyletongue", "Blinks and sneaks; satyr adds." },
            { "Celebras the Cursed", "Redeem him after the fight for the Scepter of Celebras quest." },
            { "Landslide", "Knocks the group back; summons rock elementals." },
            { "Tinkerer Gizlock", "Bombs and a goblin dragon gun." },
            { "Rotgrip", "Puncture; keep the tank healed." },
            { "Princess Theradras", "Repulsive Gaze and dust storms. Kill her for Zaetar's spirit." },
        },
    },
    {
        id = "st", name = "Sunken Temple", areas = { 1477, 1417 }, levels = "50-60", where = "Swamp of Sorrows",
        bosses = {
            { "Atal'alarion", "Summoned by the statues in order on the bottom floor." },
            { "Jammal'an the Prophet", "Mind controls and heals; with Ogom the Wretched." },
            { "Morphaz", "Green dragon on the upper ring; with Hazzas." },
            { "Hazzas", "Green dragon; sleep and acid." },
            { "Shade of Eranikus", "Puts the group to sleep; a warrior or rogue tank is best." },
            { "Avatar of Hakkar", "Summoned with the Egg of Hakkar (quest)." },
        },
    },
    {
        id = "brd", name = "Blackrock Depths", areas = { 1584, 1585 }, levels = "52-60", where = "Blackrock Mountain, between Searing Gorge and Burning Steppes",
        bosses = {
            { "High Interrogator Gerstahn", "Mind flay and fear." },
            { "Lord Roccor", "Earth shock and ground tremor." },
            { "Houndmaster Grebmar", "Bloodlust and demoralizing shout." },
            { "Ring of Law", "The arena: one of six bosses at random." },
            { "Pyromancer Loregrain", "Fire; searing totems." },
            { "Lord Incendius", "Fire Storm; at the Black Anvil." },
            { "Fineous Darkvire", "In the Vault area." },
            { "Bael'Gar", "Summon him with Altered Black Dragonflight Molt (quest)." },
            { "General Angerforge", "Calls adds at low health. Kill fast." },
            { "Golem Lord Argelmach", "Wakes the golems; pull carefully." },
            { "Hurley Blackbreath", "In the Grim Guzzler after the ale kegs." },
            { "Phalanx", "Guards the Grim Guzzler; thunderclap." },
            { "Plugger Spazzring", "The bar; don't steal the ale." },
            { "Ambassador Flamelash", "Burning spirits rush him; kill them first." },
            { "The Seven", "Seven dwarves, one at a time." },
            { "Magmus", "Fire jets from the walls in the throne approach." },
            { "Emperor Dagran Thaurissan", "Don't kill Princess Moira (her quest)." },
        },
    },
    {
        id = "dire", name = "Dire Maul", areas = { 2557, 10022, 10023, 10024, 10025, 10026, 10027 }, levels = "54-60", where = "Feralas",
        bosses = {
            { "Pusillin", "East. Chase him for the Crescent Key." },
            { "Zevrim Thornhoof", "East. Sacrifice; heals." },
            { "Hydrospawn", "East. Water elemental." },
            { "Lethtendris", "East. Shadows and Pimgib." },
            { "Alzzin the Wildshaper", "East. Shapeshifts." },
            { "Tendris Warpwood", "West. Tree; roots and trample." },
            { "Illyanna Ravenoak", "West. Hunter with a pet bear." },
            { "Magister Kalendris", "West. Shadow priest." },
            { "Immol'thar", "West. Turn off the pylons first. Watch for Eye of Immol'thar." },
            { "Prince Tortheldrin", "West. Whirlwind and arcane blast." },
            { "King Gordok", "North. Kill him to become the Gordok; tribute run if no guard dies." },
        },
    },
    {
        id = "brs", name = "Blackrock Spire", areas = { 1583, 10003, 10004, 10005, 10006, 10007 }, levels = "55-60", where = "Blackrock Mountain",
        bosses = {
            { "Highlord Omokk", "Lower Spire. Ogre with knockback." },
            { "Shadow Hunter Vosh'gajin", "Lower Spire. Hex and curse." },
            { "War Master Voone", "Lower Spire. Throws axes; mortal strike." },
            { "Mother Smolderweb", "Lower Spire. Spider; poison." },
            { "Urok Doomhowl", "Lower Spire. Summoned at the challenge pile." },
            { "Quartermaster Zigris", "Lower Spire. Drinks potions; hunter traps." },
            { "Halycon", "Lower Spire. Worg den." },
            { "Overlord Wyrmthalak", "Lower Spire. Calls adds at half health." },
            { "Pyroguard Emberseer", "Upper Spire. Kill the incarcerators, then him." },
            { "Warchief Rend Blackhand", "Upper Spire. Waves of adds first, then Gyth and Rend." },
            { "The Beast", "Upper Spire. Fire, knockback and fear." },
            { "General Drakkisath", "Upper Spire. Off-tank the two Chromatic Elite Guards." },
        },
    },
    {
        id = "scholo", name = "Scholomance", areas = { 2057, 10011, 10012, 10013, 6066, 10077, 10078, 10079 }, levels = "58-60", where = "Caer Darrow, Western Plaguelands",
        bosses = {
            { "Kirtonos the Herald", "Summoned with the Blood of Innocents at the balcony." },
            { "Jandice Barov", "Makes copies of herself; find the real one." },
            { "Rattlegore", "Drops the Viewing Room Key." },
            { "Ras Frostwhisper", "Frost; needs the Frostwhisper quest to be weakened." },
            { "Instructor Malicia", "One of the four Plagued room bosses." },
            { "Darkmaster Gandling", "Teleports players to the side rooms. Clear them all first." },
        },
    },
    {
        id = "strat", name = "Stratholme", areas = { 2017, 10001 }, levels = "58-60", where = "Eastern Plaguelands",
        bosses = {
            { "The Unforgiven", "Live side. Frost and fear." },
            { "Timmy the Cruel", "Live side. Spawns when the square is clear." },
            { "Archivist Galford", "Live side. Burns the scrolls." },
            { "Balnazzar", "Live side. Mind control; the last boss there." },
            { "Baroness Anastari", "Undead side. Possesses a player." },
            { "Nerub'enkan", "Undead side. Spider adds." },
            { "Maleki the Pallid", "Undead side. Frost bolts." },
            { "Ramstein the Gorger", "Undead side. Big knockback; abominations after." },
            { "Baron Rivendare", "Undead side. Kill him within 45 minutes to save Ysida." },
        },
    },
    -- WoW Forever's new dungeons: launch data, 2026-11-05 (Boss & Loot Watch and Launch Snapshot)
    {
        id = "hot", name = "Hall of Thanes", areas = { 16919 }, levels = "13-18", where = "Beneath Ironforge / Dun Morogh", forever = "2026-11-05",
        bosses = {
            { "Faldrim Anvilmar", "Anvilmar's Curse: about 20% attack/cast speed reduction on tank (dispel/remove curse); Mind Blast: interruptible. Putting his spirit to rest completes An Ancient Grudge." },
            { "Magmatus", "Combust: 360-degree AoE - move out; Bloodhound Runts: disease increasing damage taken; Dark Iron Summoners: interrupt Fireballs; Dark Iron Engineers: dynamite AoE; Sap/Polymorph strong." },
            { "Plunder", "Golem encounter; clear nearby trash." },
            { "Durgen Dirgehammer", "Final boss; his head is for Old Ironforge Incursion." },
        },
        quests = { "The Restless Dead", "Important Heirlooms", "An Ancient Grudge", "Old Ironforge Incursion (needs Underground Map first: the Dark Iron Map to Earthseer Farsen)", "The Treaty of Understanding" },
        status = "complete",
    },
    {
        id = "rol", name = "Ruins of Lordaeron", areas = { 16611 }, levels = "15-20", where = "Ruins above Undercity, Tirisfal Glades", forever = "2026-11-05",
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
        id = "exc", name = "Excavation Site: Wetlands", areas = { 16732 }, levels = "24-31", where = "Wetlands, above Whelgar's Excavation", forever = "2026-11-05",
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
        id = "dal", name = "City of Dalaran", areas = { 16544 }, levels = "28-33", where = "Alterac Mountains (violet dome)", forever = "2026-11-05",
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
    -- Updated 2026-11-19: boss lists and quests from the Gear, Boss & Loot Watch and
    -- QuestieDB's WoW Forever database; loot in LootForever.lua
    {
        id = "drowned", name = "The Drowned City", levels = "35-40", where = "Off the Stranglethorn coast; underwater entrance", forever = "2026-11-19",
        bosses = {
            { "Zul'Alai", "Troll boss. Mechanics not published yet." },
            { "Var'Taka", "Brinescale naga; a quest asks for his death (The Only Good Brinescale...)." },
            { "Primeval Elemental", "Drops Heart of the Primeval, a caster trinket reported to drop often." },
            { "Captain Dreadrise", "Saltseer pirate captain; kill 3 Saltseer Coroners nearby for The Saltseer Captain." },
            { "Deathless Marrow", "Its adds make it take more damage. Drops the Ancient Gurubashi Idol for the idol quests." },
            { "Min'loth the Serpent", "Last boss. Drops Maw of Min'loth, a tank shield." },
        },
        quests = { "The Drowned City", "Take Two With Water", "Magics of the Drowned City", "Shady Saltseers", "The Saltseer Captain",
                   "The Only Good Brinescale...", "Ancient Gurubashi Idol", "Ancient Gurubashi Secrets" },
        notes = { "Troll city risen from the sea; naga, murlocs, pirates", "Quest chains start in Booty Bay, Rebel Camp, Grom'gol and Southshore",
                  "Linken's Boots of Iron can drop from any boss" },
        status = "improved",
    },
    {
        id = "kroldok", name = "Krol'dok Stronghold", areas = { 17780 }, levels = "40-45", where = "Riverglades (EK east coast)", forever = "2026-11-19",
        bosses = {
            { "Slavecrusher Grox", "First boss. Mechanics not published yet." },
            { "Twilight Commander Zarmok", "Twilight's Hammer commander; his cultists drop Cultist Ears and Bangles for the Riverglades quests." },
            { "War Handler Ashka", "Worg handler; expect worgs with him." },
            { "Nar'gurk", "Drops the Tome of Twilight and Krol'dok Warplate (the Krol'dok Battlegear set)." },
            { "Bossman Toof", "Mechanics not published yet." },
            { "Overlord Mugg", "Last boss. Jumps and slams: spread out. Drops the Eye of Mugg for the quest, and Emblem of Slamming (trinket)." },
        },
        quests = { "Krol'dok Moulding", "A Token of Vengeance", "Twilight Mementos", "Krol'dok No More!", "Tome of Twilight", "Eye of Mugg", "Vengeance of the Highborne" },
        notes = { "Twilight's Hammer ogre fortress", "Do the Riverglades quests first: they lead here", "Bridge wave encounter with a hole in the bridge" },
        status = "improved",
    },
    {
        id = "alcaz", name = "Alcaz Prison", levels = "48-53", where = "Alcaz Island, Dustwallow Marsh", forever = "2026-11-19",
        bosses = {
            { "Tidemistress Ca'zass", "Naga; her head is needed for A Little Payback / A Bit of Wet Work." },
            { "Overseer Wrex", "Defias overseer. Mechanics not published yet." },
            { "Katerina the Cleaner", "Mechanics not published yet." },
            { "Zarla Ober", "Rides Blazeroar; her loot drops from Blazeroar (enabled by the Nov 9 hotfix)." },
            { "Blazeroar", "Drops Zarla's Journal (The Dragon's Journal) and her loot." },
            { "Commander Folkar", "Orc commander held here; part of No Orc Left Behind and Bad News for Folkar." },
            { "The Questioner", "Drops the shackle key (The Man in the Iron Chains)." },
        },
        quests = { "Right Place, Wrong Time", "The Secret Prison", "No Orc Left Behind", "The Honor of the Kor'kron", "A Little Payback", "A Bit of Wet Work",
                   "Blood Red Bandanas", "The Man in the Iron Chains", "Bad News for Folkar", "The Dragon's Journal" },
        notes = { "Defias against naga; the search for King Varian Wrynn", "Precisely Calibrated Boomstick (epic gun) is reported from here" },
        status = "partial",
    },
    {
        id = "blackmaw", name = "Blackmaw Hold", levels = "55-60", where = "Northern Azshara, behind the sealed furbolg gates", forever = "2026-11-19",
        bosses = {
            { "Impaan the Imprisoner", "Interrupt him; kill his imps before he dies." },
            { "Bonesnout the Unbroken", "Takes 25% less damage for each living Legashi Ritualist: kill the ritualists first. AoE stun." },
            { "Withermaw", "Maggots; AoE fear (Fear Ward, Tremor Totem)." },
            { "Unbound Spirit", "Speak to the NPC; destroy the 3 pillars while protecting the channeler from adds." },
            { "Elder Shaman Bloodmane", "Two spectral wolves: focus the boss or cleave." },
            { "Blackmaw Behemoth", "Kill Clawbert, its healer, first. Enrage, shout and whirlwind." },
            { "Varrox Bleakhoof", "Interrupt Fear and Shadow Bolt Volley. Crimson Wrest mind-controls, then explodes; avoid the ground orbs." },
        },
        quests = { "The Twin Bears", "Get to the Roots of It", "Blackmaw Magic", "Blackmaw Pouches", "The Reliquary of Tyr", "Blackmaw Reclamation" },
        notes = { "Non-linear: several routes through the furbolg city", "On the path toward the Barrow Deeps raid", "Mid-November gold exploit here was fixed (gold removed, abusers suspended)" },
        status = "strong",
    },
    {
        id = "shaper", name = "Shaper's Terrace", areas = { 16985 }, levels = "58-60", where = "Northern Un'Goro Crater", forever = "2026-11-19",
        bosses = {
            { "Vitrix", "Titan construct; drops Sparklance Wand and Bolt's Charged Eyeball, and the others' loot." },
            { "Snowtalon", "Drops Albinofur Grips and Crownroar Chestplate." },
            { "Cinder", "Drops Heartflame Gauntlets." },
        },
        quests = { "Digestible Research", "Panic at the Digsite", "Mapping the Way Forward", "The Dark Crystal", "Crystalline Elements", "Essence of Seeping Slimes" },
        notes = { "Titan facility", "Gather power crystals in Un'Goro for the consoles inside", "Boss list still filling in (Vitrix, Snowtalon and Cinder named in hotfixes)" },
        status = "partial",
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
        id = "zg", name = "Zul'Gurub", areas = { 1977 }, size = 20, where = "Stranglethorn Vale",
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
        id = "aq20", name = "Ruins of Ahn'Qiraj", areas = { 3429 }, size = 20, where = "Silithus",
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
        id = "ony", name = "Onyxia's Lair", areas = { 2159 }, size = 40, where = "Dustwallow Marsh",
        bosses = {
            { "Onyxia", "Phase 2: kill whelps, don't stand under her. Phase 3: avoid the eruption cracks; tank faces her away." },
        },
        notes = { "Returning on WoW Forever on December 9, 2026; attunement through the Drakefire Amulet" },
    },
    {
        id = "barrow", name = "Barrow Deeps", size = 20, where = "Entrances from Blackmaw Hold, Hyjal and Winterspring", forever = "2026-11-19",
        bosses = {},
        notes = { "New WoW Forever raid, opening December 9, 2026", "Bosses and loot not published yet", "Raid size not announced; listed with the 20-player raids for now" },
    },
    {
        id = "hyjal", name = "Hyjal Summit", size = 20, where = "Mount Hyjal", forever = "2026-11-19",
        bosses = {},
        notes = { "WoW Forever raid, opening December 9, 2026", "Bosses and loot not published yet", "Raid size not announced; listed with the 20-player raids for now" },
    },
    {
        id = "mc", name = "Molten Core", areas = { 2717 }, size = 40, where = "Blackrock Mountain",
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

    {
        id = "bwl", name = "Blackwing Lair", areas = { 2677 }, size = 40, where = "Upper Blackrock Spire",
        bosses = {
            { "Razorgore the Untamed", "Control the orb and destroy the eggs." },
            { "Vaelastrasz the Corrupt", "Burning Adrenaline: walk away from the raid before you blow up." },
            { "Broodlord Lashlayer", "Mortal strike and knockback; off the suppression room." },
            { "Firemaw", "Wing buffet stacks; rotate tanks. Line of sight to drop Flame Buffet." },
            { "Ebonroc", "Shadow of Ebonroc heals him; swap tanks." },
            { "Flamegor", "Frenzies: hunters use Tranquilizing Shot." },
            { "Chromaggus", "Two random breaths and five afflictions; bring Hourglass Sand." },
            { "Nefarian", "Class calls. Kill the drakonids, then the dragon." },
        },
    },
    {
        id = "aq40", name = "Temple of Ahn'Qiraj", areas = { 3428, 10040, 10041 }, size = 40, where = "Silithus",
        bosses = {
            { "The Prophet Skeram", "Splits into copies and mind controls." },
            { "Bug Trio", "Vem, Kri and Princess Yauj: kill order decides the poison cloud." },
            { "Battleguard Sartura", "Whirlwinds; stun her guards." },
            { "Fankriss the Unyielding", "Spawns worms; tank swaps." },
            { "Viscidus", "Freeze with frost, then shatter with melee." },
            { "Princess Huhuran", "Nature resistance; tranquilize her frenzy." },
            { "Twin Emperors", "Swap tanks when they teleport. Warlocks tank Vek'lor." },
            { "Ouro", "Sand blast and submerge; tank swaps." },
            { "C'Thun", "Spread out against the eye beam; kill the tentacles inside the stomach." },
        },
    },
    {
        id = "naxx", name = "Naxxramas", areas = { 3456, 10062, 10063, 10064, 10065, 10066 }, size = 40, where = "Floating above Stratholme, Eastern Plaguelands",
        bosses = {
            { "Anub'Rekhan", "Arachnid Quarter. Locust Swarm: kite him." },
            { "Grand Widow Faerlina", "Sacrifice a worshipper to stop her frenzy." },
            { "Maexxna", "Web wrap and web spray; nature resistance." },
            { "Noth the Plaguebringer", "Plague Quarter. Curses to remove; teleports." },
            { "Heigan the Unclean", "The dance: move through the safe zones." },
            { "Loatheb", "Healing only every 20 seconds; use spore buffs." },
            { "Instructor Razuvious", "Mind control the understudies to tank him." },
            { "Gothik the Harvester", "Split the raid across the gate." },
            { "The Four Horsemen", "Rotate tanks between the corners." },
            { "Patchwerk", "Construct Quarter. Hateful Strike: three high-health tanks." },
            { "Grobbulus", "Mutating injection: run to the edge." },
            { "Gluth", "Kite the zombies; Decimate." },
            { "Thaddius", "Polarity shift: plus and minus sides." },
            { "Sapphiron", "Frost resistance; hide behind ice blocks for Frost Breath." },
            { "Kel'Thuzad", "Interrupt Frostbolt; spread out for Detonate Mana." },
        },
    },
}
