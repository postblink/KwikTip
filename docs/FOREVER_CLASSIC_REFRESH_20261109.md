# Bounded Classic slice, reviewed 2026-11-09

Historical worker handoff below; both slices were subsequently integrated and
passed the parent release gates.

CONFIRMED: sixteen exact name/ID matches in preserved, SHA-256-reverified70790
Map/DungeonEncounter/MapDifficulty tables. Deadmines36 has eight admitted records,
including rare Miner Johnson3676. Wailing Caverns43 has eight; rare Deviate Faerie
Dragon has no matched record and is excluded. Difficulty1 only, no route inference.
No current70862 qualification or in-game pass. No shared repository files edited.

Sources read live:
- https://www.icy-veins.com/wow-forever/deadmines-guide
  Header Oct18; changelog Oct19. Eight bosses with strategy.
- https://www.icy-veins.com/wow-forever/wailing-caverns-guide
  Oct19. Nine described including unmatched rare.
- https://www.method.gg/wow-forever/dungeons/wailing-caverns
  Oct20; cross-check resolves Icy's duplicated Serpentis heading above Pythas prose.
- Method /deadmines endpoint inaccessible; not treated as confirmation.

UNCERTAIN: Sneed2742 is the only matched entry for the shredder/Sneed sequence;
no separate shredder event invented. Observe actual event timing before claiming
that the advice appears during both phases. Wailing escort may not emit an event
until Mutanus appears: tip is encounter advice, not an escort-stage detector.
No NPC/subzone/coordinates, exact health thresholds, or rare-name fallback added.

Integration: append both Lua entries inside DUNGEONS, append coverage_entries.json,
copy evidence docs, extend order-independent tests, counts, packaging and docs.
Run existing full gates. Add negative test for unmatched Faerie Dragon using a
synthetic ID rather than guessing one. Include alternate201 for both,213 for36.

Standalone verification: raw SHA-256 and each encounter ID/name asserted by
make script; Lua syntax parse passed. Shared runtime tests remain parent's step.
No commit, installation or publication performed by this worker.
