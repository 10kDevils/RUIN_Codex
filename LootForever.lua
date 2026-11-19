-- RUIN Codex: WoW Forever dungeon loot
-- Boss drops with their item IDs, from QuestieDB's WoW Forever database (1.1.3,
-- 2026-11-19: build 1.60.1.70959) checked against the Gear, Boss & Loot Watch
-- database of the same day and the launch guides (ForeverChanges, Wowhead
-- Forever, Icy Veins, Mobalytics, Timesaver), plus ForeverDB's dungeon pages and
-- QuestieDB's development data of Nov 18. With item IDs the Journal shows
-- each drop's link and Best in Slot can weigh it. Quest items are marked so
-- they stay out of gear advice. Unverified until RUIN members loot them.
local ADDON, ns = ...
if not ns.AddLoot then return end

ns.AddLoot("hot", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (complete)",
    verified = false,
    bosses = {
        { "Faldrim Anvilmar", { { 270227, name = "Ephemeral Choker", info = "Neck, +Spirit / stamina variants reported" }, { 271096, name = "Aetherwisp Bracers", info = "Wrist Cloth, Spell power" }, { 271097, name = "Spiritwraith Drape", info = "Back, +Agi +Spirit" } } },
        { "Magmatus", { { 270230, name = "Kindlegem Girdle", info = "Waist Mail" }, { 270231, name = "Flamefist Grips", info = "Hands Leather" }, { 271095, name = "Fang of Magmatus", info = "MH Dagger, Spell power" } } },
        { "Plunder", { { 270228, name = "Golemheart Stave", info = "2H Staff, Spell power / fire resist" }, { 270229, name = "Treads of the Protector Golem", info = "Feet Mail" }, { 271098, name = "Golemguard Chest", info = "Chest Mail" } } },
        { "Durgen Dirgehammer", { { 270256, name = "Durgen's Crescent Axe", info = "MH Axe" }, { 270260, name = "Direhammer Leggings", info = "Legs Leather" }, { 270261, name = "Robes of the Disgraced Thane", info = "Chest Cloth" }, { 274286, name = "Durgen Dirgehammer's Head", info = "Quest item", quest = true } } },
    },
})

ns.AddLoot("rol", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (complete)",
    verified = false,
    trash = { { 286977, name = "Sword of the Fallen", info = "Two-hand Sword, level 18; from the ghouls" }, { 286978, name = "Rotmender's Garb", info = "Cloth chest, level 18; Rotmender's Raiment set" }, { 286979, name = "Rotmender's Gloves", info = "Cloth hands, level 17; Rotmender's Raiment set" }, { 286980, name = "Rotmender's Sash", info = "Cloth waist, level 17; Rotmender's Raiment set" }, { 286981, name = "Death Bindings", info = "Mail wrist, level 16" } },
    bosses = {
        { "Witherfang", { { 271201, name = "Atrophic Girdle", info = "Mail Waist" }, { 271202, name = "Witherbite Bracers", info = "Leather Wrist" }, { 271203, name = "Segmented Spider Leg", info = "Agi Staff" }, { 275443, name = "Highly Toxic Strain", info = "Quest item", quest = true } } },
        { "The Baron", { { 268518, name = "Head of the Baron", info = "Quest item", quest = true }, { 271204, name = "Meathook Slicer", info = "Dagger" }, { 271205, name = "Abomination Bones", info = "Mail Chest" }, { 271206, name = "Leftover Abomination Skin", info = "Cloth Chest" } } },
        { "The Abandoned", { { 271207, name = "Rotmender's Leggings", info = "Cloth Legs" }, { 271208, name = "Grip of Fear", info = "Mail Hands" }, { 271216, name = "Scepter of the Abandoned", info = "SP Mace" } } },
        { "Bjork", { { 271209, name = "Bonerust Leggings", info = "Mail" }, { 271210, name = "Tuskwrap Belt", info = "Cloth" }, { 271217, name = "Corpse Chopper", info = "2H Axe" } } },
        { "Rath'mael", { { 251961, name = "Arcane Mote", info = "Quest item", quest = true }, { 271213, name = "Mirror of Rath'mael", info = "Shield" }, { 271214, name = "Rotmender's Treads", info = "Cloth Feet" }, { 271215, name = "Coldspire Staff", info = "Frost SP" }, { 273085, name = "Blueprint: Fermenter", info = "Camp blueprint" }, { 273103, name = "Blueprint: Arcane Salvager", info = "Camp blueprint" } } },
        { "Viktor the Vile", { { 271211, name = "Vilewalkers", info = "Mail, level 17" }, { 271212, name = "Bloodied Chestwraps", info = "Leather, level 17" }, { 271218, name = "Vileblood Scimitar", info = "One-hand Sword, level 17" } } },
        { "Lordaeron Captain", { { 251342, name = "Plans: Protector's Chain Shirt", info = "Recipe" }, { 251343, name = "Plans: Acolyte's Chain Shirt", info = "Recipe" }, { 251344, name = "Plans: Crusader's Chain Shirt", info = "Recipe" }, { 252771, name = "Pattern: Brawler's Leather Armor", info = "Recipe" }, { 252772, name = "Pattern: Trapper's Leather Armor", info = "Recipe" }, { 252773, name = "Pattern: Defender's Leather Armor", info = "Recipe" }, { 252776, name = "Pattern: Wisdom's Leather Armor", info = "Recipe" }, { 253912, name = "Pattern: Filigreed Shining Gown", info = "Recipe, level 1" }, { 6641, name = "Haunting Blade", info = "Two-hand Sword, level 22" } } },
    },
})

