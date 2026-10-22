-- RUIN Codex: SAMPLE loot data for the Journal
-- A template for the boss loot database: copy this file (for example to
-- Loot_Dungeons.lua), add it to RUIN_Codex.toc after LootSample.lua, and fill
-- in one ns.AddLoot(...) per dungeon or raid. See Loot.lua for the format.
-- A file loaded later replaces an instance's sample list.
--
-- The Deadmines list below is World of Warcraft Classic's boss loot (item
-- IDs as on Wowhead Classic), so the Journal has something to show. WoW
-- Forever may have changed it: it is marked unverified until a RUIN member
-- confirms the drops on Forever. Codex also learns real drops on its own
-- whenever RUIN members loot something inside an instance.
local ADDON, ns = ...
if not ns.AddLoot then return end

ns.AddLoot("dm", {
    source = "WoW Classic loot tables (sample, not yet checked on Forever)",
    verified = false,
    bosses = {
        { "Rhahk'Zor", { { 5187, name = "Rhahk'Zor's Hammer" }, { 872, name = "Rockslicer" } } },
        { "Sneed's Shredder", { { 2169, name = "Buzzer Blade" } } },
        { "Sneed", { { 5194, name = "Taskmaster Axe" }, { 5195, name = "Gold-flecked Gloves" } } },
        { "Gilnid", { { 1156, name = "Lavishly Jeweled Ring" }, { 5199, name = "Smelting Pants" } } },
        { "Mr. Smite", { { 7230, name = "Smite's Mighty Hammer" }, { 5196, name = "Smite's Reaver" }, { 5192, name = "Thief's Blade" } } },
        { "Captain Greenskin", { { 5201, name = "Emberstone Staff" } } },
        { "Edwin VanCleef", { { 5193, name = "Cape of the Brotherhood" }, { 5191, name = "Cruel Barb" },
                              { 10399, name = "Blackened Defias Armor" }, { 5202, name = "Corsair's Overshirt" } } },
        { "Cookie", { { 5197, name = "Cookie's Tenderizer" }, { 5198, name = "Cookie's Stirring Rod" } } },
    },
})

-- A WoW Forever dungeon waiting for its list. Fill in the bosses and item IDs
-- as RUIN learns them (the Journal shows what members have looted meanwhile):
-- ns.AddLoot("hot", {
--     source = "RUIN members' loot, Forever beta 1.60.1",
--     verified = true,
--     bosses = {
--         { "Faldrim Anvilmar", { { 000000, name = "Item name" }, 000000 } },
--         { "Durgen Dirgehammer", { 000000, { 000000, 20 } } },
--     },
-- })
