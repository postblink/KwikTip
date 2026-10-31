# Stormwind Stockade — five-encounter alpha slice

Status (2026-10-31): exact-build static IDs and source-backed Normal-mode tips
implemented in the existing `0.1.0-alpha.1` review candidate. No game load or
client event pass is established. Installed `0.1.0-test` is unchanged.

Wago's refreshed 1.60.1.70707 exports verify party Map **34**, with these records:

| Encounter | ID |
|---|---:|
| Targorr the Dread | 2756 |
| Kam Deepfury | 2757 |
| Hamhock | 2758 |
| Dextren Ward | 2759 |
| Bazil Thredd | 2760 |

Area **717** links to Map 34 but is not a runtime subzone trigger. No Stockade
UiMap or Map 34/Area 717 assignment was found. NPC/subzone/map-fallback fields
are omitted. MapDifficulty contains normal **1/five players**, **201/ten** and
**214/five**; only difficulty 1 is in the alpha scope. Source hashes and selected
rows are in `FOREVER_STOCKADE_IDS_70707.json`, including guide-response provenance.

Current Forever [Method/Jurdi, October 15](https://www.method.gg/wow-forever/dungeons/the-stockade)
and [Icy Veins/Neryssa, October 19](https://www.icy-veins.com/wow-forever/the-stockade-guide)
support the cautious five boss tips and generic preparation overview. The text
omits Targorr's conflicting exact enrage threshold, Bazil add composition, and
the questionable precise trash-stun duration. No legacy data is imported.

**Rare Bruegal Ironknuckle is explicitly excluded from automatic tips.** Both
guides describe him, but the complete exact-build DungeonEncounter export has
no Bruegal/ironknuckle name match. No guessed encounter ID or NPC/name fallback
is shipped. His presence is a known coverage gap, not evidence he was removed.

The two wings and reordered fights do not imply a fixed route. With
`previewNextBoss=false`, a kill restores the optional overview/quiet state.
The overview is instance-wide advice, not current-pack or room detection.

November 4 acceptance: verify actual instance/difficulty and all five event
IDs/names, reordered wings, success/wipe/exit cleanup, overview opt-in and
persistence. If Bruegal appears, record whether an event is logged and its exact
identity before considering a detector. No complete-dungeon claim is made.