ns.AddLoot("exc", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (complete)",
    verified = false,
    trash = { { 286982, name = "Unearthed Barrier", info = "Shield, level 27; boss unconfirmed" }, { 286985, name = "Thicket Bindings", info = "Leather, level 26; boss unconfirmed" }, { 286986, name = "Abandoned Leggings", info = "Cloth, level 26; boss unconfirmed" }, { 287068, name = "Excavated Dagger", info = "Thrown, level 28; boss unconfirmed" } },
    bosses = {
        { "Saltspine", { { 273022, name = "Supple Bellyskin Leggings", info = "Legs Leather, +Str +Sta - strong tank" }, { 273023, name = "Saltscale Girdle", info = "Waist Mail, +Str +Int" }, { 273024, name = "Glinteye Slippers", info = "Feet Cloth, Spell power" } } },
        { "Shadetooth", { { 271100, name = "Thicket Raptor Meat", info = "Quest item", quest = true }, { 273025, name = "Raptorclaw Greaves", info = "Feet Mail" }, { 273026, name = "Garb of Florid Feathers", info = "Chest Leather, +Agi +Int" }, { 273027, name = "Raptor's Gaze", info = "Off-hand, Spell power" }, { 273106, name = "Blueprint: Greenhouse", info = "Camp blueprint, Herbalism 140" }, { 284845, name = "Thicket Raptor Hide", info = "Quest item", quest = true } } },
        { "Highland Horror", { { 270180, name = "Horrible Rootcore", info = "Quest item", quest = true } } },
        { "Relic Guardian", { { 270865, name = "Titan Relic", info = "Quest item, Starts Alliance/Horde chains", quest = true }, { 270866, name = "Titan Relic", info = "Quest item, Starts Alliance/Horde chains", quest = true }, { 273028, name = "Reliquary Mantle", info = "Shoulder Mail, +Sta +hit" }, { 273029, name = "Golemsight Long Gun", info = "Gun, +Agi" }, { 273030, name = "Ring of Power Regulation", info = "Finger, MP5 / SP" }, { 273097, name = "Blueprint: Rock Garden", info = "Camp blueprint, Mining 140" } } },
    },
})

