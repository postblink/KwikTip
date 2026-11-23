# Forever content refresh — 2026-11-22

Research-only candidate, not an installable release. Based on an exact file snapshot of the dirty four-map research candidate. Client manifest observed during this work: wowf 1.60.1.71037. Existing static evidence is from earlier builds; current-build table and hotfix requalification and live testing of this candidate remain outstanding.

## Krol'dok identity

The player's previously saved KwikTip encounter log records instance 3039, normal difficulty 1, five players: Slavecrusher Grox 3450, Twilight Commander Zarmok 3452, Handler Ashka 3453, Nar'gurk 3449, and Overseer Mugg 3451. These were observed events, not proof the new candidate displays correctly. The saved log does not establish the client build for each observation. Independent 70959 readable rows and their extraction limitations are preserved in `FOREVER_KROLDOK_IDS_70959.json`.

[Gaming Guide Archives](https://gamingguidearchives.com/guide/wow-forever-kroldok-stronghold-dungeon-guide/) calls the encounter Handler Ashka and describes her two beasts, Command: Kill! and fear; [Method](https://www.method.gg/wow-forever/dungeons/kroldok-stronghold), updated November 19, calls the same described wolf fight War Handler Ashka. Gaming Guide Archives explicitly states the journal's Overseer Mugg is called Overlord Mugg on the nameplate. Method describes Mugg's two Centurion guards, weapon phases and knockback. These are guide-based associations, not an assertion that the log identified the nameplate or NPC ID.

Method supplies the trash and encounter tactics, including peon runners, patrolling outriders, grunts' Bladestorm, shaman Bloodlust, Centurion Mortal Strike, and the controlled-player 50% threshold for Nar'gurk. Bossman Toof is discussed as a distinct encounter in Method, but no trustworthy event ID has been established. No event is invented; the overview explicitly states that no automatic tip exists. Source strategies are not a direct gameplay verification.

## Zul'Farrak

[Mobalytics](https://mobalytics.gg/wow-forever/dungeons/zul-farrak-dungeon-guide), updated November 12, describes Antu'sul's adds, Healing Ward and Healing Wave, Gahz'rilla's upward knockback and suggested low arch, and Zum'rah's adds and interrupt priority. [ConquestCapped](https://conquestcapped.com/guides/wow-forever/wow-forever-zulfarrak-guide/) describes Sandfury Shadowhunter Hex and the pyramid waves. [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/zulfarrak/) explicitly says its guide is Classic-based and not Forever beta-validated; its Theka transform and Velratha totem advice is therefore provisional. Sources disagree about Theka's exact transformation threshold and duration, so no number is asserted. Do not mistake old 70790 positive ID rows for 71037 qualification or simulated events for observed ZF events.

## Remaining limitations

Normal difficulty 1 only; no per-room, per-pull, wing or NPC-target detection. Persistent dungeon overview is opt-in; boss advice begins on a matching encounter event, not before pull. Eight ZF event IDs retain older static provenance, and both the guides and new candidate require real-client verification. The four-map candidate's other work is inherited, not freshly audited or certified here. The test package remains disabled by default but this setting does not override existing client enablement, so it must not be installed as an automatic compatibility test. The preexisting 2026-11-17 and 2026-11-18 research records are historical and retain their original exclusions and counts.
