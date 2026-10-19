# RUIN Codex changelog

Versioning: the third number counts the meaningful changes made since the second number last went up.

## Unreleased

(nothing yet)

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
