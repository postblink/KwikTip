# KwikTip — Decision Log

This is the concise record of **durable decisions**: choices that affect addon architecture, data identity, content sourcing, localization, or user-facing behavior. It is not a feature wish list or a session diary.

## How to use this log

Add an entry only for settled decisions or explicit supersessions. Describe the choice, the reason, and the operational consequence. Link to implementation or source data rather than copying it here.

## Current decisions

### 2026-09-27 — Forever release scope is full dungeon coverage

- **Decision:** The Forever-specific KwikTip release targets all Vanilla-era dungeon content units/wings plus all nine new Forever dungeons; it is not a two-dungeon preview or a nine-new-dungeon-only flavor. The current matrix has 26 Classic units (including Upper Blackrock Spire) plus nine new dungeons, but the exact total stays provisional until the client resolves the 34-vs-35 roster discrepancy.
- **Why:** Forever retains the Classic dungeon progression while adding nine dungeons. Owner reports the returning dungeons so far behave like Classic/Vanilla; their strategies are promising reuse candidates, but Forever identity, encounter coverage, and changes still need verification.
- **Consequence:** Keep Forever data/package isolated from Retail. Inventory wings/sides separately where independently runnable; verify Forever IDs/modes and all encounter/tip triggers. KwikTip remains a strategy-tip addon, not a loot-table browser; new itemization does not silently expand its data model. Raid coverage is separate; keep Upper Blackrock Spire in the candidate set pending its Forever dungeon/raid classification.
- **Source:** Owner direction; `docs/FOREVER_COVERAGE_MATRIX.md`.

### 2026-09-09 — Identity is ID-based; display is locale-aware

- **Decision:** Detect instances, encounters, NPCs, and maps from canonical game IDs. Use Blizzard APIs for localized display names and locale files only for authored tip prose.
- **Why:** Names vary by locale and game patch; IDs preserve the stable data contract.
- **Consequence:** Resolve missing IDs from DB2 first; use runtime/in-game checks only for genuinely dynamic subzone names or positions.
- **Source:** `AGENTS.md`.

### 2026-09-09 — Game data and strategy content remain separate

- **Decision:** Static client data provides IDs and names; tips come from ranked guide sources, led by Tactyks/method.gg for Mythic+.
- **Why:** It keeps data correctness independent from mutable strategy advice.
- **Consequence:** Review `tools/.monitor/updates.md` before any tip-content work; source monitoring may trigger prose updates without changing IDs.
- **Source:** `AGENTS.md`.

### 2026-09-09 — The HUD is contextual and deliberately quiet

- **Decision:** The HUD surfaces area-relevant information inside supported instances and stays hidden elsewhere unless move mode is active.
- **Why:** A pull-time aid should reduce cognitive load rather than become another UI panel to manage.
- **Consequence:** HUD mouse passthrough is disabled by default and only enabled in move mode.
- **Source:** `AGENTS.md`.

### 2026-09-17 — Forever content targets the modern client API

- **Decision:** Any KwikTip coverage for **Forever** uses the modern client API; do not constrain its design to legacy/Classic API compatibility.
- **Why:** Forever's supported client contract is modern, so a compatibility layer for older API behavior would add complexity without serving its target environment.
- **Consequence:** Keep Forever data/content isolated from Midnight and other game branches, but prefer current client APIs and events when adding it. Treat the exact interface version, API surface, instance IDs, and runtime behavior as a release/build verification gate rather than assuming they match Midnight.
- **Source:** Owner direction, 2026-09-17.
