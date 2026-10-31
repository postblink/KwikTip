# KwikTip Forever — full dungeon coverage matrix

Status (2026-10-31): **Hall has isolated encounter tips and a candidate opt-in dungeon-wide preparation/trash overview; zero dungeons meet complete coverage below.** Static IDs are verified from Wago exports; client runtime, actual area/NPC triggers, and Infurnus/Magmatus identity remain pending. Candidate `0.1.0-test.2` is not installed; installed `0.1.0-test` stays unchanged. No supported release or release approval. Full scope is preserved; later-dungeon research dates remain historical.

## Release scope

The Forever-specific KwikTip release is intended to cover **all Vanilla-era dungeon content units/wings plus all nine new Forever dungeons**. The working inventory has 26 Classic units and nine new dungeons (35 total) if Upper Blackrock Spire is included; however, Forever community rosters disagree, with one counting 34 and omitting UBRS while another includes it. Keep UBRS in the candidate matrix and resolve the final inventory against the exact Forever client before calling the count authoritative.[12][13][15]

The owner reports that the returning dungeons so far play like Classic/Vanilla. Use existing Vanilla encounter strategy as a **reuse candidate**, not as proof that every Forever encounter and trigger is unchanged. Forever-specific instance/map/encounter identifiers, modes, and any mechanic differences still need to be checked against the Forever client. New loot is a separate itemization concern: KwikTip currently provides contextual encounter/trash advice, not loot tables or item recommendations, so this coverage goal does not add a loot database.

Raids are not silently included in this dungeon scope. Upper Blackrock Spire is included because it is part of the Classic dungeon roster; verify its Forever party/instance mode rather than dropping it based on its historical group size. Any other raid coverage is a separate decision.

## Repository baseline

- `DungeonData.lua` is the Midnight dataset. Its six `season = "legacy"` entries are Algeth'ar Academy, Pit of Saron, Seat of the Triumvirate, Skyreach, Kings' Rest, and Temple of Sethraliss—not Vanilla dungeons.
- `DungeonData_Timewalking.lua` has 33 entries, beginning with the Burning Crusade pool and continuing through Legion. It has no Vanilla/Classic pool. Some of its boss tips are still empty; it is not a source of complete Forever coverage.
- `Forever/DungeonData.lua` contains one Hall test entry with four encounters and an optional instance-wide overview. No Classic/Vanilla units are implemented. **Complete, client-tested coverage remains 0/26 Classic units and 0/9 new dungeons**; one new dungeon is in implementation, not complete.
- Forever data, indexes, guards and tip overlays are separate from Retail. The current install manifest identifies `wowf` build `1.60.1.70707` at `_forever_/Wow.exe`; interface `16001` is the package target, corroborated by installed addon TOCs. No target-client load is established.

## Classic dungeon inventory — 26 units

Classic boss/route/trash guides exist as a research baseline for the old instances; Forever-specific identifiers and any changes remain unverified. Wowhead's Classic overview is the primary starting index for the Vanilla-era roster and strategy pages.[12]

| # | Forever coverage unit | Current KwikTip data | Forever validation |
|---:|---|---|---|
| 1 | Ragefire Chasm | Missing | Pending |
| 2 | Wailing Caverns | Missing | Pending |
| 3 | The Deadmines | Missing | Pending |
| 4 | Shadowfang Keep | Missing | Pending |
| 5 | Blackfathom Deeps | Missing | Pending |
| 6 | The Stockade | Missing | Pending |
| 7 | Gnomeregan | Missing | Pending |
| 8 | Razorfen Kraul | Missing | Pending |
| 9 | Scarlet Monastery — Graveyard | Missing | Pending |
| 10 | Scarlet Monastery — Library | Missing | Pending |
| 11 | Scarlet Monastery — Armory | Missing | Pending |
| 12 | Scarlet Monastery — Cathedral | Missing | Pending |
| 13 | Razorfen Downs | Missing | Pending |
| 14 | Uldaman | Missing | Pending |
| 15 | Zul'Farrak | Missing | Pending |
| 16 | Maraudon | Missing | Pending |
| 17 | Temple of Atal'Hakkar (Sunken Temple) | Missing | Pending |
| 18 | Blackrock Depths | Missing | Pending |
| 19 | Lower Blackrock Spire | Missing | Pending |
| 20 | Upper Blackrock Spire | Missing | Pending; verify Forever mode/party size |
| 21 | Dire Maul — East | Missing | Pending |
| 22 | Dire Maul — West | Missing | Pending |
| 23 | Dire Maul — North | Missing | Pending |
| 24 | Scholomance | Missing | Pending |
| 25 | Stratholme — Living | Missing | Pending |
| 26 | Stratholme — Undead | Missing | Pending |

## New Forever dungeons — 9 units

The nine names below are confirmed by Blizzard; the published launch brackets are recorded in the readiness document.[8][14]

Current beta availability is not the same as full-release scope: the Week 1 announcement names Hall of Thanes and Ruins of Lordaeron, and the September 24 notes do not announce a phase expansion.[1][2]

