# Classic batch2, checked 2026-11-09

CONFIRMED: 19 exact name/ID matches with DungeonEncounter difficulty0/1, plus
normal1 MapDifficulty rows. Full preserved70790 tables rehashed against original
manifest. No claim to current70862 verification or live client acceptance.

Sources read live (Forever-specific Icy Veins strategy, not Classic inferred):
- https://www.icy-veins.com/wow-forever/shadowfang-keep-guide
  Oct19 changelog. Eight mapped events; rare Captain and horses unmapped.
- https://www.icy-veins.com/wow-forever/blackfathom-deeps-guide
  Oct19 changelog. Six exact-name records admitted. Guide Gelihast differs from
  normal export Geilhast2914; excluded rather than assumed alias. Baron Aquanis
  has only difficulty198 export evidence here, not normal advice.
- https://www.icy-veins.com/wow-forever/gnomeregan-guide
  Oct21 changelog. Five normal-compatible events; rare Ambassador unmapped.

Important identity pitfall: Blackfathom and Gnomeregan exports include multiple
same-name records for difficulty198/201. Do NOT substitute those IDs for normal1.
BFD admitted2916,2915,2913,2912,2911,2910; excludes2914 and all198/201 records.
Gnomeregan admitted2768–2772; excludes same-name198 IDs and Mechanical Menagerie.
SFK admitted2748–2755, no guessed rare/horse event.

UNCERTAIN: actual event timing and encounter availability still need client tests.
Fenrus tip avoids claiming the guide's exact summon timing. Grubbis tip does not
pretend to detect pre-boss escort waves. No exact thresholds, NPCs, subzones,
coordinates or automatic name matching. Optional overview is generic preparation.

Verification performed: raw hashes, exact admitted names, normal-compatible row
selection, Lua syntax parse. Parent must run shared runtime/package regressions.
Add explicit negative tests for alternate198/201 IDs and modes, BFD2914, rare
names; no fallback. No shared edits, commits, installation or publishing.
