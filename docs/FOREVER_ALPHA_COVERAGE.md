# Forever 0.1.0-alpha.1 candidate coverage

Prepared for review and build-only CI. No publishing tag or release is approved
by this document. Installed `0.1.0-test` is unchanged; this candidate is separate.

| Included alpha entry | Static identity | Tips/overview | Mode | Actual client test |
|---|---|---|---|---|
| Hall of Thanes | 3065; 3493/3495/3494/3496 | Four boss records and opt-in dungeon overview; Infurnus/Magmatus association provisional | Normal 1 only | Pending November 4 |
| Ragefire Chasm | 389; 2732/2733/2734/2735 | Four boss records and opt-in dungeon overview; no assumed next-boss route | Normal 1 only | Pending November 4 |
| Stormwind Stockade | 34; 2756/2757/2758/2759/2760 | Five regular boss records and opt-in overview; rare Bruegal automatic tips excluded; no wing-order assumption | Normal 1 only | Pending November 4 |

This means **three implemented alpha entries, 13 encounter records, zero
complete/client-tested dungeons**. No NPC/subzone/current-pull routing or raid
coverage is included. Tips are English; UI locale fallback is exercised offline.
The release's `coverage.json` and bundled `source-evidence.json` state the same
scope and provenance. Exported IDs and mocked events do not establish an in-game pass.

The full target remains all Classic dungeon units/wings plus nine new Forever
dungeons. In the provisional 26+9 matrix, 24 other Classic candidates and eight
other new dungeons remain unimplemented; UBRS classification may reduce the final
inventory by one. The first alpha must not be described as full support.

Before a publishing decision, inspect this candidate's PR/checks and artifact,
confirm build/version/coverage notes, and choose whether a clearly untested
launch alpha is acceptable or to wait for the first November 4 client smoke.
Merge and publishing-tag decisions are separate; no tag is created automatically.

First live loop: record GetBuildInfo and actual difficulty, clean login/HUD/settings,
one fight in either included dungeon, success/wipe/exit cleanup, and persistence.
Then exercise the remaining encounter records and explicitly confirm the Hall
alias; Bruegal remains excluded unless his identity is verified. Disable the
addon on an error; preserve the old ZIP and SavedVariables.
For hotfixes, capture exact build/instance/event/error, reproduce offline where
possible, rerun the gates, and issue a distinct reviewed alpha version.
