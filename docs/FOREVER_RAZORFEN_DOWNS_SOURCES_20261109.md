# Razorfen Downs provisional slice

Reviewed 2026-11-09. Six exact 70790 encounter matches on map129, normal1 only. Every tip visibly says `Provisional advice`. No install, shared repository edits, or client acceptance.

## Sources

- https://mobalytics.gg/wow-forever/profile/ruse_cruize/dungeons/razorfen-downs-dungeon-guide-bosses-loot-and-quests — Ruse_Cruize, updated Nov4 2026. Read substantive boss-strategy sections for all six. Primary strategy source.
- https://www.wowhead.com/forever/guide/razorfen-downs-dungeon-overview-location-rewards — Nodge, updated Oct30 2026, patch1.60.1. Still explicitly warns of beta/incomplete/Classic-derived material. Corroborates broad strategy; not a claim of tested launch behavior.
- https://www.warcrafttavern.com/forever/guides/razorfen-downs — search surfaced a Forever overview but full read returned403. Not used as strategy evidence.

100 original tip words total across six encounters, within each retrieved source's200-word budget. No copied guide prose. Mobalytics supports wave threat, poison removal, skeleton control, interrupting heals, mind control, cloud avoidance, tank damage, summoned adds and shared focus choice. Wowhead corroborates the main mechanics but does not independently verify them in-game. Plaguemaw deliberately has only basic tank/heal advice. No promise of particular cleanse mechanics, strict positioning, timers, wave counts or pre-boss event detection. Amnennar focus choice follows Mobalytics rather than imposing Wowhead's more specific positioning prescription.

## IDs and boundaries

`FOREVER_RAZORFEN_DOWNS_IDS_70790.json` preserves selected map129 rows and original retrieval hashes/URLs from `/tmp/kwiktip-build-drift-70790/evidence.json`. Rehashed every export before use. Map name checked; normal1 MapDifficulty exists; all six named encounters2780–2785 have DifficultyID0. Alternate MapDifficulty201 excluded from runtime. Lady Falther'ess has no matched normal event; no guessed alias.

Installed70862 is newer: this is dated70790 evidence, not current-build ID qualification. Published advice corroboration is not independent client verification. No route, gong or escort-stage detection, and `previewNextBoss=false` prevents asserting DB2 order as route.

## Checks

- `python /tmp/make_rfd.py` passed hash, map, mode and exact-name assertions.
- Wrapped snippet in `return { ... }` and `luac5.1 -p -` passed.
- Shared runtime suite and release integration remain parent's responsibility.

Files: `razorfen_downs.lua`, `coverage_entries.json`, `FOREVER_RAZORFEN_DOWNS_IDS_70790.json`, this ledger.
