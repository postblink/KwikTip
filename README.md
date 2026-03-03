<p align="center">
  <img src="assets/ktlogo.png" alt="KwikTip" />
</p>

A World of Warcraft: Midnight addon that displays contextual tips for dungeons and raids. As your group moves through an instance, KwikTip surfaces relevant boss and trash tips in a small, unobtrusive HUD — no interaction required mid-pull.

Inspired by **QE Dungeon Tips** by QEdev (no longer maintained).

---

## Features

- **Area-aware HUD** — automatically shows and hides based on whether you're in a supported instance
- **Boss tips** — concise, actionable guidance for every boss in the Season 1 M+ rotation

---

## Dungeon Coverage

### Season 1 Mythic+ Rotation

| Dungeon | Type |
|---|---|
| Windrunner Spire | New — Midnight |
| Maisara Caverns | New — Midnight |
| Magisters' Terrace | New — Midnight (reworked) |
| Nexus-Point Xenas | New — Midnight |
| Algeth'ar Academy | Legacy |
| Pit of Saron | Legacy |
| Seat of the Triumvirate | Legacy |
| Skyreach | Legacy |

### Additional Midnight Dungeons

| Dungeon | Type |
|---|---|
| Murder Row | Level-up (81–88) |
| Den of Nalorakk | Level-up (81–88) |
| The Blinding Vale | Max level |
| Voidscar Arena | Max level |

---

## Installation

1. Download or clone this repository
2. Copy the `KwikTip` folder into your addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/KwikTip
   ```
3. Enable the addon in the WoW character select screen

---

## Usage

| Command | Action |
|---|---|
| `/kwiktip` or `/kwik` | Open/close settings |
| `/kwik move` | Toggle move mode (drag the HUD) |
| `/kwik debug` | Print current instance detection state to chat |

The HUD is hidden outside of instances. Use `/kwik move` to show and reposition it at any time.
