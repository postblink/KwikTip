# Forever content refresh — 2026-11-09 UTC

## Current result

`0.1.0-alpha.2` release preparation adds five Ruins, four Excavation, seven Dalaran and sixteen Classic encounter
records to the published alpha's 13: **eight entries, 45 encounter tips**.
Normal difficulty 1 only. This is partial, source-backed coverage, not complete
or current-client qualification. No game, installed addon or Retail file was changed.

The worktree starts at `d409c816daa390203fd9bdf884e5b05a6273addd` (latest locally
known origin/master), not the older dirty master checkout. That checkout and its
uncommitted files remain untouched. No commit, push, upload or publication.

## Current online updates and disposition

- Blizzard's [November 6 hotfixes](https://news.blizzard.com/en-us/article/24315281/wow-forever-hotfixes-november-6-2026)
  fix Maraudon's post-boss NPC, disengaging enemies in Blackmaw/Drowned City,
  the Drowned City portal, and the Horde Baron quest item's minimum level (15).
  These are bug/quest fixes, not new combat instructions for our current entries.
- Blizzard's [November 8 post](https://us.forums.blizzard.com/en/wow/t/dungeon-enemy-xp-increased-november-8/2406595)
  confirms a 50% dungeon kill-XP increase. No combat tip or XP calculator changed.
- Existing Method guide pages still show Hall/Stockade October 15 and Ragefire
  October 12. No newly verified official mechanic change justifies rewriting
  those tips. Their existing caveats remain.
