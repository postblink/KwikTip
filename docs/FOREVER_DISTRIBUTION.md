# Forever distribution through GitHub Actions

Status (2026-10-31): implemented for review with offline validation. Review-branch
and GitHub build results are recorded in the PR/checks; no publishing tag is
approved. No addon release has been published. The installed local addon
remains the separately verified `0.1.0-test`; source candidate `0.1.0-test.2`
is not installed. No client load or in-game test is established before November 4.

## Existing Retail flow

Repository origin is `github.com/postblink/KwikTip`. `.github/workflows/release.yml`
listens for `v*` tags, checks out the repository, then invokes pinned
BigWigsMods/packager. Root `.pkgmeta` supplies Retail package name `KwikTip`,
CurseForge `1478824`, Wago `QN53W7KB`, WoWInterface `27074`, and CurseForge
localization `1478824`. The upload step references `GITHUB_TOKEN`, `CF_API_KEY`,
`WAGO_API_TOKEN`, and `WOWI_API_TOKEN`. These are referenced secret names, not a
verification that each is configured or authorized; no values were read.

Retail's workflow, IDs, localization and runtime are unchanged. Root `.pkgmeta`
now narrowly excludes Forever source/docs/tools/tests so committing the new
flavor will not put it into a Retail archive.

## Forever flow

`.github/workflows/forever-release.yml` runs the real package/runtime tests,
distribution gates and existing Retail localization checks. PR and manual runs
create reviewable workflow artifacts only. A `forever-v*` tag runs the same
build, then the publication job only if the tag passes strict validation:

- Only `forever-vX.Y.Z-alpha.N` is accepted for publishing; it must equal the
  Forever TOC version. Stable, beta, Retail, mismatched and local-test tags fail.
- The packaged README must identify the same version as the Forever TOC.
- The builder uses only the explicit Forever package file list, not root pkgmeta,
  Retail data or Retail tip overlays. It produces the standalone ZIP, SHA256SUMS,
  source evidence, authored release notes and BigWigs-compatible `release.json`.
- The release metadata maps interface `16001` to flavor `forever`, not `wowf`
  (the latter is the local Blizzard product identifier).
- Build jobs have read permission. Only the publication job has contents write,
  and only its final release step receives the built-in `GITHUB_TOKEN`.
- GitHub CLI verifies the tag already exists and creates an explicit prerelease,
  with `--latest=false`. Existing releases/assets are not silently overwritten.
- The separately scoped marketplace step reuses existing CurseForge/Wago pages
  with alpha-only Forever metadata. It uploads the same verified ZIP bytes;
  provider preflight must find exact patch `1.60.1`, with no flavor/patch fallback.

This preserves the tested package layout while matching the Retail packager's
GitHub release-asset metadata contract. The existing BigWigs pin itself supports
Forever (`-g forever`, alias `camelot`, or version `1.60.1`); isolation is the
reason for the separate builder, not a lack of packager support. Actual addon
manager acceptance and GitHub-hosted execution remain untested.

## Destinations and missing configuration

GitHub prereleases and the existing CurseForge/Wago pages are implemented behind
the same approved alpha-tag trigger. GitHub uses the built-in token; the two
marketplaces reference the existing `CF_API_KEY` and `WAGO_API_TOKEN` secret
names. No credential values were read and no new grant or setting was created.

New CurseForge or Wago pages are not required. Their per-file game metadata can
route Forever separately on the existing addon page. Existing BigWigs pages demonstrate
Forever alongside other game versions on [CurseForge](https://www.curseforge.com/wow/addons/bigwigs)
and [Wago](https://addons.wago.io/addons/bigwigs/versions?stability=stable).
`tools/forever_marketplaces.py` retains CurseForge `1478824` and Wago `QN53W7KB`.
Its multipart payloads follow the exact pinned packager implementation: CF
`releaseType=alpha` plus a patch ID resolved only from Forever game version type
`88568`; Wago `stability=alpha` plus `supported_forever_patches=["1.60.1"]`.
All checksums/tag/flavor/patch validations and both token-presence checks complete
before the first upload. No credentials are given to PR/manual builds.

Actual project token permissions and provider acceptance remain untested until
an approved publication. WoWInterface Forever is disabled pending provider
support; no `WOWI_API_TOKEN` is used in this workflow. The standalone folder stays
`KwikTip_Forever`; no speculative rename was made. Addon-manager acceptance still
needs testing. No marketplace project, token, permission or paid service was created.

Uploads across providers are not atomic. The uploader does not retry POSTs and
reports each completed provider. If a later step fails, inspect the existing
files before rerunning; do not blindly duplicate a successful upload.

## Review and first alpha

Local commands, using a new output path:

```sh
python3 -B -m unittest discover -s tests -p 'test_forever*.py' -v
lua5.1 tests/test_localization.lua
actionlint .github/workflows/forever-release.yml
python3 -B tools/forever_release.py /tmp/kwiktip-forever-review-build
```

The focused review branch includes the workflow, Forever source, builder,
release helper, tests, notes and required provenance docs, preserving unrelated
working-tree edits. Run a PR/manual workflow build and inspect its
artifact before a publishing tag. Workflow dispatch is available once the
workflow is on the repository's default branch.

For a proposed first public `0.1.0-alpha.1`, review actual coverage/client status,
set the Forever TOC and README version together, update the authored notes, and
rerun the gates. Current `0.1.0-test.2` intentionally cannot pass a public alpha
tag check. Obtain approval before pushing `forever-v0.1.0-alpha.1`: that tag is
the concrete publication trigger. Do not use `v0.1.0-alpha.1`, which belongs to
the Retail workflow's tag space. No tag or push was performed here.

That publishing tag will upload to the existing CF/Wago pages and create the
GitHub prerelease. A review-branch push and draft PR run build checks only.

Alpha notes must say Hall encounter tips plus optional dungeon overview only;
no per-pull/NPC/subzone detection and no full Classic-plus-nine coverage. The
Infurnus/Magmatus guide association remains provisional. In-game results stay
pending until actually observed; offline tests are not a client pass.

## Official implementation references

- [Pinned BigWigs implementation](https://github.com/BigWigsMods/packager/blob/e50a250f8705041e40f2fa1ddcb280a686d65aa0/release.sh), flavor table and `release.json` construction.
- [GitHub release creation options](https://cli.github.com/manual/gh_release_create).
- [CurseForge upload API](https://support.curseforge.com/support/solutions/articles/9000197321) and [Forever client selection](https://blog.curseforge.com/wow-forever-migrate-addons-beta-to-live/).
- [Wago game data](https://addons.wago.io/api/data/game), exact supported Forever patches.
- [Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), tag triggers and permissions.
- [Upload artifact v7.0.2](https://github.com/actions/upload-artifact/releases/tag/v7.0.2) and [download artifact v8.0.2](https://github.com/actions/download-artifact/releases/tag/v8.0.2), pinned in the workflow.
