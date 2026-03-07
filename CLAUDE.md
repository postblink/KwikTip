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

Two concerns are handled separately: **game data** (IDs, names) and **tip content** (strategy, priorities).

### Game Data — IDs, ability names, mob names
1. **Wowhead** — primary. Database is pulled directly from the game client; NPC IDs, encounter IDs, and ability names can be trusted without secondary verification.
2. **warcraft.wiki.gg** — secondary. Most mechanically precise; exact ability numbers, durations, and damage values sourced from game data. Use to cross-check specific ability details when writing tips.

### Tip Content — what to write in `tip` fields
**M+ dungeons** (Magisters' Terrace, Windrunner Spire, Maisara Caverns, Nexus-Point Xenas + legacy four):
1. **method.gg** — primary. M+-focused, practical, high-end perspective. Best source for positioning cues, pull priorities, and mechanic callouts.
2. **Icy Veins** — secondary. Structured tank/healer/DPS notes; useful for completeness and cross-verification.

**Non-M+ dungeons** (Murder Row, Den of Nalorakk, The Blinding Vale, Voidscar Arena):
1. **Icy Veins** — primary. method.gg does not cover non-M+ dungeons.
2. **Wowhead** — secondary.

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
| `Init.lua` | Main entry point — event handling for initial addon load (`OnLoad`, `OnLogin`) and lazy evaluation initialization triggers |
| `DungeonData.lua` | Static data — dungeon names, boss lists, tips keyed by `uiMapID` |
| `Core.lua` | Engine handlers — tracking active environment, event polling, and general utilities |
| `Frames.lua` | HUD frame — backdrop, drag support, wrapped in lazy `InitHUD()` |
| `UI_Config.lua` | Config window + minimap button — loaded lazily via `CreateConfigWindow()` only when requested |

## Key Conventions
- **Namespace**: every file opens with `local ADDON_NAME, KwikTip = ...`
- **Saved variables**: `KwikTipDB`, initialised from `KwikTip.DEFAULTS` on first load (missing keys are back-filled, never overwritten)
- **Public API**: methods on the `KwikTip` table (e.g. `KwikTip:UpdateVisibility()`)
- **Private helpers**: `local function` at file scope; prefixed with `_` when attached to the namespace (e.g. `KwikTip:_PlaceMinimapBtn()`)
- **HUD mouse passthrough**: `hud:EnableMouse(false)` by default; only enabled during move mode so it never blocks game interaction
- **Sliders**: custom template-free implementation (no `OptionsSliderTemplate` dependency)
- **Instance detection**: `IsInInstance()` for show/hide; `C_Map.GetBestMapForUnit("player")` for dungeon identification

## Instance / Area Detection
Primary lookup uses `GetInstanceInfo()` (8th return = instanceID); fallback uses `C_Map.GetBestMapForUnit("player")` (uiMapID). Area tips use `GetSubZoneText()` matched against `dungeon.areas[].subzone`, or `mapID` for zones without subzone text.

Position-based detection (future; not yet used):
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

## Performance Optimizations
- **Lazy Initialization:** `UI_Config.lua` and HUD visual resources are deferred until explicitly triggered (via gameplay events or slash cmds). This eliminates UI frame allocation during the initial character loading sequence.
- **Array Limits:** Uses standard array slicing (`KwikTip:PruneArray()`) instead of CPU-blocking `table.remove(..., 1)` logic to enforce size caps on logging vectors.
- **Event Deduplication:** State checks guard `ZONE_CHANGED` events from unconditionally creating duplicate GC payload logs on the same subzone mappings.
- **Dynamic Event Registration:** High-frequency targeting events (`PLAYER_TARGET_CHANGED`, `UPDATE_MOUSEOVER_UNIT`) are optimized or unregistered when the player is not actively inside a supported instance (`party/raid/scenario`). This prevents unnecessary CPU cycles and polling during open-world gameplay.

## Slash Commands
| Command | Action |
|---|---|
| `/kwiktip` or `/kwik` | Open/close settings window |
| `/kwik move` | Toggle move mode on the HUD |
| `/kwik debug` | Print current instance detection state to chat |
| `/kwik clearlog` | Clear mapIDLog and mobLog saved data |

A minimap button (when enabled in settings) provides quick access: left-click opens settings, right-click toggles move mode, drag to reposition.

## TODO / Known Gaps
- Legacy dungeon `uiMapID`s are set to `0` — verify in-game with `/run print(C_Map.GetBestMapForUnit("player"))` and update `DungeonData.lua`
- Legacy dungeons lack `areas` entries — add subzone/bossIndex mappings once uiMapIDs are confirmed
- Trash tips missing for Murder Row, Den of Nalorakk, The Blinding Vale, Voidscar Arena — collect NPC IDs via debug mobLog, then add `trash` entries