| # | Dungeon | Bracket | Evidence / status |
|---:|---|---:|---|
| 27 | The Hall of Thanes | 13–18 | Four boss records and candidate opt-in instance-wide overview. Wago 70707 verifies instance 3065 and order 3493/3495/3494/3496. Client runtime, Infurnus/Magmatus equivalence, and per-area/NPC routing pending. |
| 28 | Ruins of Lordaeron | 15–20 | Partial strategy coverage; reconcile the seven-entry roster, alias/name conflicts, mechanics, and IDs before marking complete.[5][6][9] |
| 29 | Excavation Site: Wetlands | 24–29 | Build-labelled encounter roster found; strategy coverage was not established by the checked page.[10] |
| 30 | City of Dalaran | 28–33 | Build-labelled encounter roster found; strategy coverage was not established by the checked page.[11] |
| 31 | The Drowned City | 35–40 | Demo/report material is not a complete beta-played strategy source.[7] |
| 32 | Krol'dok Stronghold | 40–45 | Official bracket known; encounter mechanics/strategy inventory still required.[8] |
| 33 | Alcaz Prison | 48–53 | Official bracket known; encounter mechanics/strategy inventory still required.[8] |
| 34 | Blackmaw Hold | 55–60 | Official bracket known; encounter mechanics/strategy inventory still required.[8] |
| 35 | Shaper's Terrace | 58–60 | Official bracket known; encounter mechanics/strategy inventory still required.[8] |

## Definition of complete coverage

A dungeon counts as covered only when its Forever package has:

1. A verified instance identity and map/area routing for the Forever client; wings or sides that run independently are distinct units.
2. A verified encounter roster and ID for every boss/encounter that KwikTip intends to surface. Any optional, summoned, or alternate encounters are explicitly handled or explicitly excluded.
3. A short, actionable tip for each covered boss, based on Classic guides for unchanged mechanics or current Forever beta play/guides for new or changed mechanics.
4. The important route/area triggers and notable high-risk trash advice supported by the relevant source; no unverified NPC names or guessed IDs.
5. A passing target-client test that the package loads and the right tip appears in the right instance/encounter without false positives.

“Full” does not mean reproducing every enemy's loot table or documenting every ordinary trash NPC. New loot is not part of KwikTip's current data model. If loot recommendations are desired, add that as a distinct product/data requirement rather than hiding it inside dungeon-tip coverage.

## Work order and gates

1. **Resolve the inventory.** Confirm the target client's instance modes and independently runnable wings. Keep UBRS in the candidate set until its Forever dungeon/raid classification and party mode settle the 34-vs-35 count.
2. **Build the Classic baseline.** For each of the 26 units, map existing Vanilla guide encounters and notable mechanics to Forever's current IDs. Reuse text only after checking that it remains correct for Forever; record confirmed invariants and differences.
3. **Complete the nine new dungeons.** Maintain separate states for roster/ID-known, strategy-sourced, drafted, and client-tested. Do not promote an encounter list or loot table to mechanics evidence.
4. **Implement the isolated Forever flavor** only after confirming the current TOC/API contract and a small load/detection spike. Do not alter the Retail manifest, version, or release workflow as part of Forever work.
5. **Release gate:** all rows in the final client-confirmed inventory meet the definition above (including UBRS if Forever classifies it as a dungeon); the complete data set passes validation, the package contains no Retail-only identifiers/metadata, and the target Forever client smoke test passes. A two-dungeon preview is not a substitute for this full-support promise.

## Sources

[1] https://news.blizzard.com/en-us/article/24304160/the-world-of-warcraft-forever-beta-now-live
[2] https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-september-24/2360696
[3] https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards
[4] https://www.wowhead.com/forever/news/the-hall-of-thanes-new-dungeon-walkthrough-for-wow-forever-382991
[5] https://mobalytics.gg/wow-forever/dungeons/ruins-of-lordaeron-dungeon-guide
[6] https://wowforevertalents.com/dungeons/ruins-of-lordaeron
[7] https://www.warcrafttavern.com/forever/news/the-drowned-city-dungeon-preview-in-wow-forever
[8] https://us.forums.blizzard.com/en/wow/t/krol%E2%80%99dok-stronghold/2349672 — Krol’dok Stronghold — official nine-dungeon level brackets
[9] https://wow-forever.gg/dungeons/ruins-of-lordaeron
[10] https://wow-forever.gg/dungeons/excavation-site-wetlands
[11] https://wow-forever.gg/dungeons/city-of-dalaran
[12] https://www.wowhead.com/classic/guide/classic-dungeons-overview — Wowhead Classic Dungeons Overview
[13] https://www.warcrafttavern.com/forever/guides/dungeons — Warcraft Tavern WoW Forever Dungeons
[14] https://worldofwarcraft.blizzard.com/en-us/news/24303862 — Blizzard World of Warcraft Forever What’s Next Panel Recap
[15] https://wowforeverbuilds.com/dungeons — WoW Forever Dungeons: Level Ranges for Every Dungeon
