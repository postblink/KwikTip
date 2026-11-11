KwikTip Forever 0.1.0-alpha.5 -- partial encounter alpha

KwikTip now supports WoW Forever alongside Retail (Midnight). This standalone
Forever package brings encounter tips and the familiar HUD/settings to Forever.

Downloads:
GitHub alpha: https://github.com/postblink/KwikTip/releases/tag/forever-v0.1.0-alpha.5
CurseForge alphas: https://www.curseforge.com/wow/addons/kwiktip/files
Wago alphas: https://addons.wago.io/addons/kwiktip/versions?stability=alpha

CurseForge and Wago use the existing KwikTip pages; select the Forever game
flavor and alpha versions. WoWInterface currently distributes Retail only.
Retail uses the separate KwikTip folder; this package uses KwikTip_Forever.

Candidate scope: 183 encounter tips in 23 runtime instance entries. Included:
Hall, Ragefire, Stockade, Ruins, Excavation, Dalaran, Deadmines, Wailing Caverns,
Shadowfang Keep, Blackfathom Deeps, Gnomeregan, Razorfen Kraul, Uldaman,
Blackrock Depths, Scholomance, ZulFarrak, Maraudon, Scarlet Monastery,
Dire Maul, Stratholme, Sunken Temple, Razorfen Downs and The Drowned City. Individual encounter exclusions remain.
Shared Scarlet, Dire Maul and Stratholme entries do not infer wings or routes.
Cathedral and Razorfen Downs tips are explicitly provisional. Normal difficulty 1 only.

Full dungeon coverage remains in progress: 24 Classic units/wings and five new
dungeons have some advice, not complete coverage. Both Blackrock Spire wings plus four new dungeons remain outside this candidate.
The roadmap includes all Classic dungeon units/wings plus nine new dungeons.
This candidate has not been tested in-game. Do not describe it as complete,
fully current-build verified, or automatically installed.

Target: Forever product wowf, interface 16001. Hall/Ragefire/Stockade use 70707; all added entries
except Drowned City use preserved 70790 exports. Drowned City uses exact 70888
Map, MapDifficulty and encounter rows. Other latest-build drift checks remain pending.
The current install is World of Warcraft/_forever_/Wow.exe; the older
_classic_beta_/WowB.exe path in historical notes is no longer the target.

Installation:
1. Download KwikTip_Forever-0.1.0-alpha.5.zip from the release or select the
   same Forever alpha version on the marketplace pages above.
2. Close the game and extract its KwikTip_Forever folder into:
   World of Warcraft/_forever_/Interface/AddOns/KwikTip_Forever
3. Enable KwikTip: Forever (Alpha) in that client. Keep Retail KwikTip disabled
   there, and retain a backup of the previous addon folder when updating.

The repository's Forever directory is source material; install the packaged ZIP
so the required shared runtime and assets are included. Disabling/removing this
addon does not erase SavedVariables. Disable it if you encounter Lua errors.

Expected behavior:
- /kwik opens settings; the minimap icon and settings logo should appear.
- /kwik move and /kwik preview test the HUD without entering a dungeon.
- Outside supported content, ordinary tips remain hidden.
- In Hall of Thanes, ENCOUNTER_START locks the relevant boss tip. With Persistent
  Tip Window enabled, a successful kill may preview the next ordered encounter.
  The expected IDs in route order are 3493, 3495, 3494, 3496 on instance 3065.
- Enable the existing Persistent Tip Window setting for an optional dungeon-wide
  preparation/trash overview in each included dungeon. It is not a current-pull detector. Boss and
  explicit demo previews take priority; the default remains quiet between fights.
- Ragefire uses instance 389 and encounters 2732/2733/2734/2735. It does not guess
  the next boss after a kill; it returns to the overview or quiet state. Skipped
  or reordered bosses are identified only by their actual encounter event.
- Stockade uses instance 34 and encounters 2756/2757/2758/2759/2760. Its wing
  order is not assumed. Bruegal Ironknuckle is present in current guides, but
  has no verified encounter mapping and does not get an automatic/name-based tip.
