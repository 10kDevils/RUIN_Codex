# RUIN Codex

Class macros you can add in one click, a reference of macro commands, a dungeon and raid journal with boss loot and the drops RUIN members loot, and an upgrade line on every item tooltip scored for your spec.

Part of the **RUIN Gaming Companion App**. Requires **RUIN Core** (0.3.15 or later). With **RUIN Muster** installed, runs planned in Codex are posted as Muster events.

## The experience
- **Where it lives:** the Codex tab in the RUIN window (Macros, Journal), item tooltips, and `/codex` (`/codex macros`, `/codex commands`, `/codex journal`, `/codex raids`, `/codex <dungeon or raid>`).
- **Class macros:** 113 ready-made macros for every class and spec plus shared ones for all classes, filtered by class, spec, tag and search. *Add to account* / *Add to character* creates the macro (outside combat; in combat it waits), fills in food, drink and potions from your bags, flags spells you don't know yet, and shows your free slots. Anything that talks in chat asks first, and every macro is checked (255 characters, no `/run` or `/script`). *Copy text* is there when the client can't create macros.
- **Commands:** 47 less-known macro commands and conditions (`/castsequence reset=`, `/cast !Spell`, `/stopmacro`, `/targetexact`, `/tm`, `[@targettarget]`, `[btn:2]`, `/equipslot`, `/click StaticPopup1Button1` ...), grouped as targeting, casting, conditions, items and gear, pet, group and raid, and utility. Each has a working example to copy into the game's macro window or add in one click.
- **Journal:** switch between *Dungeons* and *Raids*. Each entry shows its level range or size and location, then every boss with a one-line tip and the loot it drops (drop chance when known, and "looted 2x by RUIN" when members have it), other drops, and anything RUIN members looted that isn't on the list. Inside a dungeon or raid, Codex opens on it. *Plan a joint RUIN run* posts it to Muster for the day and time you pick: a 5-player run for a dungeon, or 10, 20 or 40 players for a raid, with role needs for that size.
- **Tooltips:** "Codex: +18% upgrade over your chest (Fury)" and "drops in The Deadmines (looted 3x by RUIN)". Items are scored with your spec's weights, covering Forever's Haste and Expertise and its single Hit and Crit stats, and the "Equip:" lines the item API misses (spell damage and healing, school damage, spell crit and hit, attack power, mana per 5, defense). The spec is detected from your talents; change it with *Weights* under the Journal's list or `/codex spec <name|auto>`, and switch the line off with *Tooltip upgrade line*.

## Boss loot data
Loot lists come from data files loaded with Codex. `Loot.lua` describes the format and `LootSample.lua` is the template:

```lua
ns.AddLoot("dm", {                                   -- the Journal entry's id or name
    source = "Where the list comes from",
    verified = false,                                -- true once checked on WoW Forever
    bosses = {
        { "Rhahk'Zor", { 5187, 872 } },              -- boss, then item IDs
        { "Edwin VanCleef", { 5193, { 5191, 18 } } },   -- { item ID, drop chance % }
    },
    trash = { 1156 },                                -- optional: drops from anything inside
})
```

Add a file with one `ns.AddLoot` per instance (list it in `RUIN_Codex.toc` after `LootSample.lua`; a later list replaces the sample). A separate data addon can instead fill the global `RUIN_CodexLoot = { [instance] = data }` before Codex loads, or call `RUIN_API:GetModule("Codex"):AddLoot(instance, data)`.

## What it shares with RUIN
Items you loot inside a dungeon or raid (item and instance).

## Notes
Dungeon and raid data are WoW Classic's as a placeholder, and the Journal says so: the sample Deadmines loot list is marked *Not checked on Forever*. Stat weights are a reasoned starting point, not simulation output. Gear tracking (best-in-slot lists, a gear path) moved out of Codex in 0.3.10; RUIN will use a dedicated gear addon for it.
