# Local DB2 extraction qualification (2026-11-09)

Status: source inspection only. **Not ready to run stock TACTTool as offline.**
No installation, extraction, game-data download, game interruption or blocked
Wago-route retry was performed. This document does not authorize a new run.

## Confirmed inputs

Installed `.build.info` reports active product `wowf`, version `1.60.1.70862`.
Install root: `/home/postblink/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft`.
No suitable current raw exports were found in scoped searches. The ordinary
KwikTip CSV cache is dated September 9 and cannot establish this build.

Upstream source inspected:
- https://github.com/wowdev/TACTSharp/tree/79f58445bc81d0d13f84540f1d1d52e94188cc08
  `TACTTool/Program.cs`, `TACTSharp/Settings.cs`, `Build.cs`, `CDN.cs`.
- https://github.com/wowdev/WoWDBDefs/tree/fb58b5b8ea8ce82945194cc9c4e760fd12ddd85c
  `manifest.json` supplies these DB2 FileDataIDs (not encounter IDs):
  Map **1349477**, DungeonEncounter **1347279**, MapDifficulty **1367868**.
- https://github.com/Marlamin/DBC2CSV : upstream README documents conversion,
  WoWDBDefs definitions and optional same-build hotfix input. Not executed.

## Flags and blockers

Confirmed TACTTool flags: `-b/--buildconfig`, `-c/--cdnconfig`, `-p/--product`,
`-d/--basedir`, `-l/--locale`, `-m/--mode`, `-i/--inputvalue`, `-o/--output`.
A future extraction would explicitly select wowf, enUS, pinned local config files
and `fdid` mode. These flags alone are **not** an offline command:

- `--basedir` is a local cache preference. Settings.TryCDN defaults true and has
  no CLI off switch.
- CLI requests ProductConfig from Ribbit when absent, even with build/CDN
  configs supplied; there is no productconfig CLI flag.
- Library Settings exposes TryCDN and ListfileFallback. A reviewed fail-closed
  wrapper is needed rather than inventing unsupported CLI flags. Verify *all*
  network paths, not just CDN file fallback, before claiming offline behavior.
- Build.Load may generate group indexes and decode full encoding/root/install
  manifests. Three small output tables do not imply small I/O or memory cost.
- Current TACTTool targets net10.0. Available private runtime is only
  `/home/postblink/.dotnet/dotnet`, Microsoft.NETCore.App 9.0.18; no dotnet on PATH.
  Current DBC2CSV README likewise requires .NET10. A compatible vetted binary
  or runtime remains necessary; none installed for this task.

## Safe next gate

Prepare isolated tooling with explicit local configs and no network fallback;
validate missing-data failure on synthetic fixtures. Preserve game directory as
read-only, write outputs/cache elsewhere, pin/check build before and after, and
record raw SHA256s plus decoder/definition versions. Use a quiet guarded window,
not a running-game experiment. Bound resource use and stop on contention or
missing local data. Reconcile matching-build hotfix records separately before
calling output effective runtime data. Unsupported encryption/schema is a blocker,
not a reason to fetch, guess or silently omit rows.
