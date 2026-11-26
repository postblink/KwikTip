KwikTip Forever 0.1.0-alpha.7 -- Dungeon refresh alpha

THE RIGHT TIP, RIGHT WHEN IT MATTERS.

KwikTip is a compact dungeon HUD for World of Warcraft: Forever. It keeps
encounter reminders close at hand and lets you preview a boss before the pull.
This is a separate edition from Retail and installs as KwikTip_Forever.

GET STARTED

- Type /kwik to open settings, or use the minimap button.
- Turn on Persistent Tip Window for dungeon-wide preparation and trash advice.
- Choose a boss in settings or type /kwik boss in a supported dungeon to list
  available boss tips. Use /kwik boss <number or name> to preview one.
- A matching boss encounter takes over the HUD. Combat clears a manual preview;
  after the fight, the overview returns if you enabled it, otherwise the HUD
  stays quiet. /kwik boss clear dismisses a manual preview.
- Use /kwik move to position and resize the HUD, and /kwik preview to preview
  role-note formatting. Settings include appearance, personal notes and a
  selectable chat channel for the HUD's send button.

COVERAGE

This alpha provides partial Normal-mode dungeon coverage across 28 runtime
maps. Shared-map wings are labeled in the preparation advice; the addon does
not automatically detect the current wing, room or trash pack. Alternate
modes and some optional encounters are not covered. Bossman Toof has bridge
preparation but no automatic boss tip; Demon Fall Canyon and Karazhan Crypts
have client data rows but their live availability is unconfirmed.

Registered map, Normal-mode and encounter IDs were checked against readable
Forever 1.60.1.71037 client data and a local hotfix snapshot. Those checks do
not qualify newer build 1.60.1.71139. The alpha has passed offline load and
routing tests, but in-client display, persistence and encounter behavior have
not been fully verified. The picker and newer tips use English where a
translation is unavailable.

INSTALLATION

Extract the KwikTip_Forever folder into:
World of Warcraft/_forever_/Interface/AddOns/KwikTip_Forever

Enable KwikTip: Forever (Alpha) in the Forever client. The addon is enabled by
default for new installations, but existing character settings can be kept.
After updating Lua files while logged in, /reload normally loads the update.
Do not install the repository's Forever/ source folder by itself; the packaged
ZIP includes the shared files it needs.

COMMANDS

/kwik                       Open settings
/kwik move                  Move and resize the HUD
/kwik preview               Preview role-note formatting
/kwik boss                  List available bosses in a supported dungeon
/kwik boss <number or name> Preview a boss tip
/kwik boss clear            Dismiss the manual boss preview
/kwik help                  List available commands

DOWNLOADS AND FEEDBACK

GitHub: https://github.com/postblink/KwikTip/releases
Wago: https://addons.wago.io/addons/kwiktip/versions?stability=alpha
CurseForge: https://www.curseforge.com/wow/addons/kwiktip/files
Report a missing or incorrect tip: https://github.com/postblink/KwikTip/issues

Include your edition, dungeon, boss and what happened in a report. Do not post
full SavedVariables files; they can contain personal notes and unrelated logs.
The repository includes a detailed coverage ledger and build evidence.