ns.AddLoot("dal", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (strong)",
    verified = false,
    trash = { { 286987, name = "Violet Sorcerer's Sandals", info = "Cloth feet, level 28; Violet Sorcerer's Vestments" }, { 286988, name = "Violet Sorcerer's Leggings", info = "Cloth legs, level 29; Violet Sorcerer's Vestments" }, { 286989, name = "Violet Sorcerer's Wraps", info = "Cloth wrist, level 28; Violet Sorcerer's Vestments, also Arcane Anomaly" }, { 286990, name = "Arcane Remnant Leggings", info = "Leather legs, level 28" }, { 286991, name = "Roused Nature Footwraps", info = "Leather feet, level 27" }, { 286992, name = "Construct's Grips", info = "Mail hands, level 28" }, { 286995, name = "Guardian's Emblem", info = "Level 28" }, { 286996, name = "City Guard's Tarnished Blade", info = "One-hand Sword, level 29" }, { 286994, name = "Tattered Kirin Tor Cloak", info = "Back, level 28; source unconfirmed" } },
    bosses = {
        { "Atrexis the Grave Knight", { { 273032, name = "Bonebinder's Signet", info = "Finger" }, { 273033, name = "Gravespike Repeater", info = "Crossbow" }, { 273036, name = "Graveweave Bindings", info = "Cloth Wrist" } } },
        { "Lyn the Ignored", { { 273053, name = "Tendonscraper Dagger", info = "caster MH" }, { 273054, name = "Cartilage Shapers", info = "Leather, level 28" }, { 273055, name = "Bonepile Gaze", info = "Shield, level 28" } } },
        { "Arcane Anomaly", { { 273031, name = "Runemender's Seal", info = "healer ring" }, { 273034, name = "Ephemeral Grips", info = "Cloth Hands" }, { 273035, name = "Mana-Warped Chain Shirt", info = "Mail Chest" } } },
        { "Arcanic Enigma", { { 273043, name = "Wand of Mana Concentration", info = "Wand, level 27" }, { 273044, name = "Violet Sorcerer's Robes", info = "Cloth, level 27" }, { 273045, name = "Drape of Shifting Energy", info = "Level 27" } } },
        { "Unstable Sentinel", { { 273046, name = "Guardian's Dualblade", info = "2H Axe" }, { 273047, name = "Unstable Crystalline Shoulderpads", info = "Leather" }, { 273048, name = "Refractory Scaleguards", info = "Mail Legs" }, { 273099, name = "Blueprint: Spinning Wheel", info = "Camp blueprint" }, { 275997, name = "Cracked Sentry Core", info = "Quest item", quest = true } } },
        { "Mana Devourer", { { 273040, name = "Spine of the Devourer", info = "2H Staff SP" }, { 273041, name = "Slitherwrap Girdle", info = "Leather Waist" }, { 273042, name = "Manascale Treads", info = "Mail Feet" } } },
        { "Fel Ancient", { { 273037, name = "Felbough Arm", info = "Polearm, level 29" }, { 273038, name = "Garb of Fallen Felbark", info = "Leather, level 29" }, { 273039, name = "Blightleaf Rope", info = "Cloth Waist" } } },
        { "Shade of the Archmage", { { 251961, name = "Arcane Mote", info = "Quest item", quest = true }, { 273049, name = "Archmagister's Faceted Pendant", info = "Level 30" }, { 273051, name = "Violet Sorcerer's Mantle", info = "Cloth, level 30" }, { 273052, name = "Ponderous Orb", info = "healer OH" }, { 273103, name = "Blueprint: Arcane Salvager", info = "Camp blueprint" } } },
    },
})

ns.AddLoot("drowned", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (improved)",
    verified = false,
    trash = { { 271718, name = "Linken's Boots of Iron", info = "Mail, level 33; any boss can drop them" }, { 287002, name = "Risen Sentry's Links", info = "Mail, level 35; Risen Sentries" } },
    bosses = {
        { "Zul'Alai", { { 274598, name = "Bloodslash Axe", info = "One-hand Axe, level 34" }, { 274599, name = "Oathbound Bracers", info = "Leather, level 34" }, { 274600, name = "Berserker Shackles", info = "Mail, level 34" } } },
        { "Var'Taka", { { 274601, name = "Harpoon of Command", info = "Polearm, level 35" }, { 274602, name = "Brinebelly Leggings", info = "Leather, level 35" }, { 274613, name = "Priestess Cloak", info = "Level 35" } } },
        { "Primeval Elemental", { { 274611, name = "Robe of the Drowned", info = "Cloth, level 35" }, { 274612, name = "Waterlogged Burial Shroud", info = "Level 35" }, { 274615, name = "Heart of the Primeval", info = "Level 35" } } },
        { "Captain Dreadrise", { { 274603, name = "Dreadfrost Saber", info = "One-hand Sword, level 35" }, { 274604, name = "Frosty Blunderbuss", info = "Gun, level 35" }, { 274605, name = "Briny Sash", info = "Cloth, level 35" } } },
        { "Deathless Marrow", { { 274606, name = "Bloodspine Staff", info = "Staff, level 36" }, { 274607, name = "Viscera Spaulders", info = "Mail, level 36" }, { 274614, name = "Knucklebone Ring", info = "Level 36" }, { 276894, name = "Ancient Gurubashi Idol", info = "Quest item", quest = true } } },
        { "Min'loth the Serpent", { { 274608, name = "Maw of Min'loth", info = "Shield, level 37" }, { 274609, name = "Serpentbane Crown", info = "Mail, level 37" }, { 274610, name = "Ritual-Binder's Gloves", info = "Leather, level 37" } } },
    },
})

