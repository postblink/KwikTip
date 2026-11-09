# Later Classic source assessment — 2026-11-09

Historical source handoff: Uldaman was subsequently implemented and verified
as documented in FOREVER_ULDAMAN_SOURCES_20261109.md and FOREVER_NEXT_20261109.md.

## Ready slice: Razorfen Kraul

CONFIRMED: six exact encounter/name matches2773–2778 in preserved70790 Map47;
three raw table SHA-256 values verified against saved manifest. Normal1 only,
no route inference. Current70862 and client runtime remain unverified.

Strategy read live: https://www.icy-veins.com/wow-forever/razorfen-kraul-guide
(header Oct18; Forever-labelled strategy section). Its headline says seven but
lists six regular and two rares; never copy its total. Earthcaller Halmgar and
Blind Hunter lack matching rows and are explicitly excluded. Authored tips93
words, conservative original summary. No threshold or NPC/area guess.

Files: razorfen_kraul.lua, coverage_entries.json,
FOREVER_RAZORFEN_KRAUL_IDS_70790.json. Standalone Lua parse passed; ID/name/hash
checks passed. Shared runtime/integration gates must be run by parent.

## Razorfen Downs: defer automatic inclusion

https://www.wowhead.com/forever/guide/razorfen-downs-dungeon-overview-location-rewards
was read live, updated Oct30. It has six strategy sections matching preserved
Map129 IDs2780–2785, BUT explicitly warns unavailable dungeons use Classic data
and the guide may be inaccurate. Icy lists it Coming Soon; its direct endpoint
and Method endpoint were inaccessible. This is reusable provisional advice,
not proof of tested Forever behavior. Do not silently qualify it as current.
No RFD snippet/coverage entry created in this safe batch.

## Broader availability

Icy overview read live (Oct24):
https://www.icy-veins.com/wow-forever/dungeons-overview
Graveyard and Library have guide links. Armory/Cathedral, Downs, Uldaman,
ZulFarrak, Maraudon, SunkenTemple, BRD, BRS, Scholomance, Stratholme and all
DireMaul wings remain Coming Soon there. This does NOT mean no sources exist.

Wowhead Uldaman read live, patch1.60.1 updated Nov6, detailed strategies:
https://www.wowhead.com/forever/guide/uldaman-dungeon-overview-location-rewards
No old-beta warning in the opening reviewed. Strong next candidate after
reading mechanics and matching static IDs, not yet implementation-qualified.

Additional Wowhead search discoveries (not full mechanic-reviewed):
- /forever/guide/scarlet-monastery-graveyard-dungeon-overview-location-rewards (Oct24)
- /forever/guide/scarlet-monastery-library-dungeon-overview-location-rewards (Oct24)
- /forever/guide/scarlet-monastery-cathedral-dungeon-overview-location-rewards (Oct22)
  Search snippets retain Classic-fallback warning for these three.
- /forever/guide/zulfarrak-dungeon-overview-location-rewards (Nov6)
- /forever/guide/maraudon-dungeon-overview-location-rewards
- /forever/guide/the-temple-of-atalhakkar-dungeon-overview-location-rewards
- /forever/guide/blackrock-depths-dungeon-overview-location-rewards (Nov4)
- /forever/guide/upper-blackrock-spire-dungeon-overview-location-rewards (Nov6)
- /forever/guide/scholomance-dungeon-overview-location-rewards (Nov6)
- /forever/guide/stratholme-live-side-dungeon-overview-location-rewards (Nov4)
- /forever/guide/dire-maul-gordoks-commons-north-dungeon-overview-location-rewards (Nov4)
- /forever/guide/dire-maul-warpwood-quarter-east-dungeon-overview-location-rewards (Nov4)
- /forever/guide/dire-maul-capital-gardens-west-dungeon-overview-location-rewards

Those are leads, not evidence of observed Forever combat. Read each page's
caveats and source history before using, and don't treat all /forever URL paths
as proof the content was retested. LowerBRS/Stratholme service-side source
qualification still outstanding. No implementation, commit or publication for
these remaining units by this worker.
