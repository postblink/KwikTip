-- KwikTip: Dungeon and boss data for World of Warcraft: Midnight
--
-- Two ID systems are used for dungeon detection:
--
--   instanceID : GetInstanceInfo() 8th return — single stable ID per dungeon instance.
--                Used as the PRIMARY lookup. Source: BigWigs/LittleWigs NewBoss declarations.
--                All values are unverified unless noted. IDs marked 0 need to be sourced.
--
--   uiMapID    : C_Map.GetBestMapForUnit("player") — required for position queries.
--                Used as FALLBACK when instanceID lookup fails (e.g., instanceID = 0).
--                Verify in-game: /run print(C_Map.GetBestMapForUnit("player"))
--                IDs marked 0 need to be confirmed in-game.
--
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- Dungeon Data
-- ============================================================
-- Fields per dungeon:
--   instanceID  : GetInstanceInfo() 8th return — primary dungeon identifier
--   uiMapID     : C_Map.GetBestMapForUnit("player") inside the instance
--   altMapIDs   : additional uiMapIDs for entrance/antechamber sub-zones (fallback lookup)
--   name        : display name
--   location    : zone the entrance is in
--   season      : "midnight" = new dungeon  |  "legacy" = returning M+ dungeon
--   type        : "level" = leveling (81-88)  |  "max" = max-level (88-90)
--   mythicPlus  : true if in the Season 1 Mythic+ key rotation, false = Mythic 0 only
--   bosses      : ordered list; each entry has:
--     encounterID : ENCOUNTER_START event ID (from LittleWigs SetEncounterID). 0 = unknown.
--     name        : boss name as shown in the game
--     tip         : short contextual tip shown in the HUD during the boss fight
--   trash       : optional list of notable trash mobs; PLAYER_TARGET_CHANGED shows tip on match
--     npcID     : numeric NPC ID extracted from UnitGUID("target"):match("-(%d+)-%x+$")
--     name      : mob display name
--     tip       : contextual tip shown in HUD when this mob is targeted
--   areas       : optional list; if present, HUD switches to area-based tips
--                 matched against GetSubZoneText() as the player moves through the dungeon
--     subzone   : exact string returned by GetSubZoneText() for this area (verify in-game)
--     tip       : contextual tip shown in HUD when the player is in this sub-zone
--
-- Season 1 M+ rotation (8 dungeons total):
--   New Midnight: Magisters' Terrace, Maisara Caverns, Nexus-Point Xenas, Windrunner Spire
--   Legacy:       Algeth'ar Academy, Pit of Saron, Seat of the Triumvirate, Skyreach

