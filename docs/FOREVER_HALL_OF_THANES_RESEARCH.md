# Forever pilot: The Hall of Thanes

## Current evidence and implementation — 2026-10-31

Status: **exact-build static IDs verified from Wago exports; encounter-only local test implemented; in-game behavior untested.** This supersedes the candidate-ID/build status in the preserved historical research below. It does not establish a direct extraction from the local client or an in-game pass.

The active install manifest identifies `wowf` `1.60.1.70707`, using `_forever_/Wow.exe`. Wago's explicitly versioned exports verify:

| Route order | DungeonEncounter ID | Raw client record name | OrderIndex |
|---:|---:|---|---:|
| 1 | 3493 | Faldrim Anvilmar | 0 |
| 2 | 3495 | Infurnus | 2000 |
| 3 | 3494 | Plunder | 2500 |
| 4 | 3496 | Durgen Dirgehammer | 3000 |

`Map.ID = 3065` is The Hall of Thanes (`InstanceType = 1`); `AreaTable.ID = 16919` links to continent/map 3065. The latter is not a uiMapID. The retrieved `UiMap` and `UiMapAssignment` tables contain no Hall map/area assignment. JournalEncounter/JournalEncounterCreature exports returned HTTP 400 for this build. No guessed NPC ID, subzone string, coordinate or city-map fallback is shipped.

