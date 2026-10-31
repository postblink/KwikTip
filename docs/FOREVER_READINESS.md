# World of Warcraft: Forever support — readiness and implementation gates

Status (2026-10-31): isolated alpha candidate **`0.1.0-alpha.1`** contains Hall of Thanes and Ragefire Chasm: eight boss records, optional dungeon-wide preparation, and normal difficulty 1 only. Installed `0.1.0-test` is unchanged. Exact-build static IDs come from Wago's 1.60.1.70707 exports. **No in-game load or dungeon pass is established; no release is approved.** Area/NPC triggers and Hall's Infurnus/Magmatus association remain unverified. Full Classic-plus-nine scope is unchanged. See `FOREVER_ALPHA_COVERAGE.md`, `FOREVER_RAGEFIRE_READINESS.md` and `FOREVER_DISTRIBUTION.md`.

The active install manifest identifies `wowf` version `1.60.1.70707`; the executable is `_forever_/Wow.exe`. The latest inspected graphics log recorded 1.60.1.70634 on October 27. The older `_classic_beta_` install no longer has an executable. Interface `16001` is the intended package target and is corroborated by installed Forever addon TOCs, not a new `GetBuildInfo()` observation. The test instructions are packaged in `Forever/README.txt`.

## Current recommendation

Forever's full-release target is **all Classic dungeon units/wings plus all nine new Forever dungeons**, kept in a separate Forever package and data set.[12][13][14]

The working matrix counts 26 Classic units plus nine new dungeons if Upper Blackrock Spire is included; one Forever chart counts 34 and omits UBRS, while another includes it. Resolve that exact roster count against the client before treating 35 as authoritative.[13][15]

The two-dungeon preview proposal is superseded.

The Week 1 beta cap and availability constrain what can be tested now, not what the full release promises.[1][2]

Use `FOREVER_COVERAGE_MATRIX.md` as the canonical inventory and full-coverage definition; some new-dungeon strategies and all target-client runtime behavior still need work.

The durable decisions are in `DECISIONS.md`: Forever uses the modern client API, stays separate from Midnight/Retail, and its full dungeon scope is all Vanilla-era dungeons/wings plus all nine new dungeons. The exact row count, including UBRS's final classification, remains a target-client verification item. `FOREVER_COVERAGE_MATRIX.md` owns the candidate inventory and completion criteria; this document records evidence and release gates.

## Confirmed launch roster