ns.AddLoot("kroldok", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (improved)",
    verified = false,
    trash = { { 287013, name = "Krol'dok Warplate Legplates", info = "Plate legs, level 41; Twilight's Hammer and Krol'dok trash" }, { 287010, name = "Outrider's Gloves", info = "Leather hands, level 39; Twilight Outriders" }, { 287012, name = "Krol'dok Warplate Gauntlets", info = "Plate hands, level 40; source unconfirmed" }, { 287014, name = "Krol'dok Warplate Pauldrons", info = "Plate shoulders, level 41; source unconfirmed" } },
    bosses = {
        { "Slavecrusher Grox", { { 273101, name = "Blueprint: Expert Campfire", info = "Camp blueprint" }, { 274995, name = "Slavecrusher Scepter", info = "One-hand Mace, level 39" }, { 274996, name = "Resistance Breaker Spaulder", info = "Mail, level 39" }, { 274997, name = "Chain of Binding", info = "Mail, level 39" } } },
        { "Twilight Commander Zarmok", { { 267091, name = "Cultist Ear", info = "Quest item", quest = true }, { 267234, name = "Twilight Bangle", info = "Quest item", quest = true }, { 274998, name = "Shadowlight Athame", info = "Dagger, level 40" }, { 274999, name = "Shadecaster's Leggings", info = "Cloth, level 40" }, { 275000, name = "Zarmok's Plated Signet", info = "Level 40" } } },
        { "War Handler Ashka", { { 275001, name = "Bloodied Gutslicer", info = "Two-hand Sword, level 40" }, { 275002, name = "War Handler's Gaze", info = "Leather, level 40" }, { 275003, name = "Worgbinder's Treads", info = "Plate, level 40" } } },
        { "Nar'gurk", { { 267104, name = "Tome of Twilight", info = "Quest item", quest = true }, { 275004, name = "Chain of the Corruptor", info = "Level 41" }, { 275005, name = "Krol'dok Warplate Chest", info = "Plate, level 41" }, { 275006, name = "Krol'dok Warplate Helmet", info = "Plate, level 41" } } },
        { "Bossman Toof", { { 286428, name = "Band of Bossman", info = "Level 40" }, { 286429, name = "Big-Belly Belt", info = "Cloth, level 40" }, { 286430, name = "Toofbreaker", info = "One-hand Mace, level 40" } } },
        { "Overlord Mugg", { { 267086, name = "Eye of Mugg", info = "Quest item", quest = true }, { 275007, name = "Mugg's Jabber", info = "Fist Weapon, level 42" }, { 275008, name = "Mugg's Crosser", info = "Fist Weapon, level 42" }, { 275009, name = "Emblem of Slamming", info = "Level 42" }, { 275010, name = "Strongly Scented Hood", info = "Cloth, level 42" } } },
    },
})

ns.AddLoot("alcaz", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (partial)",
    verified = false,
    bosses = {
        { "Tidemistress Ca'zass", { { 273883, name = "Ca'zass's Head", info = "Quest item", quest = true }, { 276735, name = "Tidesong Wand", info = "Wand, level 47" }, { 276736, name = "Seascale Bracers", info = "Mail, level 47" }, { 276737, name = "Cloak of the Tidemistress", info = "Level 47" } } },
        { "Overseer Wrex", { { 274028, name = "Blood Red Bandana", info = "Quest item", quest = true }, { 276732, name = "Alcaz Willcrusher", info = "Two-hand Mace, level 47" }, { 276733, name = "Grips of Control", info = "Plate, level 47" }, { 276734, name = "Wrex's Pinky Ring", info = "Level 47" } } },
        { "Katerina the Cleaner", { { 274028, name = "Blood Red Bandana", info = "Quest item", quest = true }, { 276738, name = "Katerina's Shanker", info = "Dagger, level 49" }, { 276739, name = "Cutthroat Chestguard", info = "Mail, level 49" }, { 276740, name = "Sentimental Locket", info = "Level 49" } } },
        { "Zarla Ober", {  } },
        { "Blazeroar", { { 276744, name = "Zarla's Snack Pouch", info = "Level 50" }, { 276745, name = "Beastbond Robe", info = "Cloth, level 50" }, { 276746, name = "Defias Enforcer's Legguards", info = "Leather, level 50" }, { 276890, name = "Zarla's Journal", info = "Quest item", quest = true } } },
        { "Commander Folkar", {  } },
        { "The Questioner", { { 274028, name = "Blood Red Bandana", info = "Quest item", quest = true }, { 274029, name = "Ornate Shackle Key", info = "Quest item", quest = true }, { 276741, name = "Defias Enforcer's Shoulderpads", info = "Leather, level 48" }, { 276742, name = "Girdle of Extracted Answers", info = "Plate, level 48" }, { 276743, name = "Fingerbreaker Stamp", info = "Level 48" } } },
    },
})