Exact URLs, response hashes and relevant rows are recorded in `FOREVER_HALL_OF_THANES_IDS_70707.json`. Sources: [Map](https://wago.tools/db2/Map/csv?build=1.60.1.70707), [DungeonEncounter](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70707), [AreaTable](https://wago.tools/db2/AreaTable/csv?build=1.60.1.70707), [UiMap](https://wago.tools/db2/UiMap/csv?build=1.60.1.70707), [UiMapAssignment](https://wago.tools/db2/UiMapAssignment/csv?build=1.60.1.70707).

The current strategy references are [Method/Jurdi, October 15](https://www.method.gg/wow-forever/dungeons/hall-of-thanes) and [Icy Veins/Neryssa, October 19](https://www.icy-veins.com/wow-forever/hall-of-thanes-guide). Tips summarize patrol-space preparation, the interrupt, add management, knockback positioning, and final-room hazards. They are source-backed test wording, not observed mechanics in this installation. Method and Icy Veins disagree on Durgen's boss-versus-add kill priority, so no such priority is included.

**Unresolved alias:** both guides call the second fight Magmatus, while DB2 calls encounter 3495 Infurnus. Matching those by position is an inference, not verified NPC/event equivalence. The second HUD tip explicitly says its guide match is provisional; the runtime uses the event's localized display name. Confirm the event/name/mechanics in the actual client before considering that association settled.

The isolated package uses `Forever/RuntimeIndexes.lua` and `Forever/Flavor.lua`, not Timewalking data. `Forever/README.txt` contains manual acceptance steps. All dungeon coverage gates in `FOREVER_COVERAGE_MATRIX.md` still apply.

### Candidate readiness follow-up

`0.1.0-test.2` adds an opt-in **dungeon-wide** overview through the existing
Persistent Tip Window setting, keyed only by verified instance 3065. Method's
Important Trash section supports the preparation advice. It is not a current
pack, room, NPC or subzone detector; default entry remains quiet. Boss/explicit
demo previews take priority. Unsupported modes and unknown-encounter replacement
clear stale state in the Forever guard. The installed `0.1.0-test` is unchanged.

Further exact-build `Spell`/`SpellName` data identifies spell 1293228 as Combust
and names Magmatus in its description. This corroborates that guide name in
client-authored spell text, but provides no direct link to encounter 3495.
The alias remains provisional. No usable local creature-cache record or raw
Criteria linkage resolved it. Durgen's kill priority remains excluded because
sources disagree. These findings do not justify a new NPC/area trigger.

## Historical draft — retained for provenance

The following September/October beta research was preliminary. Candidate status and the old 70205 build statements below are superseded by the dated evidence above; its source text is not a current-client validation claim.

Primary source: [The Hall of Thanes Dungeon Overview Guide](https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards).

This is an editorial extraction for a future isolated Forever data file. IDs below are candidates supported by online Forever build data, not yet verified from the installed client. No Forever API behavior has been tested. Keep the short HUD lines below as candidate wording; verify against the actual client and revise if beta changes.

## Candidate identifiers

| Identifier | Candidate value | Evidence and limit |
|---|---:|---|
| Map ID | 3065 | [WoW Forever map page](https://wow-forever.gg/dungeons/the-hall-of-thanes) lists map 3065; [WoW Forever Guides](https://wowforeverguides.com/dungeons/hall-of-thanes) reports the map and encounter range for build 1.60.1.70205. The guide explicitly classifies the client-data claim as reported/datamined, not confirmed. |
| Area/zone ID | 16919 | [Wowhead Forever zone page](https://www.wowhead.com/forever/zone=16919/the-hall-of-thanes) and [WoW Forever zone page](https://wow-forever.gg/db/zones/16919-the-hall-of-thanes/) identify the zone as 16919. The latter labels its data build 1.60.1.70338. |
| Encounter IDs | 3493–3496, in client order: Faldrim Anvilmar; encounter-internal name Infurnus / reported in-game display Magmatus; Plunder; Durgen Dirgehammer | [WoW Forever Guides](https://wowforeverguides.com/dungeons/hall-of-thanes) reports `DungeonEncounter 3493 to 3496` on map 3065 for build 1.60.1.70205, but labels the claim reported/datamined, not confirmed. [Forever Codex corrections](https://forever-codex.com/corrections) says 3495 is the encounter's internal name Infurnus, while the boss's spell and loot say Magmatus; preserve this display-name mismatch rather than treating the names as interchangeable proof. |

The build-specific report for [1.60.1.70205](https://wow-forever.gg/news/2026-10-03-build-1-60-1-70205-report) states zero maps or zones changed versus 1.60.1.70170. The third-party guide above reports the map/encounter IDs for 70205 directly, but labels that report unconfirmed. These sources make the IDs stronger candidates; neither substitutes for checking the actual local client tables or in-game runtime behavior. Do not put them in release data until a direct-client cross-check is possible.

## Boss candidates

| Order | Candidate name | HUD tip draft | Evidence / caveat |
|---:|---|---|---|
| 1 | Faldrim Anvilmar | Clear nearby trash and wait for his patrol to reach the cleared side before pulling. Tank: expect Mind Blast and Curse of Anvilmar. | Guide describes a central patrol, Mind Blast, and a 10-minute tank curse. NPC reference ID shown by Wowhead: 261306; must cross-check against this Forever build's client data. |
| 2 | Magmatus (encounter record candidate: Infurnus) | Pull Magmatus away from the party; focus the Dark Iron Summoner first, then return to the boss. Watch for Fire Nova-style group damage and Combust on a random player. | Guide names the add and strategy; calls the AoE “Fire Nova-like” without identifying an ability name. NPC reference ID: 261316; verify in client. Encounter-name/display-name discrepancy is documented above. |
| 3 | Plunder | Fight in a safe part of the hallway; position against a wall so Knock Away does not send anyone into another pack. | Guide reports a single knockback ability, Knock Away. NPC reference ID: 261311; verify in client. |
| 4 | Durgen Dirgehammer | Before engaging, clear the Dark Iron Looters around the room. Control the two Lesser Stone Golems one at a time; use stuns/fears and focus them rather than splitting damage. Watch for the boss's Fear and Rend. | The article body and quest reference use **Durgen**, and the linked NPC is 261319; two guide headings/loot-table labels spell the name **Dirgen**. Treat Durgen as provisional until the Forever client confirms canonical display text. |

## Trash candidates

- **Dark Iron Looter:** rapid dagger auto-attacks; avoid large pulls and prioritize killing it to reduce tank damage. Wowhead NPC reference 263396.
- **Dark Iron Engineer:** targeted bombs are avoidable once the target location is chosen. Wowhead NPC reference 263397.
- **Dark Iron Summoner:** Fireballs plus summons a Fiery Assistant. Line-of-sight around a pillar/wall to interrupt its cast sequence or force it to move. Wowhead NPC reference 263438.
- **Lesser Stone Golem:** high damage and increased movement speed; pull singly when possible, otherwise focus-fire. In the final mixed pack, crowd-control one threat, then kill the Golem before the Looter. Wowhead NPC reference 263466.

NPC references above are research pointers from Wowhead, not confirmed Forever DB2/runtime identifiers. The guide's recommendations are written for low-level leveling groups; keep the content aimed at useful, brief leveling guidance rather than importing Midnight M+ conventions.

## Data needed before coding this into the addon

1. Verify map 3065, area 16919, relevant uiMapIDs, and encounter IDs 3493/3495/3494/3496 against the installed Forever client build.
2. Verify the four boss names and NPC IDs against client tables or direct beta observations. Resolve the Durgen/Dirgen discrepancy from the client, not by choosing whichever spelling looks likelier.
3. Check if boss encounter events are usable in this client and whether target/NPC identity is secret-protected. Do not design trash-by-target detection until tested.
4. Observe the dungeon's subzone strings and map transitions in-game if the HUD is to change by area.
5. Add this content only to a separate Forever data path/package after the selection/loading mechanism is proven; keep ID placeholders out of any candidate release archive.