Blizzard's September 15 forum post is the source of truth for this roster and the corrected ranges: [Krol'dok Stronghold and all nine ranges](https://us.forums.blizzard.com/en/wow/t/krol%E2%80%99dok-stronghold/2349672).[8] Blizzard's [Forever panel recap](https://worldofwarcraft.blizzard.com/en-us/news/24303862) confirms the new original-Azeroth content direction; the official forum post supplies the exact table.

| Dungeon | Official bracket | Current evidence for KwikTip content | Status |
|---|---:|---|---|
| The Hall of Thanes | 13–18 | Exact-build Map/DungeonEncounter exports verify instance and four encounter IDs. Current Method (Oct 15) and Icy Veins (Oct 19) guides inform a local encounter-only test. | Implemented test data; client runtime pending. Infurnus/Magmatus guide match remains provisional; no area/trash coverage claim. |
| Ruins of Lordaeron | 15–20 | A community data page labelled build 1.60.1.70009 lists seven encounters and IDs, but no linked Journal/strategy. Mobalytics covers several mechanics and calls one encounter The Baron; the data page lists The Butcher while its loot data says The Baron. | Partial coverage; reconcile roster/name/mechanics and encounter IDs against the current client before marking complete.[5][6][9] |
| Excavation Site: Wetlands | 24–29 | A build-1.60.1.70009 data page exposes four encounter names/IDs; its page says strategies are coming soon and the dungeon is beyond the current cap. | Candidate for the next data inventory; no reliable tips yet.[10] |
| City of Dalaran | 28–33 | A build-1.60.1.70009 data page exposes nine encounter names/IDs; its page says strategies are coming soon and the dungeon is beyond the current cap. | Candidate for the next data inventory; no reliable tips yet.[11] |
| The Drowned City | 35–40 | A BlizzCon-floor preview reports seeing two bosses, but this is not public-beta play and is not a complete strategy guide. | Research lead only; do not turn demo impressions into shipped tips.[7][8] |
| Krol'dok Stronghold | 40–45 | Bracket confirmed by Blizzard; earlier third-party 40–55 claims are superseded. | Strategy coverage not confirmed. |
| Alcaz Prison | 48–53 | Bracket confirmed by Blizzard. | Strategy coverage not confirmed. |
| Blackmaw Hold | 55–60 | Bracket confirmed by Blizzard. | Strategy coverage not confirmed. |
| Shaper's Terrace | 58–60 | Bracket confirmed by Blizzard. | Strategy coverage not confirmed. |

“Not confirmed” means this audit did not verify a current, dungeon-specific mechanics guide; it does not assert that no beta data or community coverage exists.

## Repository facts and boundaries

- Current retail manifest is `KwikTip.toc`, interface `120100`, version `3.5.0`; it loads `DungeonData.lua` and `DungeonData_Timewalking.lua`.
- The current data/ID puller, `python3 tools/pull_db2_ids.py --json`, reports zero fills for the existing dataset. That is not a Forever ID audit: the tool currently targets the present data files and its matching/version assumptions have not been validated against Forever's client tables.
- The release workflow is tag-triggered (`v*`) and packages/uploads to CurseForge, Wago, WoWInterface, and GitHub. A tag would be an external release; do not use it for the spike.
- The pre-existing `CONTEXT.md` modification and untracked `tests/smoke.lua` were preserved. `DECISIONS.md` was already untracked and is now updated with the owner's settled full-coverage scope; no Midnight runtime/data files or Retail manifest were changed.

## Release gates

1. **Flavor/package:** interface `16001`, standalone `KwikTip_Forever`. Installed `0.1.0-test` is preserved; source candidate is `0.1.0-alpha.1`. Builders never install/publish; the workflow requires a separately approved matching alpha tag. Coverage/version ledger, notes and provenance ship alongside the ZIP. Retail runtime remains unchanged. A candidate is not a supported release.
2. **IDs:** Wago's exact-build `Map` export verifies instance 3065 and `DungeonEncounter` verifies route order **3493, 3495, 3494, 3496**. `AreaTable` verifies area 16919, but this is not a uiMapID or runtime subzone trigger. No Hall `UiMap`/assignment was found; NPC identifiers remain unverified. These fields are omitted instead of guessed or zero-filled. See `FOREVER_HALL_OF_THANES_RESEARCH.md` and `FOREVER_HALL_OF_THANES_IDS_70707.json` for provenance. Exported static data is not direct local extraction or an in-game pass.
3. **Runtime compatibility:** manually test the current `_forever_` client; verify `GetInstanceInfo`, `IsInInstance`, encounter events, protected/secret-value behavior, settings persistence, and clean load with the actual TOC/interface. Confirm event 3495 really corresponds to the guide fight called Magmatus before treating that tip as settled. Subzone/area routing remains future work.
4. **Content:** satisfy every row in `FOREVER_COVERAGE_MATRIX.md`. Reuse Classic strategy only after checking it applies in Forever; finish the new-dungeon strategy audits and resolve named roster/mechanics conflicts. A beta roster, loot table, or general overview is not boss strategy evidence.
5. **Data isolation:** preserve the decided boundary between Forever and Midnight data. Reuse runtime consumers only after proving the runtime data shape is compatible; do not add speculative `type` branches.
6. **Release QA:** build the flavor-specific package, verify its archive has the right TOC/interface/data and no retail-only content leakage, run validators/tests, then obtain explicit release approval before tagging or uploading.

## First implementation slice

The first testable slice is Hall boss-event tips with an optional dungeon-wide overview, not a supported/full-coverage addon. The package includes manual acceptance steps. Default entry stays quiet; Persistent Tip Window opts into the overview keyed only by instance 3065. This does not detect a room, current pack or NPC. No unverified subzone/city-map fallback is shipped. Public sharing/tagging/uploading remains outside this work. Historical beta availability and later-dungeon research are not refreshed claims about current access.

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
