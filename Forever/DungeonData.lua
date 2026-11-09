-- Forever-only local test data. No Retail or Timewalking data is loaded.
local ADDON_NAME, KwikTip = ...

-- IDs: Wago Map/DungeonEncounter CSVs: existing entries use 70707;
-- All newly added entries use preserved 70790 exports. Current 70862 drift remains unverified.
-- Strategy: current Forever Method/Icy Veins guides. See the per-dungeon
-- readiness/provenance documents listed in Forever/Coverage.json.
-- These static IDs do not establish an in-game pass. UiMap/NPC/subzone
-- identifiers remain unverified and are deliberately omitted, not set to 0.
KwikTip.DUNGEONS = {
    {
        instanceID = 3065,
        name = "The Hall of Thanes",
        season = "forever",
        type = "dungeon",
        difficultyIDs = { 1 }, -- source-backed normal-mode alpha only
        -- Dungeon-wide preparation only. No claim to detect the current pack,
        -- room, subzone or NPC. Shown by the existing opt-in persistent setting.
        overview = "Engineers: move away from the bomb's target spot.\n"
            .. "Summoners: interrupt casts; use line of sight to bring them closer.\n"
            .. "Looters and Golems hit hard: keep pulls small and control extra enemies.",
        bosses = {
            {
                encounterID = 3493,
                name = "Faldrim Anvilmar",
                tip = "Clear space along the patrol before pulling. Interrupt Mind Blast.",
            },
            {
                encounterID = 3495,
                -- DungeonEncounter uses Infurnus; guides call him Magmatus.
                -- The HUD prefers the actual localized ENCOUNTER_START name.
                name = "Infurnus",
                tip = "Provisional Magmatus guide match: kill the Dark Iron Summoner first. Keep the boss away from the party to limit fire damage.",
            },
            {
                encounterID = 3494,
                name = "Plunder",
                tip = "Clear nearby packs and fight with your back toward a safe wall so Knock Away cannot push you into another group.",
            },
            {
                encounterID = 3496,
                name = "Durgen Dirgehammer",
                tip = "Clear the surrounding room before pulling. Prepare for two Lesser Stone Golems and heavy tank damage from Rend; Fear can send players toward uncleared enemies.",
            },
        },
    },
    {
        instanceID = 389,
        name = "Ragefire Chasm",
        season = "forever",
        type = "dungeon",
        difficultyIDs = { 1 },
        -- DB2 order is an encounter roster, not observed player progression.
        -- Surface actual encounter events; do not guess the next pull after a kill.
        previewNextBoss = false,
        overview = "Shaman: interrupt Healing Wave; use line of sight to bring casters closer.\n"
            .. "Avoid large Enforcer pulls that can chain-stun the tank. Keep fights away from lava edges.",
        bosses = {
            {
                encounterID = 2732,
                name = "Oggleflint",
                tip = "Clear nearby troggs before pulling. Face the boss away from the party so his cleave does not hit other melee players.",
            },
            {
                encounterID = 2733,
                name = "Taragaman the Hungerer",
                tip = "Tank near the center of the platform so Uppercut cannot knock you into lava. Stay out of melee range when possible to avoid Fire Nova.",
            },
            {
                encounterID = 2734,
                name = "Jergosh the Invoker",
                tip = "Control the two accompanying enemies. Remove Immolate and Curse of Weakness when your group has the appropriate dispels.",
            },
            {
                encounterID = 2735,
                name = "Bazzalan",
                tip = "Control the two adds and focus the boss. Healers watch tank damage from poison and Sinister Strike.",
            },
        },
    },
    {
        instanceID = 34,
        name = "Stormwind Stockade",
        season = "forever",
        type = "dungeon",
        difficultyIDs = { 1 },
        previewNextBoss = false, -- wing order is not assumed from DB2 OrderIndex
        -- Rare Bruegal has no verified DungeonEncounter mapping and is excluded.
        overview = "Clear nearby cells before boss pulls and control accompanying prisoners.\n"
            .. "Keep pulls small: prisoner stuns and bleeds can compound tank damage.",
        bosses = {
            {
                encounterID = 2756,
                name = "Targorr the Dread",
                tip = "Control or kill the accompanying prisoners. Healers prepare for fast tank hits and an enrage late in the fight.",
            },
            {
                encounterID = 2757,
                name = "Kam Deepfury",
                tip = "Control or kill nearby prisoners first. Watch the tank during Shield Slam's stun.",
            },
            {
                encounterID = 2758,
                name = "Hamhock",
                tip = "Control the two accompanying prisoners. Spread out to reduce Chain Lightning jumps.",
            },
            {
                encounterID = 2759,
                name = "Dextren Ward",
                tip = "Clear nearby cells before pulling so Intimidating Shout cannot fear players into additional packs.",
            },
            {
                encounterID = 2760,
                name = "Bazil Thredd",
                tip = "Ranged players stay away from Smoke Bomb. Keep the tank healthy before its nearby stun and watch for heavy melee damage.",
            },
        },
    },
    {
        -- Preserved Wago 70790 IDs; current 70862 recheck remains pending.
        -- Do not infer a route or map The Baron onto The Butcher (3355).
        instanceID = 2999,
        name = "Ruins of Lordaeron",
        season = "forever",
        type = "dungeon",
        difficultyIDs = { 1 },
        previewNextBoss = false,
        overview = "Pull spider packs back from patrols. Avoid combining heavy-hitting golems or monstrosities with other packs.\n"
            .. "Prioritize Ragged Ghouls; keep nearby groups out of the pull.\n"
            .. "This candidate omits The Baron/Butcher and the rare Lordaeron Captain.",
        bosses = {
            {
                encounterID = 3353,
                name = "Witherfang",
                tip = "Clear a safe section of the patrol before pulling. Keep the tank healthy through the poison and control the accompanying spiders.",
            },
            {
                encounterID = 3357,
                name = "The Abandoned",
                tip = "Start the statue event with health and mana ready for several waves. Stop Life Drain with a stun; expect nearby roots and slows.",
            },
            {
                encounterID = 3411,
                name = "Viktor the Vile",
                tip = "Optional fireplace event: conserve mana through the waves. Let the tank establish threat when Viktor arrives.",
            },
            {
                encounterID = 3412,
                name = "Bjork",
                tip = "Clear nearby enemies before engaging and keep the fight away from other patrols. His detailed ability advice is pending source reconciliation.",
            },
            {
                encounterID = 3354,
                name = "Rath'mael",
                tip = "Clear surrounding enemies first. Move out of Flamestrike; use a stun to prevent the cast when available.",
            },
        },
    },
    {
        -- Preserved 70790 IDs, not current 70862 qualification.
        instanceID = 2998,
        name = "Excavation Site: Wetlands",
        season = "forever",
        type = "dungeon",
        difficultyIDs = { 1 },
        previewNextBoss = false,
        overview = "Keep raptor pulls small and watch for hidden enemies near the grass.\n"
            .. "Dodge Saboteur bombs. Clear room around bosses before pulling; Highland Horror is an optional quest encounter.",
        bosses = {
            { encounterID = 3480, name = "Saltspine",
              tip = "Pull away from other lake enemies. Keep ranged players outside melee range during Dust Storm; watch the tank's movement slow." },
            { encounterID = 3481, name = "Shadetooth",
              tip = "Clear hidden raptors before pulling so fear cannot bring extra packs. Control the two accompanying Hunters and prepare healing and stops for heavy bleed damage and enrage." },
            { encounterID = 3644, name = "Highland Horror",
              tip = "Optional quest encounter: clear nearby slimes first. Expect roots and self-healing; avoid bringing surrounding enemies into the fight." },
            { encounterID = 3482, name = "Relic Guardian",
              tip = "Activate with the nearby control panel when ready. Face the guardian away from allies; ranged stay outside melee range. Prepare for knockbacks, stuns and threat disruption." },
        },
    },
    {
        -- Seven exact name/ID matches; no inferred Mana Elemental/Enigma alias.
        instanceID = 2959,
        name = "City of Dalaran",
        season = "forever", type = "dungeon", difficultyIDs = { 1 },
        previewNextBoss = false,
        overview = "Keep pulls controlled and replenish mana between fights.\n"
            .. "Partial coverage: Arcanic Enigma and unmatched static records have no automatic tip.",
        bosses = {
            { encounterID = 3311, name = "Atrexis the Grave Knight",
              tip = "Clear nearby necromancers first. Control summoned skeletons and watch threat while the tank is disarmed." },
            { encounterID = 3310, name = "Lyn the Ignored",
              tip = "Optional summoned encounter: heal through Shadow Bolt Volley, remove Curse of Thorns when able, and control skeleton adds." },
            { encounterID = 3298, name = "Arcane Anomaly",
              tip = "Avoid the rotating Focal Blast beam and keep away from edge adds. Interrupt Arcane Bolt when possible." },
            { encounterID = 3299, name = "Fel Ancient",
              tip = "Move out of green pools immediately. Save root-breaking abilities for Entangle overlapping a pool." },
            { encounterID = 3300, name = "Mana Devourer",
              tip = "Clear the room before engaging; remaining enemies join the fight. Start with mana ready and finish before repeated drains exhaust the healer." },
            { encounterID = 3302, name = "Unstable Sentinel",
              tip = "Clear nearby enemies first. Face the boss away from allies and move out for Malfunction; ranged and healers stay well back." },
            { encounterID = 3303, name = "Shade of the Archmage",
              tip = "Spread and dodge Bounding Mana. Ranged and healers stay back from Arcane Explosion; expect Mass Polymorph and a mana refill when the boss runs dry." },
        },
    },
    {
        -- Preserved70790 IDs; current70862 validation pending.
        instanceID = 36, name = "Deadmines",
        season = "forever", type = "dungeon",
        difficultyIDs = { 1 }, previewNextBoss = false,
        overview = "Clear space before pulls and avoid adding patrols. This is encounter advice, not a route tracker.",
        bosses = {
            { encounterID = 2741, name = "Rhahk'Zor",
              tip = "Pull guards separately first. Healers watch the tank during stuns." },
            { encounterID = 2742, name = "Sneed",
              tip = "Clear nearby goblins before the shredder's fear. After Sneed emerges, watch threat during Disarm." },
            { encounterID = 3676, name = "Miner Johnson",
              tip = "Rare encounter: remove nearby miners first so the tank is not overwhelmed." },
            { encounterID = 2743, name = "Gilnid",
              tip = "Control or kill the accompanying Engineer before robot summons accumulate. Watch tank threat during the fire debuff." },
            { encounterID = 2745, name = "Mr. Smite",
              tip = "Kill the Blackguards first. Prepare tank healing for group stuns and later weapon changes." },
            { encounterID = 2744, name = "Captain Greenskin",
              tip = "Prioritize the Squallshaper escort. Tank faces Greenskin away from melee allies to avoid cleave." },
            { encounterID = 2747, name = "Edwin VanCleef",
              tip = "Kill initial Blackguards and handle additional guards as they arrive. Keep the tank healthy through heavy hits." },
            { encounterID = 2746, name = "Cookie",
              tip = "Bring Cookie away from the ship. Interrupt Cookie's Cooking to prevent healing." },
        },
    },
    {
        -- Preserved70790 IDs; current70862 validation pending.
        instanceID = 43, name = "Wailing Caverns",
        season = "forever", type = "dungeon",
        difficultyIDs = { 1 }, previewNextBoss = false,
        overview = "Clear space before pulls and avoid adding patrols. This is encounter advice, not a route tracker.",
        bosses = {
            { encounterID = 585, name = "Lady Anacondra",
              tip = "Avoid adding patrols. Interrupt Sleep and Healing Touch; control extra enemies." },
            { encounterID = 586, name = "Lord Cobrahn",
              tip = "Kill accompanying snakes. Interrupt sleep and prepare extra tank healing when he transforms." },
            { encounterID = 587, name = "Kresh",
              tip = "High armor slows physical damage. Use armor reduction where available and maintain tank healing." },
            { encounterID = 588, name = "Lord Pythas",
              tip = "Control the accompanying enemies and interrupt sleep. Ranged stay back from Thunderclap." },
            { encounterID = 589, name = "Skum",
              tip = "Spread out so Chained Bolt does not connect nearby players." },
            { encounterID = 590, name = "Lord Serpentis",
              tip = "Control the accompanying druids. Interrupt sleep, heals and Lightning Bolt." },
            { encounterID = 591, name = "Verdan the Everliving",
              tip = "Prepare for heavy tank damage. Ranged stay outside melee range to avoid nearby roots." },
            { encounterID = 592, name = "Mutanus the Devourer",
              tip = "Escort finale: protect the Disciple through waves. Expect fear and sleep; ranged stay away from Thundercrack." },
        },
    },
}
