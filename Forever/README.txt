KwikTip Forever 0.1.0-test.2 -- local engineering candidate

This is the first Hall of Thanes encounter test, not a full-coverage release.
The full project scope remains all Classic dungeon units/wings plus the nine
new Forever dungeons. No target-client test has passed yet.

Target: Forever product wowf, build 1.60.1.70707, interface 16001.
The current install is World of Warcraft/_forever_/Wow.exe; the older
_classic_beta_/WowB.exe path in historical notes is no longer the target.

No automatic installation is performed by the builder. For a controlled manual
test, close the game, copy only the KwikTip_Forever folder into the Forever
client's Interface/AddOns directory, and enable it. Do not enable the Retail
KwikTip addon in the same client. Removing this folder reverses the install;
it does not erase SavedVariables. No public upload or release is approved.

Expected behavior:
- /kwik opens settings; the minimap icon and settings logo should appear.
- /kwik move and /kwik preview test the HUD without entering a dungeon.
- Outside supported content, ordinary tips remain hidden.
- In Hall of Thanes, ENCOUNTER_START locks the relevant boss tip. With Persistent
  Tip Window enabled, a successful kill may preview the next ordered encounter.
  The expected IDs in route order are 3493, 3495, 3494, 3496 on instance 3065.
- Enable the existing Persistent Tip Window setting for an optional dungeon-wide
  preparation/trash overview in Hall. It is not a current-pull detector. Boss and
  explicit demo previews take priority; the default remains quiet between fights.
- Area/trash triggers, NPC targeting, and pre-pull room routing are not implemented.
  There is no guessed city-map fallback. A quiet HUD before a boss is expected.

Important test caveat: raw DungeonEncounter calls the second boss Infurnus;
guides call the second fight Magmatus. That association is provisional. Its
tip is visibly labelled provisional until the actual event/name/mechanics
are checked. The HUD uses the localized encounter name from the event.
Durgen add-versus-boss kill order is omitted because current guides disagree.

In-game acceptance:
1. Record /run print(GetBuildInfo()) and confirm clean login with no Lua errors.
2. Check settings, icon/logo, move mode, preview, mouse passthrough when locked.
3. In Hall, use /kwik debug and confirm instance 3065. Observe all four boss
   events, displayed names and tips, success/wipe handling, and zone exits.
   Check the provisional second-boss association before relying on that tip.
4. Confirm no Hall tip appears in another dungeon or after leaving the instance.
   Check the opt-in overview and its personal note; disable Persistent Tip Window
   and confirm ordinary Hall entry is quiet again.
5. Change a setting, /reload, then log out/in and confirm it persists. Memory-only
   automated preference checks do not establish client persistence.
6. Report the tested build, locale, encounter IDs/names, and any Lua error.
   /kwik debug stores a snapshot; existing encounter logging records event IDs.
   Do not post an entire account/SavedVariables folder or credentials.

Sources (checked 2026-10-31):
https://wago.tools/db2/Map/csv?build=1.60.1.70707
https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70707
https://www.method.gg/wow-forever/dungeons/hall-of-thanes
https://www.icy-veins.com/wow-forever/hall-of-thanes-guide
