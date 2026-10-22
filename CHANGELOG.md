# RUIN Codex changelog

Versioning: the third number counts the meaningful changes made since the second number last went up.

## Unreleased

(nothing yet)

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
