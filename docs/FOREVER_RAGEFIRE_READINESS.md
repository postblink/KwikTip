# Ragefire Chasm — normal-mode alpha entry

Status (2026-10-31): exact-build static identity and source-backed tips implemented
for `0.1.0-alpha.1`. No client load, encounter-event or gameplay pass is claimed.
The current installed product metadata remains `wowf 1.60.1.70707`.

The refreshed Wago exports verify Map **389**, party instance, with four
DungeonEncounter records: **2732 Oggleflint**, **2733 Taragaman the Hungerer**,
**2734 Jergosh the Invoker**, **2735 Bazzalan**. Area 2437 links to Map 389;
this is not a runtime subzone trigger. No Ragefire UiMap/assignment was found.
Unknown NPC/map/subzone routing is omitted instead of guessed.

MapDifficulty includes normal **1 / five players** and alternate **201 / ten
players**. This alpha explicitly targets normal difficulty 1 only. Alternate
availability/mechanics are unverified. The same exact-build table confirms
Hall normal 1 and alternate 201; its alpha is also restricted to normal 1.

Provenance: `FOREVER_RAGEFIRE_IDS_70707.json` records URLs, hashes and selected
rows for six exact-build raw tables, plus fetched guide-response provenance.
These are hosted exports, not extraction from the installed client. Raw sources:
[Map](https://wago.tools/db2/Map/csv?build=1.60.1.70707),
[DungeonEncounter](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70707),
[MapDifficulty](https://wago.tools/db2/MapDifficulty/csv?build=1.60.1.70707).

Current Forever guides by [Method/Jurdi, October 12](https://www.method.gg/wow-forever/dungeons/ragefire-chasm)
and [Icy Veins/Neryssa, October 19](https://www.icy-veins.com/wow-forever/ragefire-chasm-guide)
support the four concise boss tips and optional instance-wide preparation text.
No legacy Retail data is imported. Jergosh's kill priority is omitted because
the guides differ; the other included advice has no identified material conflict.

The roster's OrderIndex is not proof of a compulsory live route. Players can
skip Oggleflint's detour or choose final-room order. All four encounters remain
included, but `previewNextBoss=false` returns to the overview/quiet state after
a kill instead of guessing which boss comes next. No extra optional encounter
was identified in the raw table or either guide.

November 4 acceptance: normal-mode actual instance/difficulty/event IDs; each
boss's localized name/tip; skipped/reordered fights; wipe/kill transitions;
overview opt-in/quiet default; wrong-instance/mode rejection; exit cleanup and
settings persistence. Alternate modes and per-room/NPC triggers remain excluded.
