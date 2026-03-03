# KwikTip

## Project Overview
WoW addon inspired by **QE Dungeon Tips** (by QEdev — no longer maintained). KwikTip displays contextual information about mobs and bosses based on the player's current position inside a dungeon or raid instance, automatically surfacing relevant tips as the group moves through each area.

## Core Concept
- Detects the current instance and the player's position within it
- Displays a small HUD overlay with tips/info relevant to the specific area (pull, mini-boss, boss room, etc.)
- The HUD is hidden outside of supported instances unless the player enables "Move" mode to reposition it
- Inspired by the QE Dungeon Tips design: unobtrusive, area-aware, zero required interaction mid-pull

## Target Game Version
- **WoW: Midnight** retail — interface `120001`

## Data Sources
**Wowhead is the primary source for all game data.** Always look there first. Only fall back to other sources (Icy Veins, Warcraftpedia, Method, etc.) if the specific data cannot be found on Wowhead.

Reasons:
- Wowhead's database is pulled directly from the game client and is consistently accurate and up-to-date
- Boss names and encounter data on Wowhead can be trusted without secondary verification

**uiMapID values must be verified in-game.** External sources are unreliable for `C_Map.GetBestMapForUnit("player")` values:
- Wowhead zone IDs (`/zone=XXXXX`) are **not** the same as uiMapIDs — they use a different ID space
- LittleWigs/BigWigs use instanceMapIDs (from `GetInstanceInfo()`), which also differ from uiMapIDs
- wow.tools shut down in May 2025
- wago.tools maps are JS-rendered and not programmatically queryable

The only reliable method is running this command while standing inside the dungeon:
```
/run print(C_Map.GetBestMapForUnit("player"))
```

## File Structure
| File | Purpose |
|---|---|
| `KwikTip.toc` | Addon manifest — interface version, file load order, saved variables |
| `KwikTip.lua` | Main entry point — event handling, lifecycle hooks (`OnLoad`, `OnLogin`), slash commands, `DEFAULTS` table |
| `Frames.lua` | HUD frame — backdrop, drag support, `UpdateVisibility`, `ToggleMoveMode`, `SetContent` |
| `DungeonData.lua` | Static data — dungeon names, boss lists, tips keyed by `uiMapID` |
| `Config.lua` | Config window + minimap button — sliders, checkboxes, `ToggleConfig`, `InitMinimapButton` |

## Key Conventions
- **Namespace**: every file opens with `local ADDON_NAME, KwikTip = ...`
- **Saved variables**: `KwikTipDB`, initialised from `KwikTip.DEFAULTS` on first load (missing keys are back-filled, never overwritten)
- **Public API**: methods on the `KwikTip` table (e.g. `KwikTip:UpdateVisibility()`)
- **Private helpers**: `local function` at file scope; prefixed with `_` when attached to the namespace (e.g. `KwikTip:_PlaceMinimapBtn()`)
- **HUD mouse passthrough**: `hud:EnableMouse(false)` by default; only enabled during move mode so it never blocks game interaction
- **Sliders**: custom template-free implementation (no `OptionsSliderTemplate` dependency)
- **Instance detection**: `IsInInstance()` for show/hide; `C_Map.GetBestMapForUnit("player")` for dungeon identification

## Instance / Area Detection
Detect which dungeon the player is in:
```lua
local uiMapID = C_Map.GetBestMapForUnit("player")
local dungeon = KwikTip.DUNGEON_BY_UIMAPID[uiMapID]
```
Get the player's position within an instance for area-specific tips (future):
```lua
local uiMapID = C_Map.GetBestMapForUnit("player")
local pos = C_Map.GetPlayerMapPosition(uiMapID, "player")
-- pos.x, pos.y  (0.0–1.0 normalised coordinates)
```

## Dungeon Coverage (Midnight Season 1)
See `DungeonData.lua` for the full data table.

**New Midnight dungeons (level-up, 81–88):** Windrunner Spire, Murder Row, Den of Nalorakk, Maisara Caverns

**New Midnight dungeons (max level):** Magisters' Terrace (reworked), Nexus-Point Xenas, The Blinding Vale, Voidscar Arena

**Legacy M+ dungeons (uiMapIDs deferred):** Algeth'ar Academy, Pit of Saron, Seat of the Triumvirate, Skyreach

## Slash Commands
| Command | Action |
|---|---|
| `/kwiktip` or `/kwik` | Open/close settings window |
| `/kwik move` | Toggle move mode on the HUD |
| `/kwik debug` | Print current instance detection state to chat |

## TODO / Known Gaps
- Legacy dungeon `uiMapID`s are set to `0` — original zone IDs may have changed when re-tuned for Midnight; verify in-game with `/run print(C_Map.GetBestMapForUnit("player"))`
- `tip` fields in `DungeonData.lua` are empty — content pass needed for all bosses and key trash pulls
- Area-based tip switching (swap HUD content as the group moves through dungeon zones) not yet implemented