KwikTip.DUNGEONS = {

    -- --------------------------------------------------------
    -- NEW MIDNIGHT DUNGEONS — Level-Up (81–88)
    -- --------------------------------------------------------
    {
        instanceID = 2805,  -- BigWigs, unverified in-game
        uiMapID    = 2492,
        name       = "Windrunner Spire",
        location   = "Eversong Woods",
        season     = "midnight",
        type       = "level",
        mythicPlus = true,
        bosses = {
            { encounterID = 3056, name = "Emberdawn",          tip = "Tank in corner; players hit by Flaming Updraft drop it near the corner and use a personal defensive; dodge Twisters spawned from puddles; healer major CDs on Burning Gale." },
            { encounterID = 3057, name = "Derelict Duo",       tip = "Keep both at equal health throughout — Broken Bond stacks if they're uneven and enrages the survivor; interrupt Kalis's Shadow Bolt; tank use active mitigation for Latch's Bone Hack." },
            { encounterID = 3058, name = "Commander Kroluk",   tip = "Burn adds at 66%/33%; boss immune (Shield Wall) until warparty dies; stay grouped — Intimidating Shout fears isolated players." },
            { encounterID = 3059, name = "The Restless Heart", tip = "Dodge Arrow Rain; sidestep targeted Bolt Gale; at 100 energy, boss fires wind arrow spawning expanding Billowing Wind rings — stay out; never touch Turbulent Arrows (knockup + removes Squall Leap)." },
        },
    },
    {
        instanceID = 2813,  -- BigWigs, unverified in-game
        uiMapID    = 2813,  -- TODO: unverified — matches BigWigs instanceID, likely wrong; verify in-game
        name       = "Murder Row",
        location   = "Silvermoon City",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses = {
            { encounterID = 3101, name = "Kystia Manaheart",        tip = "Dispel Illicit Infusion from Nibbles for 15s stun + 100% dmg window — Kystia radiates Chaos AoE during this phase so healer CDs needed; dodge Nibbles' Fel Spray cone while she's hostile; interrupt Mirror Images." },
            { encounterID = 3102, name = "Zaen Bladesorrow",        tip = "Stand behind Forbidden Freight during Murder in a Row; move Fire Bomb away from freight (it destroys cover); Heartstop Poison halves tank max health — prioritize tank healing." },
            { encounterID = 3103, name = "Xathuux the Annihilator", tip = "Dodge Axe Toss impact zones and the Fel Light left behind; stay mobile to avoid Burning Steps." },
            { encounterID = 3105, name = "Lithiel Cinderfury",      tip = "Kill Wild Imps before Malefic Wave reaches them (they gain haste if hit); use Gateways to avoid the wave; interrupt Chaos Bolt." },
        },
    },
    {
        instanceID = 2825,  -- BigWigs, unverified in-game
        uiMapID    = 2514,
        altMapIDs  = { 2564 },  -- 2564 = entrance/antechamber sub-zone
        name       = "Den of Nalorakk",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses = {
            { encounterID = 3207, name = "The Hoardmonger",    tip = "At 90%/60%/30%, boss retreats to empower; destroy Rotten Mushrooms before burst (Toxic Spores debuff); dodge frontals." },
            { encounterID = 3208, name = "Sentinel of Winter", tip = "Dodge Raging Squalls; stand in Snowdrift zones to resist the Eternal Winter knockback." },
            { encounterID = 3209, name = "Nalorakk",           tip = "Fury of the War God: intercept charging echoes to protect Zul'jarra; spread when Echoing Maul marks you." },
        },
    },
    {
        instanceID = 2874,  -- BigWigs, unverified in-game
        uiMapID    = 2501,
        name       = "Maisara Caverns",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = true,
        bosses = {
            { encounterID = 3212, name = "Muro'jin and Nekraxx",     tip = "Kill simultaneously — Muro'jin dies first: Nekraxx enrages (Bestial Wrath); Nekraxx dies first: Muro'jin revives him. Use Freezing Trap victims to interrupt Nekraxx's Carrion Swoop." },
            { encounterID = 3213, name = "Vordaza",                  tip = "Vordaza is immune during Necrotic Convergence — use healer CDs for the damage; kill phantoms (Lingering Dread damages group); dodge Unmake." },
            { encounterID = 3214, name = "Rak'tul, Vessel of Souls", tip = "In spirit realm: interrupt Malignant Souls for Spectral Residue (+25% dmg/heal/speed); avoid Restless Masses roots. Destroy Crush Souls totems before returning." },
        },
    },

    -- --------------------------------------------------------
    -- NEW MIDNIGHT DUNGEONS — Max Level (88–90)
    -- --------------------------------------------------------
    {
        instanceID = 2811,  -- BigWigs, unverified in-game
        uiMapID    = 2511,
        altMapIDs  = { 2424, 2515, 2519, 2520 },  -- antechamber, entrance, sub-zones
        name       = "Magisters' Terrace",
        location   = "Isle of Quel'Danas",
        season     = "midnight",
        type       = "max",
        mythicPlus = true,
        bosses = {
            { encounterID = 3071, name = "Arcanotron Custos", tip = "Intercept orbs before they reach the boss; avoid Arcane Residue zones left after the knockback." },
            { encounterID = 3072, name = "Seranel Sunlash",   tip = "At 100 energy, be inside a Suppression Zone or Wave of Silence pacifies you for 8s (unable to cast); also step into a zone to resolve Runic Mark (Feedback) — but zones purge your buffs." },
            { encounterID = 3073, name = "Gemellus",          tip = "All copies share health; touch correct clone to clear Neural Link." },
            { encounterID = 3074, name = "Degentrius",        tip = "One player per quadrant soaks Void Essence as it bounces; miss = Void Destruction stack (wipe at 2). Never touch Void Torrent beams — they stun." },
        },
    },
    {
        instanceID = 2915,  -- BigWigs, unverified in-game
        uiMapID    = 2556,
        name       = "Nexus-Point Xenas",
        location   = "Voidstorm",
        season     = "midnight",
        type       = "max",
        mythicPlus = true,
        bosses = {
            { encounterID = 3328, name = "Chief Corewright Kasreth", tip = "Never cross active Leyline Arrays — lethal. When targeted by Reflux Charge, use it to destroy a nearby array for bonus damage." },
            { encounterID = 3332, name = "Corewarden Nysarra",       tip = "Kill Null Vanguard adds before Lightscar Flare; then stand in the wound during 18s stun for 300% damage." },
            { encounterID = 3333, name = "Lothraxion",               tip = "At 100 energy, find and interrupt the real Lothraxion among his images; wrong target = Core Exposure (group damage + 20% increased Holy damage taken for 1 min)." },
        },
    },
    {
        instanceID = 2859,  -- BigWigs, unverified in-game
        uiMapID    = 2500,  -- unverified in-game
        name       = "The Blinding Vale",
        location   = "Harandar",
        season     = "midnight",
        type       = "max",
        mythicPlus = false,
        bosses = {
            { encounterID = 3199, name = "Lightblossom Trinity",   tip = "Block Lightblossom Beams to prevent Light-Gorged stacks on flowers before they detonate; interrupt Lightsower Dash to stop seed planting; all three bosses share damage." },
            { encounterID = 3200, name = "Ikuzz the Light Hunter", tip = "Destroy Bloodthorn Roots quickly — rooted players are also hit by Crushing Footfalls; Bloodthirsty Gaze fixates Ikuzz on a player for 10s — maintain distance or be Incised." },
            { encounterID = 3201, name = "Lightwarden Ruia",       tip = "Heal players to full to clear Grievous Thrash bleeds; at 40%, Ruia enters Haranir form (Spirits of the Vale) and rapidly cycles all abilities — tank rotate to avoid stacking Pulverizing Strikes damage-taken debuff." },
            { encounterID = 3202, name = "Ziekket",                tip = "Position so Ziekket's Concentrated Lightbeam sweeps over Dormant Lashers to vaporize them; dodge the beam and avoid the Lightsap puddles it leaves behind." },
        },
    },
    {
        instanceID = 2923,  -- BigWigs, unverified in-game
        uiMapID    = 2572,
        altMapIDs  = { 2574 },  -- 2574 = sub-zone
        name       = "Voidscar Arena",
        location   = "Voidstorm",
        season     = "midnight",
        type       = "max",
        mythicPlus = false,
        bosses = {
            { encounterID = 3285, name = "Taz'Rah",  tip = "Stay out of Dark Rift gravity pull; dodge shade Nether Dash lines." },
            { encounterID = 3286, name = "Atroxus",  tip = "Avoid Noxious Breath frontal; when Toxic Creepers fixate on a player, that player and nearby allies spread out to avoid the 8-yard toxic aura." },
            { encounterID = 3287, name = "Charonus", tip = "Lead Gravitic Orbs into Singularities to consume them; avoid the Unstable Singularity gravity well." },
        },
    },

    -- --------------------------------------------------------
    -- SEASON 1 MYTHIC+ — Legacy Dungeons
    -- --------------------------------------------------------
    {
        instanceID = 0,     -- TODO: source from LittleWigs
        uiMapID    = 2526,  -- unverified in-game
        name       = "Algeth'ar Academy",
        location   = "Thaldraszus",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses = {
            { encounterID = 0, name = "Overgrown Ancient", tip = "Dodge Burst Pods; free allies from Germinate roots; interrupt Lumbering Swipe." },
            { encounterID = 0, name = "Crawth",            tip = "Interrupt Screech; spread for quill barrage; kill wind adds quickly." },
            { encounterID = 0, name = "Vexamus",           tip = "Interrupt Spellvoid; dodge Overloaded explosions; spread Arcane Puddle soaks." },
            { encounterID = 0, name = "Echo of Doragosa",  tip = "Spread for Astral Breath; interrupt Nullifying Pulse; dodge Arcane Rifts." },
        },
    },
    {
        instanceID = 0,    -- TODO: source from LittleWigs
        uiMapID    = 658,  -- unverified in-game
        name       = "Pit of Saron",
        location   = "Icecrown",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses = {
            { encounterID = 0, name = "Forgemaster Garfrost", tip = "LoS boss behind ice boulders to shed Permafrost stacks before they stack too high." },
            { encounterID = 0, name = "Ick & Krick",          tip = "Run from Ick during Pursuit; spread for Explosive Barrage." },
            { encounterID = 0, name = "Scourgelord Tyrannus", tip = "Dodge Overlord's Brand; spread to avoid chained Unholy Power debuffs." },
        },
    },
    {
        instanceID = 0,     -- TODO: source from LittleWigs
        uiMapID    = 1753,  -- unverified in-game
        name       = "Seat of the Triumvirate",
        location   = "Argus",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses = {
            { encounterID = 0, name = "Zuraal the Ascended", tip = "Step through void portals immediately when teleported to avoid damage." },
            { encounterID = 0, name = "Saprish",             tip = "Kill Darkfang before Saprish's energy caps; boss is vulnerable without his pet." },
            { encounterID = 0, name = "Viceroy Nezhar",      tip = "Interrupt Dark Bulwark; dodge Void Lashing tentacle swipes." },
            { encounterID = 0, name = "L'ura",               tip = "Collect soul fragments promptly; avoid standing in void pools." },
        },
    },
    {
        instanceID = 0,     -- TODO: source from LittleWigs
        uiMapID    = 1209,  -- unverified in-game
        name       = "Skyreach",
        location   = "Spires of Arak",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses = {
            { encounterID = 0, name = "Ranjit",          tip = "Hide behind wind barriers for Fan of Blades; interrupt Four Winds." },
            { encounterID = 0, name = "Araknath",        tip = "Dodge Burn ground fissures; spread to reduce Solarflare chain damage." },
            { encounterID = 0, name = "Rukhran",         tip = "Burn Spire Eagle adds fast; stay out of Solar Breath frontal cone." },
            { encounterID = 0, name = "High Sage Viryx", tip = "Interrupt Lens Flare; kill Initiates before they carry players off the platform." },
        },
    },
}

