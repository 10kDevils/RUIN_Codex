# RUIN Codex changelog

Versioning: the third number counts the meaningful changes made since the second number last went up.

## Unreleased

(nothing yet)

## 0.5.3 — 2026-11-06

- Journal tooltips (items, quests) follow the cursor instead of sitting off to the right of the row.
- Every dungeon's full loot list, read from QuestieDB (or Questie) while you play, the way RUIN Pathfinder reads quests (nothing of Questie's is copied into RUIN). Codex finds the NPCs that stand in each dungeon and the items they drop, once, in the background over a few seconds after login, saves the result, and reads it again only when the database changes. Each boss lists its drops with real item IDs (click for the full tooltip), gear first by item level, then recipes, then quest items; rares and bosses the Journal didn't list yet (Cookie, the Ring of Law fighters, Gyth...) get their own lists; *Trash* lists the gear and recipes from the dungeon's other mobs, leaving out potions, trade goods and world drops (items mostly dropped outside the dungeon). The WoW Forever launch lists are merged in (their drops the database lacks stay on the list, by name), and the Classic sample is used only without QuestieDB. Raid lists are partial: the database doesn't carry full raid loot tables. The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold and Shaper's Terrace have no zone in the database yet and keep their launch lists.
- Bosses added to the Journal: Kresh, Skum and Verdan the Everliving (Wailing Caverns), Cookie (the Deadmines), Fenrus the Devourer and Wolf Master Nandos (Shadowfang Keep).

- Every classic dungeon in the Journal: The Stockade, Blackfathom Deeps, Gnomeregan, Razorfen Kraul, Scarlet Monastery, Razorfen Downs, Uldaman, Zul'Farrak, Maraudon, Sunken Temple, Blackrock Depths, Dire Maul, Blackrock Spire, Scholomance and Stratholme, plus the raids Blackwing Lair, Temple of Ahn'Qiraj and Naxxramas. Each has its level range, entrance and bosses with a one-line tip, the dungeon's quests and Quest route, and RUIN's kill, drop and General tracking. Loot lists come when the data does.

- Dungeon quests in the Journal: every quest the dungeon has for your race and class, in level order, each with its level and required level, whether you've done it, have it, are ready to hand it in, need more levels or must do the quests before it first; where it starts and is handed in (marked "inside" when that's in the dungeon); the quests that unlock it, in order, with the ones you've done; and its rewards (from Ruinous Forever Planner's dungeon lists, when installed; click a reward for its tooltip). Click a quest to mark where it starts (or, once you have it, where to go next) on your map. Read from Questie or QuestieDB through RUIN Pathfinder; without them the Journal shows the launch data's quest names and says what to install.
- *Quest route* (beside *Post in Muster*, and a line at the top of the quest list) starts RUIN Pathfinder's route through all of the dungeon's quests and the ones that unlock them.

- Journal items open their full tooltip on click, the way an item link in chat does; shift-click links the item in chat and ctrl-click tries it on. Hovering shows the tooltip too. Before, items RUIN had looted but the game hadn't loaded showed no tooltip; any item with a known ID now has one. A listed drop the game hasn't sent yet says so on hover.
- Boss kill tracker, for reference beside the launch loot list (still the main source): each boss shows how often RUIN killed it, and each listed drop shows "3/12 kills · 25%". Kills come from the encounter events (ENCOUNTER_END, BOSS_KILL) and, on WoW Forever, a boss dying in the combat log; the first RUIN member of the group reports each kill once.
- General: the greens and blues that drop from the dungeon's mobs, from the loot windows RUIN members open inside. Each item shows how often it dropped and an estimated chance per mob looted ("x4 · about 3% per mob"); the heading says how many mobs RUIN has looted there. A corpse counts once however often it's opened; boss corpses, chests and white or grey items don't count. Counts are sent to the org in batches (every 30 seconds, and on leaving), and members who were offline catch up with the drops.

