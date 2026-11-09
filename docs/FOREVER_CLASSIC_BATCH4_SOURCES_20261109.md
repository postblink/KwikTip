# Classic batch 4 qualification — 2026-11-09

## Zul'Farrak
- https://www.wowhead.com/forever/guide/zulfarrak-dungeon-overview-location-rewards
- Title: Zul'Farrak Dungeon Strategy Guide - WoW: Forever.
- By Wowhead; updated 2026/11/06; Patch 1.60.1.
- Opening and full boss strategies read. No explicit Classic-fallback/beta warning present in reviewed guide. A Vanilla reference remains; the update label does not prove live testing.
- Avoided precise immunity timing, school list, claimed guaranteed outcomes, and questionable duplicated Velratha ability list. No summoning/quest instructions.

## Maraudon
- https://www.wowhead.com/forever/guide/maraudon-dungeon-overview-location-rewards
- Title: Maraudon Dungeon Strategy Guide - WoW: Forever.
- By Wowhead; updated 2026/11/06; Patch 1.60.1.
- Opening and full boss strategies read. No explicit Classic-fallback/beta warning present in reviewed guide. No claim of observed live behavior.
- Omitted exact timings, route/level recommendations, absolute ranged-attack suppression and ambiguous geographic descriptions.

## Identity and limitations
CONFIRMED: make.py rehashes the three preserved raw70790 tables against their original manifest and asserts all 16 exact map/name/encounter matches and normal-mode eligibility. Both maps also expose alternate difficulty rows, which this batch deliberately does not enable. Lua parse and isolated data-shape checks pass.
UNCERTAIN: current70862 exports and actual ENCOUNTER_START behavior are not validated. This is a source-backed normal-mode candidate, not live-qualified full dungeon coverage. No NPC/name fallback, room route or next-boss inference.
Excluded unmatched encounters are recorded explicitly in coverage_entries.json; generated evidence retains original URLs, retrieval time, raw checksums and selected rows. No shared repo edits, install, commits or publishing.