-- ============================================================
-- Runtime lookups — built at load time for O(1) identification
-- ============================================================

-- Primary: instanceID (GetInstanceInfo() 8th return) → dungeon
KwikTip.DUNGEON_BY_INSTANCEID = {}
for _, dungeon in ipairs(KwikTip.DUNGEONS) do
    if dungeon.instanceID ~= 0 then
        KwikTip.DUNGEON_BY_INSTANCEID[dungeon.instanceID] = dungeon
    end
end

-- Fallback: uiMapID (C_Map.GetBestMapForUnit) → dungeon
-- Also used for position queries (C_Map.GetPlayerMapPosition requires a uiMapID).
KwikTip.DUNGEON_BY_UIMAPID = {}
for _, dungeon in ipairs(KwikTip.DUNGEONS) do
    if dungeon.uiMapID ~= 0 then
        KwikTip.DUNGEON_BY_UIMAPID[dungeon.uiMapID] = dungeon
    end
    if dungeon.altMapIDs then
        for _, id in ipairs(dungeon.altMapIDs) do
            KwikTip.DUNGEON_BY_UIMAPID[id] = dungeon
        end
    end
end

-- Trash mob lookup: npcID (from UnitGUID) → { dungeon, mob }
KwikTip.TRASH_BY_NPCID = {}
for _, dungeon in ipairs(KwikTip.DUNGEONS) do
    if dungeon.trash then
        for _, mob in ipairs(dungeon.trash) do
            KwikTip.TRASH_BY_NPCID[mob.npcID] = { dungeon = dungeon, mob = mob }
        end
    end
end

-- Boss lookup: encounterID (ENCOUNTER_START event) → { dungeon, boss }
KwikTip.BOSS_BY_ENCOUNTERID = {}
for _, dungeon in ipairs(KwikTip.DUNGEONS) do
    for _, boss in ipairs(dungeon.bosses) do
        if boss.encounterID ~= 0 then
            KwikTip.BOSS_BY_ENCOUNTERID[boss.encounterID] = { dungeon = dungeon, boss = boss }
        end
    end
end