- Ruins uses instance 2999 and events 3353/3357/3411/3412/3354.
  Baron/Butcher 3355 and rare Captain 3408 are deliberately excluded.
  No next-boss route is assumed; Bjork ability advice remains conservative.
- Excavation uses instance 2998 and events 3480/3481/3644/3482. Highland Horror
  is optional; encounter order is not inferred. Disputed exact enrage thresholds
  and Dust Storm effect descriptions are omitted.
- City of Dalaran uses dungeon instance 2959, never city map 2980. Seven exact
  matches are included. Arcanic Enigma, Mana Elemental and Mana Wraith remain
  excluded for unresolved identity/strategy; no name-based substitution. Optional Lyn triggers only on its event.
- Drowned City uses instance 2970 and events 3474/3475/3476/3511/3479. The five
  exact source-name matches trigger only on their encounter events. Deathless
  Marrow/Guardians, Umbra, Gill and Zin'aka remain excluded; no inferred aliases.
- Alternate difficulties 201/214 and other unsupported modes do not activate these tips.
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
3. For every included entry in coverage.json, use /kwik debug and observe each
   event, displayed name and tip, success/wipe handling, and zone exits. The
   candidate has 183 events across 23 entries, including five in Drowned City 2970.
   Check provisional strategy associations and skipped/reordered bosses; only
   Hall permits its existing next-boss preview. Do not assume rare coverage.
4. Confirm no tip leaks into another dungeon or after leaving the instance.
   Check the opt-in overview and its personal note; disable Persistent Tip Window
   and confirm ordinary entry is quiet again. Record actual difficulty IDs;
   this alpha targets normal difficulty 1 and does not claim alternate-mode support.
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
https://www.method.gg/wow-forever/dungeons/ragefire-chasm
https://www.icy-veins.com/wow-forever/ragefire-chasm-guide
https://www.method.gg/wow-forever/dungeons/the-stockade
https://www.icy-veins.com/wow-forever/the-stockade-guide

The release assets include coverage.json and source-evidence.json for the exact
candidate scope and static-data provenance. These are not client test results.

Refresh checked 2026-11-09: Method Ruins (Nov6), Icy Veins Ruins (Oct19);
see source-evidence.json. Local installation is a separate user action.

Excavation strategy checked Nov9: Method (Oct15), Icy Veins (Oct18 header/Oct19 changelog).
https://www.method.gg/wow-forever/dungeons/excavation-site-wetlands
https://www.icy-veins.com/wow-forever/excavation-site-wetlands-guide

Dalaran strategy checked Nov9: Method Oct15 / Icy Veins Oct20.
https://www.method.gg/wow-forever/dungeons/city-of-dalaran
https://www.icy-veins.com/wow-forever/city-of-dalaran-guide

Deadmines and Wailing Caverns use preserved 70790 IDs; their current-build checks
and in-game acceptance are pending too. Sneed has one matched event; shredder
phase timing is unverified. Mutanus advice is not an escort-stage detector.
Deviate Faerie Dragon has no automatic tip. See source-evidence.json.

Alpha.3 adds Shadowfang (8), Blackfathom (6), Gnomeregan (5), Razorfen Kraul (6) and Uldaman (8).
Total 78 encounters/13 entries. See coverage.json for exact IDs and exclusions.
Known Geilhast 2914 versus guide Gelihast remains an unresolved alias and is excluded.
Alternate difficulty 198/201 records must not substitute for Normal events.
Rare/quest/escort timing remains unverified; no name-based fallback is provided.
Current-build IDs and client acceptance still unverified.

Historical alpha.4 added 100 events for a total 178/22. The alpha.5
package adds five Drowned City events for 183/23. Source strategy checked Nov 11:
https://www.wowhead.com/forever/guide/the-drowned-city-dungeon-overview-location-rewards
Drowned City's current-build row evidence is in source-evidence.json. Full tables
have unrelated unreadable sections; no missing-row or complete-roster claim.
New tips use English fallback where a translated authored tip is not available.
