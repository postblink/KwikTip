KwikTip Forever 0.1.0-test.20261122 -- Unreleased dungeon refresh

KwikTip is a quiet dungeon HUD for World of Warcraft: Forever. This test
build is separate from Retail and uses the KwikTip_Forever addon folder.

Using the HUD
- /kwik opens settings. Enable Persistent Tip Window for dungeon preparation
  and trash priorities between fights, or turn it off for a quiet HUD.
- Before a pull, choose a boss in the Forever settings picker or use /kwik boss
  inside a supported dungeon. The preview is manual, not a predicted route.
- In a supported fight, the encounter event displays that fight's tip. Combat
  clears a pre-pull preview. After an encounter, the HUD returns to preparation
  or stays quiet, according to your settings.
- /kwik move and /kwik preview let you configure the HUD outside a dungeon.

Scope and limitations
- Normal mode only. Instance, mode and registered encounter IDs were checked
  against readable Forever 1.60.1.71037 client data and a local hotfix snapshot.
- Shared wings are not detected automatically. Where applicable, preparation
  labels wing-specific advice. No room, current-pack, or hostile NPC detector.
- Some optional fights and unresolved event-to-fight mappings are not covered.
  Bossman Toof has bridge preparation but no automatic boss tip. Demon Fall
  Canyon and Karazhan Crypts have client rows but unconfirmed live availability.
- The new build has passed simulated addon loads and routing tests. In-client
  display, persistence and event lifecycle still need acceptance. New authored
  tips and the picker use English where a translation is not available.

The test build is disabled by default for new installations and is not a public
release. For an existing installation, the client can preserve addon enablement.
See Forever/Coverage.json and docs/FOREVER_CURRENT_IDS_71037.json in source for
exact coverage, exclusions, and the limits of the static data.

Published Forever builds: https://github.com/postblink/KwikTip/releases
CurseForge: https://www.curseforge.com/wow/addons/kwiktip/files
Wago: https://addons.wago.io/addons/kwiktip/versions?stability=alpha
