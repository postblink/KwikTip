# Scarlet Monastery source assessment — 2026-11-09

CONFIRMED: seven exact name/ID records on map189, all DungeonEncounter mode0;
MapDifficulty1 normal present. SHA256 matches original70790 preserved exports.
Current70862 unchanged status: not reverified. One combined map entry, no duplicate
instance records and no wing inference, name fallback or automatic next boss.

Current Forever sources read live:
- https://www.icy-veins.com/wow-forever/scarlet-monastery-graveyard-guide
  Oct21 changelog. Vishas444 and Thalnos2779 admitted; three rares unmapped.
- https://www.icy-veins.com/wow-forever/scarlet-monastery-library-guide
  Oct21 changelog/headerOct18 mismatch. Loksey446 and Doan447 admitted.
- https://www.wowhead.com/forever/guide/scarlet-monastery-armory-dungeon-overview-location-rewards
  UpdatedNov6, patch1.60.1. Herod448 admitted. No loot or level claims imported.
- https://www.wowhead.com/forever/guide/scarlet-monastery-cathedral-dungeon-overview-location-rewards
  UpdatedOct22. STILL carries beta notice: unavailable content can be Classic
  fallback. Thus do not treat the Forever URL alone as live strategy validation.
- https://mobalytics.gg/wow-forever/dungeons/scarlet-monastery-cathedral-guide
  UpdatedNov4. Actual mechanics text for Whitemane/Fairbanks corroborates core
  advice, but quest sections remain placeholders. Compact Cathedral tips visibly
  marked provisional pending client/mechanics verification.
Icy Armory/Cathedral endpoints unavailable; WarcraftTavern Cathedral403.

UNCERTAIN: Whitemane450 is the sole final-pair event; no standalone Mograine ID
invented. Advice may appear only when actual450 fires; no promise of earlier phase
coverage. Rares Azshir, Fallen Champion, Ironspine do not have matching export rows.
Four roster wings are represented by one runtime instance, NOT four tested entries.

Integration tests: seven event identities, normal1, reject201/207, actual-event
selection regardless of traversal, quiet between fights, no wing inference and
no rare or Mograine-name fallback. Keep Cathedral provisional marker in package.
Raw hashes, identity checks and Lua parse passed; shared runtime tests left to parent.
No shared files, commit, install or publish changed.
