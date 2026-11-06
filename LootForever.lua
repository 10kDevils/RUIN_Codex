-- RUIN Codex: WoW Forever dungeon loot (launch, 2026-11-05)
-- Generated from the WoW Forever Boss & Loot Watch and the Launch Snapshot databases
-- (build 1.60.1.70790; community guides: ForeverChanges, Wowhead Forever, Icy Veins,
-- Mobalytics, Timesaver, wowsrc). Items are by name and slot until RUIN members loot
-- them: once the game knows an item, the Journal shows its link. Unverified.
local ADDON, ns = ...
if not ns.AddLoot then return end

ns.AddLoot("hot", {
    source = "WoW Forever launch guides, Nov 5 2026 (complete)",
    verified = false,
    bosses = {
        { "Faldrim Anvilmar", { { name = "Ephemeral Choker", info = "Neck, +Spirit / stamina variants reported" }, { name = "Aetherwisp Bracers", info = "Wrist Cloth, Spell power" }, { name = "Spiritwraith Drape", info = "Back, +Agi +Spirit" } } },
        { "Magmatus", { { name = "Kindlegem Girdle", info = "Waist Mail" }, { name = "Flamefist Grips", info = "Hands Leather" }, { name = "Fang of Magmatus", info = "MH Dagger, Spell power" } } },
        { "Plunder", { { name = "Golemheart Stave", info = "2H Staff, Spell power / fire resist" }, { name = "Treads of the Protector Golem", info = "Feet Mail" }, { name = "Golemguard Chest", info = "Chest Mail" } } },
        { "Durgen Dirgehammer", { { name = "Durgen's Crescent Axe", info = "MH Axe" }, { name = "Direhammer Leggings", info = "Legs Leather" }, { name = "Robes of the Disgraced Thane", info = "Chest Cloth" } } },
    },
})

ns.AddLoot("rol", {
    source = "WoW Forever launch guides, Nov 5 2026 (complete)",
    verified = false,
    bosses = {
        { "Witherfang", { { name = "Atrophic Girdle", info = "Mail Waist" }, { name = "Witherbite Bracers", info = "Leather Wrist" }, { name = "Segmented Spider Leg", info = "Agi Staff" } } },
        { "The Baron", { { name = "Meathook Slicer", info = "Dagger" }, { name = "Abomination Bones", info = "Mail Chest" }, { name = "Leftover Abomination Skin", info = "Cloth Chest" } } },
        { "The Abandoned", { { name = "Rotmender's Leggings", info = "Cloth Legs" }, { name = "Grip of Fear", info = "Mail Hands" }, { name = "Scepter of the Abandoned", info = "SP Mace" } } },
        { "Bjork", { { name = "Tuskwrap Belt", info = "Cloth" }, { name = "Bonerust Leggings", info = "Mail" }, { name = "Corpse Chopper", info = "2H Axe" } } },
        { "Rath'mael", { { name = "Mirror of Rath'mael", info = "Shield" }, { name = "Rotmender's Treads", info = "Cloth Feet" }, { name = "Coldspire Staff", info = "Frost SP" } } },
        { "Viktor the Vile", { { name = "Bloodied Chestwraps" }, { name = "Vilewalkers" }, { name = "Vileblood Scimitar" } } },
        { "Lordaeron Captain", { { name = "Phantom Armor" }, { name = "Haunting Blade" } } },
    },
})

ns.AddLoot("exc", {
    source = "WoW Forever launch guides, Nov 5 2026 (complete)",
    verified = false,
    bosses = {
        { "Saltspine", { { name = "Supple Bellyskin Leggings", info = "Legs Leather, +Str +Sta - strong tank" }, { name = "Saltscale Girdle", info = "Waist Mail, +Str +Int" }, { name = "Glinteye Slippers", info = "Feet Cloth, Spell power" } } },
        { "Shadetooth", { { name = "Raptorclaw Greaves", info = "Feet Mail" }, { name = "Garb of Florid Feathers", info = "Chest Leather, +Agi +Int" }, { name = "Raptor's Gaze", info = "Off-hand, Spell power" }, { name = "Blueprint: Greenhouse", info = "Camp blueprint, Herbalism 140" } } },
        { "Highland Horror", {  } },
        { "Relic Guardian", { { name = "Reliquary Mantle", info = "Shoulder Mail, +Sta +hit" }, { name = "Ring of Power Regulation", info = "Finger, MP5 / SP" }, { name = "Golemsight Long Gun", info = "Gun, +Agi" }, { name = "Blueprint: Rock Garden", info = "Camp blueprint, Mining 140" }, { name = "Titan Relic", info = "Quest item, Starts Alliance/Horde chains" } } },
    },
})

ns.AddLoot("dal", {
    source = "WoW Forever launch guides, Nov 5 2026 (strong)",
    verified = false,
    bosses = {
        { "Atrexis the Grave Knight", { { name = "Graveweave Bindings", info = "Cloth Wrist" }, { name = "Bonebinder's Signet", info = "Finger" }, { name = "Gravespike Repeater", info = "Crossbow" } } },
        { "Lyn the Ignored", { { name = "Cartilage Shapers" }, { name = "Tendonscraper Dagger", info = "caster MH" }, { name = "Bonepile Gaze" } } },
        { "Arcane Anomaly", { { name = "Runemender's Seal", info = "healer ring" }, { name = "Ephemeral Grips", info = "Cloth Hands" }, { name = "Mana-Warped Chain Shirt", info = "Mail Chest" } } },
        { "Arcanic Enigma", { { name = "Wand of Mana Concentration" }, { name = "Violet Sorcerer's Robes" }, { name = "Drape of Shifting Energy" } } },
        { "Unstable Sentinel", { { name = "Guardian's Dualblade", info = "2H Axe" }, { name = "Unstable Crystalline Shoulderpads", info = "Leather" }, { name = "Refractory Scaleguards", info = "Mail Legs" }, { name = "Blueprint: Spinning Wheel" } } },
        { "Mana Devourer", { { name = "Spine of the Devourer", info = "2H Staff SP" }, { name = "Slitherwrap Girdle", info = "Leather Waist" }, { name = "Manascale Treads", info = "Mail Feet" } } },
        { "Fel Ancient", { { name = "Blightleaf Rope", info = "Cloth Waist" }, { name = "Garb of Fallen Felbark" }, { name = "Felbough Arm" } } },
        { "Shade of the Archmage", { { name = "Ponderous Orb", info = "healer OH" }, { name = "Violet Sorcerer's Mantle" }, { name = "Archmagister's Faceted Pendant" }, { name = "Blueprint: Arcane Salvager" } } },
    },
})
