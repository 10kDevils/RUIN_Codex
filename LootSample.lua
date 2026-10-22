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
        { "Rhahk'Zor", { 5187, 872 } },                    -- Rhahk'Zor's Hammer, Rockslicer
        { "Sneed's Shredder", { 2169 } },                 -- Buzzer Blade
        { "Sneed", { 5194, 5195 } },                       -- Taskmaster Axe, Gold-flecked Gloves
        { "Gilnid", { 1156, 5199 } },                      -- Lavishly Jeweled Ring, Smelting Pants
        { "Mr. Smite", { 7230, 5196, 5192 } },             -- Smite's Mighty Hammer, Smite's Reaver, Thief's Blade
        { "Captain Greenskin", { 5201 } },                 -- Emberstone Staff
        { "Edwin VanCleef", { 5193, 5191, 10399, 5202 } }, -- Cape of the Brotherhood, Cruel Barb,
                                                           -- Blackened Defias Armor, Corsair's Overshirt
        { "Cookie", { 5197, 5198 } },                      -- Cookie's Tenderizer, Cookie's Stirring Rod
    },
})

-- A WoW Forever dungeon waiting for its list. Fill in the bosses and item IDs
-- as RUIN learns them (the Journal shows what members have looted meanwhile):
-- ns.AddLoot("hot", {
--     source = "RUIN members' loot, Forever beta 1.60.1",
--     verified = true,
--     bosses = {
--         { "Faldrim Anvilmar", { 000000, 000000 } },
--         { "Durgen Dirgehammer", { 000000, { 000000, 20 } } },
--     },
-- })
