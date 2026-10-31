-- Forever-only local test data. No Retail or Timewalking data is loaded.
local ADDON_NAME, KwikTip = ...

-- IDs: Wago Map/DungeonEncounter CSVs for build 1.60.1.70707.
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
}