- The ranged slot is scored properly. A ranged weapon's damage per second now counts with its own weight (RDPS) instead of the melee one: casters weigh their wand (Mage, Warlock and Shadow priest 0.9, healing priests lower), hunters weigh their bow, gun or crossbow far above their melee weapon (melee DPS 0.4-0.6, ranged 2.6-3.0), and warriors and rogues weigh it low since it only pulls. Before, a wand with no stats had nothing a caster's spec weighed, so it got no upgrade line, and a hunter's bow counted the same as a melee weapon.
- A weapon's "(12.5 damage per second)" tooltip line is read when the item API leaves the damage out.
- On Retail, which has no ranged slot, bows, guns and wands are compared with the main hand.
- WoW Forever's nine new dungeons from the launch databases (2026-11-05, build 1.60.1.70790): Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, City of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold and Shaper's Terrace, with level ranges, entrances, bosses in kill order with tips from their mechanics, dungeon quests, City of Dalaran's attunement for both factions, the Rotmender's Raiment and Violet Sorcerer's Vestments set bonuses, and quest XP. The Journal marks them "WoW Forever launch data" and says how complete the public record is; dungeons with no published boss list say so.
- Boss loot for the four documented dungeons (70 drops, LootForever.lua), by name and slot until the game knows the item. Loot lists can now hold named items without an item ID ({ name = "...", info = "Neck" }); once a RUIN member loots one, the Journal shows the real item with its link and how often RUIN looted it, and it isn't listed again as an extra drop.
- 19 new class macros (132 in all): every heal and every damage-over-time spell now has a mouseover macro. Heals go to your mouseover, then your target, then yourself; DoTs go to your mouseover enemy, else your target. New: Holy Shock (heals a friend or hurts an enemy), Heal, Lesser Heal, Holy Fire, Devouring Plague, Vampiric Embrace, Swiftmend, Moonfire, Insect Swarm, Rake, Rip, Curse of Agony, Curse of Doom, Viper Sting, Scorpid Sting, Wyvern Sting, Rupture, Garrote (from stealth) and Rend.

## 0.5.2 — 2026-11-05

