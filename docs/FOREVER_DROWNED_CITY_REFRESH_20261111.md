# Drowned City refresh, November 11, 2026

The alpha.5 package adds five Normal-mode encounter tips and
an opt-in dungeon overview. It contains 183 encounter records in 23 runtime entries.
No local addon installation or in-game acceptance is implied. Publication status
is recorded by the matching GitHub prerelease and its workflow run.

## Strategy

[Wowhead's guide](https://www.wowhead.com/forever/guide/the-drowned-city-dungeon-overview-location-rewards)
was updated November 10. Primeval Elemental now has a strategy section; earlier
November 9 research marked it TBD. The admitted advice covers that optional fight,
Zul'Alai, Var'Taka, Captain Dreadrise and Min'loth. All advice is paraphrased.

[Blizzard's November 9 hotfix section](https://news.blizzard.com/en-us/article/24315281/wow-forever-hotfixes-november-9-2026)
corrects excessive dungeon damage and lowers Deathless Marrow encounter values.
The indexed official section was readable; direct extraction returned a newer
title without body text, so no exhaustive newer-hotfix review is claimed.
Advice avoids numeric damage, exact thresholds and route assumptions.

## Exact-build identity evidence

The installed wowf client is 1.60.1.70888. The initial hotfix-only check verified
Min'loth 3479 / map 2970 but lacked the map classification and difficulty rows.
A strict keyless reader could not export the full tables. A subsequent strict
reader with the public Blizzard-distributed TACT key snapshot also encountered
unreleased keys. Neither failure proves the target rows are unavailable.

The final read-only inspection uses pinned Wowsims/TACTSharp source semantics
and already-installed GNU Nettle 4.0. No new software, network fallback, game
writes or Wago access was required. Released public keys decode the relevant
Map and DungeonEncounter section; MapDifficulty is in a plaintext section.
Unrelated encrypted sections remain unreadable and are explicitly accounted for.

[The verified row evidence](FOREVER_DROWNED_CITY_IDS_70888.json) records:

- Map 2970, The Drowned City, InstanceType 1 and AreaTableID 16550.
- MapDifficulty 5935: map 2970, Normal difficulty 1, MaxPlayers 5.
- The five admitted event IDs 3474/3475/3476/3511/3479, each with an exact guide-name match.
- Alternate difficulty 201 exists but is deliberately disabled.
- Full 1.60.1.70888 schema and layout-hash matches, artifact hashes and source sections.
- Every missing byte range equals a whole skipped section. None overlaps an admitted row's section.
- Compressed chunk MD5, exact decompressed lengths and zlib trailer checks pass.
- The current hotfix cache's Min'loth row agrees with the base fields; no target Map or MapDifficulty overlay exists in that cache.

These are positive row verifications, not complete raw-table exports. Missing
rows cannot be treated as proof an encounter does not exist. The unchanged build
manifest hash and bounded extraction run are recorded in the research artifacts.
The final inspection completed in under one second at approximately 345 MiB peak RSS.

## Exclusions and behavior

Deathless Guardians 3478 is verified, but no proven alias to the guide's Deathless
Marrow exists. That event stays excluded. Umbra, Gill and Zin'aka lack reconciled
positive event/strategy mappings and receive no guessed name or NPC fallback.

The five admitted events activate only inside party instance 2970 on difficulty 1.
The default HUD stays quiet between encounters; its existing persistent setting
shows the optional overview. A kill or wipe does not predict the next boss.
Unknown encounters preserve only the user's overview choice. Authored tips fall
back to English in locales without a translated overlay.

[ALL THE THINGS](https://github.com/ATTWoWAddon/AllTheThings/blob/9bb7f2a929550016947d31b5948b464e48592147/.contrib/.db/forever/dungeons%20%26%20raids/the%20drowned%20city.lua)
independently corroborates the map and six event identities, originally sourced
from 70840. It is a cross-check, not the basis for 70888 qualification.

## Acceptance gate

Automated tests cover identity/name mapping, positive triggers, success and wipe
cleanup, exclusions, other instances, unsupported modes, quiet default behavior,
optional overview, package isolation and evidence inclusion. The source/admission
ledger is [the candidate JSON](FOREVER_DROWNED_CITY_CANDIDATE_20261111.json).

Target-client loading and real encounter acceptance remain untested. Complete,
client-accepted dungeons remain zero. The other 22 runtime entries still carry
70707/70790 evidence and need their own current-build drift check. Four new
dungeons and Blackrock Spire remain outside this runtime candidate.

Final verification: 36 Python tests, 54 localization checks and 7,315 offline
runtime assertions in each of enUS, deDE and frFR passed. Release asset
preparation, actionlint and whitespace checks passed. Independent review found
no blocking runtime or evidence defects. These checks do not replace the
target-client acceptance gate.

Release preparation uses the existing Forever-only alpha workflow and destinations.
The draft PR build must pass before merge and the matching immutable alpha tag.
Retail tags, workflow, package metadata and game installation stay unchanged.