ns.AddLoot("blackmaw", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (strong)",
    verified = false,
    trash = { { 287030, name = "Blackmaw Bindings", info = "Mail wrist, level 54; source unconfirmed" } },
    bosses = {
        { "Impaan the Imprisoner", { { 249698, name = "Feathered Charm Necklace", info = "Quest item", quest = true }, { 280056, name = "Flameslash Crescent", info = "Two-hand Axe, level 54" }, { 280057, name = "Robes of Dark Summons", info = "Cloth, level 54" }, { 280058, name = "Impish Chain Hood", info = "Mail, level 54" } } },
        { "Bonesnout the Unbroken", { { 249696, name = "Tusks of the Unbroken", info = "Quest item", quest = true }, { 280059, name = "Tuskblade Halberd", info = "Polearm, level 55" }, { 280060, name = "Lucky Shovelnose Tuft", info = "Level 55" }, { 280061, name = "Spike Crested Bracers", info = "Plate, level 55" } } },
        { "Withermaw", { { 249697, name = "Claws of the Great Bear", info = "Quest item", quest = true }, { 280062, name = "Cloak of the Fleshborer", info = "Level 55" }, { 280063, name = "Bloodfur Bulwark", info = "Shield, level 55" }, { 280064, name = "Withering Grips", info = "Leather, level 55" } } },
        { "Unbound Spirit", { { 280071, name = "Flamebreak Talisman", info = "Level 56" }, { 280072, name = "Cowl of Dark Ambition", info = "Cloth, level 56" }, { 280073, name = "Burnished Pridescales", info = "Plate, level 56" } } },
        { "Elder Shaman Bloodmane", { { 276893, name = "Blackmaw Ritual Totem", info = "Quest item", quest = true }, { 280068, name = "Bloody Claws of Attack", info = "Fist Weapon, level 56" }, { 280069, name = "Shamanic Wristguards", info = "Mail, level 56" }, { 280070, name = "Veilpiercer Girdle", info = "Leather, level 56" }, { 286415, name = "Reliquary of Tyr", info = "Quest item", quest = true } } },
        { "Blackmaw Behemoth", { { 280065, name = "Behemoth Bones", info = "Level 56" }, { 280066, name = "Trousers of the Ebon Giant", info = "Cloth, level 56" }, { 280067, name = "Blackmaw Chain Belt", info = "Mail, level 56" } } },
        { "Varrox Bleakhoof", { { 249692, name = "Head of Varrox Bleakhoof", info = "Quest item", quest = true }, { 249698, name = "Feathered Charm Necklace", info = "Quest item", quest = true }, { 280074, name = "Scalding Flamehoof", info = "Level 57" }, { 280075, name = "Bleak Eye Shoulderplates", info = "Plate, level 57" }, { 280076, name = "Horns of Varrox", info = "Leather, level 57" } } },
    },
})

ns.AddLoot("shaper", {
    source = "QuestieDB WoW Forever 1.1.3 and the Gear, Boss & Loot Watch, Nov 19 2026 (partial)",
    verified = false,
    bosses = {
        { "Vitrix", { { 280031, name = "Sparklance Wand", info = "Wand, level 58" }, { 280032, name = "Bolt's Charged Eyeball", info = "Level 58" } } },
        { "Snowtalon", { { 280026, name = "Albinofur Grips", info = "Mail, level 58; also from Vitrix" }, { 280027, name = "Crownroar Chestplate", info = "Plate, level 58; also from Vitrix" } } },
        { "Cinder", { { 280028, name = "Heartflame Gauntlets", info = "Plate, level 58; also from Vitrix" }, { 280029, name = "Cinderedge Crescent", info = "One-hand Axe, level 58" } } },
    },
})