- Spell damage and healing bonuses are read in every wording Codex has seen: "Increases healing done by magical spells and effects by up to 33", "Increases spell damage by up to 11", "+7 Damage and Healing Spells", "Healing Spells +55", "Spell Damage and Healing +30", enchant lines ("Enchanted: ..."), party auras ("... of all party members within 30 yards by up to 33"), and other server wordings ("Increases the damage and healing of your spells by up to 9"). One spell's modifiers ("... your Lesser Healing Wave spell by 20") and Use: effects are not counted.
- The item API's long stat names (ITEM_MOD_SPELL_HEALING_DONE and friends, without _SHORT) count the same as the short ones.
- `Compare` also takes an item id; new `IsUpgrade(item)` returns true, false or nil (can't tell yet). RUIN Core's party dungeon signal uses it.

## 0.5.1 — 2026-11-04

- `DungeonShort(name)`, `DungeonWhere(name)` and `FindDungeon(name)` on the Codex module, so RUIN Core's party dungeon signal shows Codex's own short names (DM, HOT ...) and the entrance in its tooltip. Names match ignoring case, punctuation and a leading "The".

## 0.5.0 — 2026-11-02

RUIN 0.5.0: every addon in the suite moves to 0.5.0 together. No changes to Codex since 0.4.2.

## 0.4.2 — 2026-11-01

1 change since 0.4.1:

1. **Drops reach the whole org more reliably.**
   - A groupmate who doesn't run RUIN still counts: one RUIN member of the group (the first by name) reports their loot, so each drop is counted once however many RUIN members are there.
   - Only real loot lines count ("receives loot"); items from quests or crafting and the roll system's "won" and "selected" lines no longer do.
   - Members who were offline catch up: when RUIN connects, Codex asks, and a member who knows more drops sends theirs.
   - On Retail, boss loot is also read from the encounter loot event, which still works where loot lines are hidden.

## 0.4.1 — 2026-10-28

Security update (works best with RUIN Core 0.4.5). 1 change since 0.4.0:

1. Learned drops shared by other members are checked (a real item ID and a short instance name) before they're kept.

## 0.4.0 — 2026-10-23 · Beta 1

The RUIN Gaming Companion App enters beta: every addon is now 0.4.0. Nothing changed since 0.3.12 apart from the version number. Report what you find under Settings → Feedback.

## 0.3.12 — 2026-10-23

1 change since 0.3.11:

1. The Journal's text and Codex's lists show a scroll bar only when there is something to scroll.

## 0.3.11 — 2026-10-22

1 change since 0.3.10 (needs RUIN Core 0.3.16):

1. Items in the Journal always show their name, never "item #1234": the game is asked for each item, names seen before are remembered, and loot data files can give names (`{ 5187, name = "Rhahk'Zor's Hammer" }`; the Deadmines sample now does) that show until the game sends the item.

## 0.3.10 — 2026-10-21

4 changes since 0.3.9 (needs RUIN Core 0.3.15):

1. **Gear Path and Best-in-slot are gone.** RUIN will track gear with a dedicated gear addon (and may work with it later). Codex keeps the upgrade line on item tooltips; its settings (the line on or off, and which spec's weights it uses) moved to the bottom of the Journal's list. `/codex path` and `/codex bis` now say where they went. The tooltip line also reads "Equip:" lines the item API misses, such as *Increases damage and healing done by magical spells and effects by up to 12*, school damage, spell crit and hit, attack power, mana per 5 and defense, and healers' weights now count healing over spell damage.
2. **Macro commands.** The Macros tab has *Class macros* and *Commands*. Commands is a reference of 47 less-known macro commands and conditions (targeting, casting, conditions, items and gear, pet, group and raid, utility), each with a working example you can copy into the game's macro window or add in one click. `/codex commands` opens it.
3. **Boss loot in the Journal.** Each boss lists the items it drops, with a drop chance when the list has one and a note when RUIN members have looted it; other drops and anything RUIN looted that isn't listed follow. Loot lists come from data files (`Loot.lua` explains the format; `LootSample.lua` is the template, with the Deadmines from WoW Classic marked *Not checked on Forever*), from a data addon that fills `RUIN_CodexLoot`, or from another addon calling `RUIN_API:GetModule("Codex"):AddLoot(...)`. Hall of Thanes now names its two bosses.
4. Planning a run in the Journal uses the same day list and hour / minute / AM-PM boxes as Muster.

## 0.3.9 — 2026-10-19

1 change since 0.3.8:

1. **One Journal for dungeons and raids.** Sub-tabs are now Gear Path, Best-in-slot, Macros and Journal (Raids merged into Journal). Inside the Journal, *Dungeons* and *Raids* switch the list. *Plan a joint RUIN run* and *Post in Muster* now work for dungeons too: a 5-player Dungeon event needing 1 tank, 1 healer and 3 DPS; raids keep the 10 / 20 / 40 size choice. `/codex raids`, `/codex dungeons` and `/codex <dungeon or raid name>` open the right list.

## 0.3.8 — 2026-10-19

1 change since 0.3.7 (needs RUIN Core 0.3.12):

1. **Tidier pages, in Codex's color.**
   - Journal and Raids: long boss tips no longer run into the next line; each line takes the room it needs.
   - Best-in-slot: everyone sees a clean read-only list. Officers press *Edit list* to get the item boxes, Import and Send to RUIN.
   - Class names read Warrior, Paladin... instead of WARRIOR, and the macro search box has its hint inside it.

## 0.3.7 — 2026-10-19

1 change since 0.3.6:

1. Back to the original name (Codex) in the RUIN window and addon list, after 0.3.6's short-lived rename. Its tab now sits in the order Guild, Finder, Muster, Pathfinder, Codex, Exchange, Options.

## 0.3.6 — 2026-10-19

1 change since 0.3.5:

1. **New display name** (Gear tab, Gear & Dungeons page), to match the RUIN Gaming Companion App brief and RUIN Core 0.3.10's new tab order. The addon list shows it as "Gear (Codex)". The tabs now read in the brief's plain language. Only what players see changed: the addon folder, repository, command and saved-data names stay the same, so nothing needs reinstalling or re-setting.

## 0.3.5 — 2026-10-19

Macros, phase 1.

1. **Macros page:** 113 ready-made macros for every class and spec plus shared ones for all classes (combat, utility, quality of life, leveling, raid, PvP), filtered by class, spec, tag and search. Each one shows its text, a short note and the spells it needs, and your class's spells you don't know yet are flagged.
2. **Add to your macros:** *Add to account* or *Add to character* creates it for you (outside combat; in combat it is queued until you leave it), keeps names unique, and shows how many of your 120 account and 30 character slots are used. Items such as food, drink and potions are filled in from your bags. Macros that say something in chat ask first. On a client without macro creation, *Copy text* gives you the text.
3. Every macro is checked before it can be added: 255 characters at most, no `/run`, `/script`, `/console` or other commands that could harm your game.

## 0.3.4 — 2026-10-18

4 changes since 0.3.0 (needs RUIN Core 0.3.7):

1. Gear Path, the new first page: every known upgrade for your class and spec ranked by progress per minute (gain × confidence × relevance ÷ minutes), with its slot, source, time and a Quick / Medium / Long tag. Solo and Group switches, a priority choice (time efficient, biggest upgrade, quickest), "show only upgrades", how many of your bracket's best-in-slot items you have, and the next upgrade. Confidence and estimated times are shown, never hidden.
2. Officers can note where a best-in-slot item comes from and how long it takes: shift-click the item, then type e.g. "quest 15 Duskwood" before pressing Set. The note travels with the list to RUIN and in exported strings.
3. The Journal says plainly that its level ranges and boss tips are a WoW Classic sample until RUIN records WoW Forever's; drops RUIN members loot stay real.
4. New RUIN look (the Codex tab, part of the RUIN Gaming Companion App), and Retail's interface number in the TOC. /codex path, /codex journal.

## 0.3.0 — 2026-10-18

- Suite release: every RUIN addon moves to 0.3.0 together, bringing everything from the 0.2.x entries below. No further code changes.
- Needs RUIN Core 0.3.0.
- From now on a RUIN addon's 0.3.x number counts its own changes since this release.

## 0.2.6 — 2026-10-18

6 changes since 0.2.0:

Needs RUIN Core 0.2.6 or later.

1. Per-spec stat weights for every class, covering Forever's Haste and Expertise and its single Hit and Crit stats. The spec is detected from your talents, with an override (`/codex spec`). The tooltip names the weights it used.
2. Best-in-slot lists: officers curate one per class, spec and level bracket and send it to RUIN. Tooltips mark best-in-slot items, and lists export and import as strings.
3. Upgrades page: the best known upgrades you can use within 3 levels, from RUIN's loot and best-in-slot lists.
4. Raids page: boss tips and learned loot for each raid, and a planner that posts a joint 10, 20 or 40-player run to RUIN Muster with role needs.
5. Fixed: item names in the journal showed without their colour and link because the link was dropped.
6. The page is split into Journal, Upgrades, Best-in-slot and Raids, and loot rows show the item's tooltip on hover.

## 0.2.0 — 2026-10-18

- Suite milestone: every RUIN addon moves to 0.2.0 together. No code changes since the last 0.1 release.
- With RUIN Core 0.2.0, this module's page opens in the new RUIN window with its own themed header: a tome with pulsing runes.

## 0.1.2 — 2026-10-18

- Fixed: "Binding header RUIN was attempted to be loaded more than once". Each module now has its own section under Key Bindings, and all of its bindings load.
- Fixed: the tooltip said "slot empty" when the item was compared with an empty second slot (an off hand, a second ring or trinket). It now names the slot it compared against.
- With /ruin debug on, tooltips show the scores Codex compared.

## 0.1.0 — 2026-10-18

First proof of concept.
