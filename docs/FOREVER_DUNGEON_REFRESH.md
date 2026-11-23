# Forever dungeon refresh

The test build supports Normal mode on 28 runtime maps, representing 35 tracked dungeon units when the independently playable Scarlet, Spire, Dire Maul and Stratholme wings are counted separately. Preparation advice and the manual boss picker work by instance, not by guessed room, pack, wing, or boss order. Some returning-dungeon tactics still use explicitly qualified Classic references. See [Coverage.json](../Forever/Coverage.json) for shipped encounter IDs.

## Evidence

[Build 1.60.1.71037 readable client rows](FOREVER_CURRENT_IDS_71037.json) qualify the registered map, Normal mode and encounter IDs. Exact-build schemas were matched to the local table layout using [WoWDBDefs](https://github.com/wowdev/WoWDBDefs/tree/3a7954cfb8ee4f1132c83cd1859753294ee8964b/definitions). A local hotfix reconciliation scanned 120,558 records; 13 matched the three identity table hashes, and none changed a final readable row. Some blocks remained unreadable (3 Map, 4 MapDifficulty and 23 DungeonEncounter records), so absence is not established. Static client rows for Demon Fall Canyon and Karazhan Crypts do not prove they are currently playable.

Prior Forever logs corroborate all eight registered Normal events in Zul'Farrak and all five in Krol'dok. Both pyramid IDs can start together in either order; both show the full paired-fight tip. Those logs did not capture room transitions, exact per-event build, or which tip rendered. No raw player logs are packaged.

The refresh uses original summaries of guide tactics. Guides used for preparation and revised tips include:

- [Method's Forever dungeon index](https://www.method.gg/wow-forever/dungeons), including the named entries for Scarlet's wings, Razorfen Downs, Uldaman, the Hall, Ruins, Excavation, Dalaran, Drowned City, Krol'dok, Alcaz and Blackmaw, and the early Classic dungeons.
- [Zul'Farrak](https://mobalytics.gg/wow-forever/dungeons/zul-farrak-dungeon-guide) and [Scarlet and other returning dungeons](https://www.method.gg/wow-forever/dungeons).
- [Maraudon orange](https://www.icy-veins.com/wow-classic/maraudon-orange-wing-dungeon-guide) and [purple](https://www.icy-veins.com/wow-classic/maraudon-purple-wing-dungeon-guide) Classic guides; preparation is explicitly labeled Classic.
- [Blackrock Depths](https://wow.gg/guides/blackrock-depths), [Scholomance](https://wow.gg/guides/scholomance), [Lower Spire](https://wow.gg/guides/lower-blackrock-spire) and [Upper Spire](https://wow.gg/guides/upper-blackrock-spire).
- [Shaper’s Terrace](https://conquestcapped.com/guides/wow-forever/wow-forever-shapers-terrace-guide).
- Late-dungeon Classic references: [Sunken Temple](https://www.icy-veins.com/wow-classic/sunken-temple-dungeon-guide), Dire Maul [East](https://www.icy-veins.com/wow-classic/dire-maul-east-dungeon-guide), [West](https://www.icy-veins.com/wow-classic/dire-maul-west-dungeon-guide), and [North](https://www.icy-veins.com/wow-classic/dire-maul-north-dungeon-guide), and Stratholme [Living](https://www.icy-veins.com/wow-classic/stratholme-live-dungeon-guide) and [Undead](https://www.icy-veins.com/wow-classic/stratholme-undead-dungeon-guide).

All 86 distinct Normal-mode encounter IDs in the reviewed historical logs now have tips. ForeverDB links [Geilhast](https://www.foreverdb.app/en/forever/embed/dungeons/blackfathom-deeps/2914) to Gelihast, [Mana Elemental](https://www.foreverdb.app/en/forever/embed/dungeons/city-of-dalaran/3301) to Arcanic Enigma, and [The Butcher](https://www.foreverdb.app/en/forever/embed/dungeons/ruins-of-lordaeron/3355) to The Baron. The Mana Elemental match also follows the [Power Overwhelming quest objective](https://wowforevertalents.com/quests/power-overwhelming-92489/). The [Drowned City guide](https://www.method.gg/wow-forever/dungeons/the-drowned-city) corroborates the Guardian add tactic; event 3478 does not establish a Marrow alias.

Blackrock Depths' arena, Seven and vault are aggregate tips rather than per-NPC triggers. The Blazeroar and Blackmaw Behemoth tips cover their documented phases or partners without predicting when the client emits their event. In-client acceptance of the updated build is pending; offline tests cover manifest loading, routing, the picker, overview settings and encounter transitions, not gameplay or room detection.