- Ruins has current [Method](https://www.method.gg/wow-forever/dungeons/ruins-of-lordaeron)
  (November 6) and [Icy Veins](https://www.icy-veins.com/wow-forever/ruins-of-lordaeron-guide)
  (October 19) mechanics. Candidate wording is short, independently authored,
  and deliberately avoids conflicting specifics.

## Ruins provenance and exclusions

Preserved Wago 70790 Map, DungeonEncounter and MapDifficulty exports were
rehash-checked against their November 4 fetch receipt. Selected rows/hashes are
in `FOREVER_RUINS_IDS_70790.json`. Map 2999; Normal difficulty 1/five players.
Admitted IDs: 3353, 3357, 3411, 3412, 3354. No inferred route, UI map, NPC or
subzone identity. The optional overview is dungeon-wide, not pack detection.

- **3355 excluded:** raw export says The Butcher, while guides and Blizzard's
  hotfix say The Baron. Neither naming resemblance nor route order establishes
  identity. No borrowed Baron mechanic is attached to that event.
- **3408 excluded:** rare Lordaeron Captain is faction-sensitive and outside
  this bounded slice. Its static identity is known; exclusion is not absence.
- **Bjork:** guides disagree on shield versus knockback. Only shared safe
  positioning/preparation advice is admitted, with explicit limitation.
- Witherfang add kill order differs; no priority is asserted.
- Wave counts and questionable exact ability thresholds are omitted.

Installed build manifest currently reports `1.60.1.70862`. Fresh Wago CSV access
was denied by network policy; the web reader could not read the CSV either.
We did not bypass the restriction. Thus 70790 is dated evidence, **not** proof
of 70862 identity stability. Refresh/reconcile those exact tables before claiming
latest-build support. Existing 70707 data and this 70790 slice are labeled mixed.

## Remaining new-dungeon research queue

| Dungeon | Current source finding | Next useful work |
|---|---|---|
| Hall | Existing candidate; guide alias still provisional | Current IDs/runtime and alias check |
| Ruins | Five admitted tips; two explicit exclusions | Reconcile Baron and current-build events |
| Excavation | [Method guide](https://www.method.gg/wow-forever/dungeons/excavation-site-wetlands), dated Oct15, now has four boss sections | Four events now admitted from dated70790 IDs; current70862 remains unverified; no longer 'no strategy found' |
| Dalaran | [Method guide](https://www.method.gg/wow-forever/dungeons/city-of-dalaran), Oct15, exists | Seven exact matches admitted; Enigma mapping and two unmatched DB2 entries excluded |
| Drowned City | [Mobalytics page](https://mobalytics.gg/wow-forever/dungeons/the-drowned-city-guide) still has placeholder mechanics despite a guide title | Need actual encounter evidence; do not ship placeholders |
| Krol'dok, Alcaz, Blackmaw, Shaper's Terrace | Targeted search did not establish complete current Method/Icy mechanics | Retain research-needed, not 'no guides exist' |

The [Icy Veins overview](https://www.icy-veins.com/wow-forever/dungeons-overview)
also warns higher-level guides are added as players discover content. Search
results, loot tables and datamined names alone are not strategy evidence. Classic
coverage remains an incremental task, not silently complete after this refresh.

## Acceptance / release boundary

Run the Python Forever suite, locale/runtime tests, workflow lint and local
release builder. Then inspect the candidate archive and current-build events.
In-game test must include each admitted Ruins event and all four Excavation events
(including optional Highland Horror) and seven Dalaran events (including Lyn),
Dalaran city-map and excluded-ID rejection, skipped/reordered fights,
wipes, instance exit, alternate mode rejection, both excluded events, optional
overview and persisted settings. No replacement of the installed alpha without
an intentional install step; no release without owner authorization.

## Verification result

- 30 Forever Python tests passed (including packaged runtime in enUS/deDE/frFR).
- 54 localization assertions passed.
- 824 standalone runtime assertions passed in each of enUS, deDE and frFR.
- Release/recovery workflow actionlint and git diff whitespace check passed.
- Local release assets generated and checksummed; no installation or publication.
- Independent read-only review found no functional defect. Fixed its candidate
  install-link ambiguity and mixed-build header finding. Native Claude review
  was blocked by network policy, so it did not review or generate this patch.

Additional excavation cross-check: preserved 70790 export has exact records for
Saltspine 3480, Shadetooth 3481, Highland Horror 3644, Relic Guardian 3482 on 2998.
Current Method/Icy guides differ on Shadetooth enrage percentage and Saltspine
Dust Storm wording; do not copy exact thresholds. The four records are now included in alpha.2, normal mode only; Highland Horror
is optional and triggers only on its exact event, never guessed from faction/name.

Excavation follow-on: compact tips cross-checked against both guides above; omitted
disputed Dust Storm effect and exact enrage threshold. Added identity, order-independent
state and alternate-difficulty tests. No installation, publication or commit.

Excavation independent review: no functional blockers; corrected count/table and
manual acceptance documentation. Final 30 Python tests, 54 localization checks,
642 runtime assertions per locale, workflow lint and whitespace checks passed.

## Dalaran follow-on

[Method](https://www.method.gg/wow-forever/dungeons/city-of-dalaran) (Oct15) and
[Icy Veins](https://www.icy-veins.com/wow-forever/city-of-dalaran-guide) (Oct20)
agree on eight guide bosses including optional Lyn. Preserved70790 has nine
records on dungeon2959: seven exact name matches, Mana Elemental3301 and Mana
Wraith3312. Arcanic Enigma has no exact match; no alias inferred. City2980 is
not the dungeon. Seven concise tips admitted, retaining current70862 limitation.
No specific beam direction or detailed projectile trajectory is asserted.
Manual acceptance must test seven events, optional Lyn, both excluded IDs,
city-map rejection and skipped/reordered fights. No full-dungeon acceptance.
First test pass found fixture state leaked alternate difficulty into the common
helper; corrected the helper to initialize Normal explicitly. No engine change.

## Remaining assessment after Dalaran

Four of nine new dungeons now have some implemented advice (Hall, Ruins,
Excavation, Dalaran); five remain unimplemented. Four Classic units have advice,
leaving 22 of the provisional26 Classic units untouched. These are implementation
counts, not complete/client-accepted counts; client-accepted complete remains0.

Additional Nov9 search found newer commercial guide pages, not enough verified
combat evidence to add those dungeons safely:
- [METAMMO Blackmaw](https://metammo.com/wow-forever/dungeons/blackmaw-hold)
  explicitly derives its seven-name roster from70862 datamining, not combat logs.
- [ConquestCapped Blackmaw](https://conquestcapped.com/guides/wow-forever/wow-forever-blackmaw-hold-guide/)
  updated Nov8 provides quest/entry/roster leads requiring mechanics cross-check.
- [Shaper's Terrace](https://mmonster.co/wow-forever/guides/dungeons/shapers-terrace)
  updated Nov7 explicitly leaves tactics pending first runs. No placeholder shipped.
Current70862 raw ID verification remains blocked, not fixed by third-party roster
claims. Next bounded work: verified Classic slices, reliable footage/encounter
mechanics for remaining new dungeons, then actual client acceptance.

Dalaran final gates: 30 Python tests; 54 localization assertions; 824 runtime
assertions per enUS/deDE/frFR; workflow lint and whitespace all pass.

Dalaran independent review: no functional blockers; minor checklist/count/grammar
findings corrected. No commit, installation or publication performed.

## Release authorization

Lucas subsequently requested getting KwikTip updated and uploaded. This authorizes
scoped release commits and existing official alpha distribution. Earlier no-publish
notes describe earlier checkpoints, not the later authorization. No local install
is implied. Scope remains partial and current-build/client acceptance unverified.

Release addition: Deadmines and Wailing Caverns contribute sixteen exact-match
events. Sources and phase/rare caveats: FOREVER_CLASSIC_REFRESH_20261109.md.

Release gate: 30 Python tests, 54 localization checks, 1241 runtime assertions
per locale, workflow lint and whitespace checks pass. Full inventory remains
unfinished; do not label the alpha all-dungeon complete.
