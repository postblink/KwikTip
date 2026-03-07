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
--     npcID       : (optional) NPC ID from UnitGUID; enables tip on targeting before ENCOUNTER_START fires.
--                   Source from Wowhead. Required for boss rooms with no subzone text.
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
--     bossIndex : (optional) 1-based index into dungeon.bosses; if set, the boss tip is
--                 shown instead of `tip` — use for boss room sub-zones so the tip appears
--                 on entry rather than waiting for ENCOUNTER_START
--
-- Season 1 M+ rotation (8 dungeons total):
--   New Midnight: Magisters' Terrace, Maisara Caverns, Nexus-Point Xenas, Windrunner Spire
--   Legacy:       Algeth'ar Academy, Pit of Saron, Seat of the Triumvirate, Skyreach

KwikTip.DUNGEONS = {

    -- --------------------------------------------------------
    -- NEW MIDNIGHT DUNGEONS — Level-Up (81–88)
    -- --------------------------------------------------------
    {
        instanceID = 2805,  -- confirmed in-game
        uiMapID    = 2492,  -- confirmed in-game
        altMapIDs  = { 2537, 2493, 2494, 2496, 2497, 2498, 2499 },  -- all confirmed in-game
        name       = "Windrunner Spire",
        location   = "Eversong Woods",
        season     = "midnight",
        type       = "level",
        mythicPlus = true,
        bosses = {
            { encounterID = 3056, name = "Emberdawn",          tip = "Tank in corner; players hit by Flaming Updraft drop it near the corner and use a personal defensive; dodge Twisters spawned from puddles; healer major CDs on Burning Gale." },
            { encounterID = 3057, name = "Derelict Duo",       tip = "Keep both at equal health — Broken Bond enrages the survivor if one dies first; interrupt Shadow Bolt and dispel Curse of Darkness; tank active mitigation for Bone Hack; Latch's Heaving Yank auto-cancels Kalis's Debilitating Shriek (you can't interrupt it yourself)." },
            { encounterID = 3058, name = "Commander Kroluk",   tip = "Burn adds at 66%/33%; boss immune (Shield Wall) until warparty dies; stay grouped — Intimidating Shout fears isolated players." },
            { encounterID = 3059, name = "The Restless Heart", tip = "Dodge Arrow Rain; sidestep targeted Bolt Gale; at 100 energy, boss fires wind arrow spawning expanding Billowing Wind rings — stay out; never touch Turbulent Arrows (knockup + removes Squall Leap)." },
        },
        trash = {
            { npcID = 232070, name = "Restless Steward",   tip = "Interrupt Spirit Bolt; use stops on Soul Torment to cancel the channel." },
            { npcID = 232113, name = "Spellguard Magus",   tip = "Defensives for Arcane Salvo; knock mobs out of Spellguard's Protection sphere — it makes them immune to damage." },
            { npcID = 232067, name = "Creeping Spindleweb", tip = "Poison Spray — use a personal defensive." },
        },
        areas = {
            { subzone = "Vereesa's Repose",    bossIndex = 1 },  -- wing bosses (Emberdawn + Derelict Duo share this subzone); confirmed in-game; bossIndex=1 shows Emberdawn tip on entry — ENCOUNTER_START overrides for Derelict Duo
            { subzone = "Windrunner Vault",    bossIndex = 3 },  -- Commander Kroluk's arena; confirmed in-game
            { subzone = "The Pinnacle",        bossIndex = 4 },  -- The Restless Heart; confirmed in-game
        },
    },
    {
        instanceID = 2813,  -- confirmed in-game
        uiMapID    = 2433,  -- confirmed in-game
        altMapIDs  = { 2435, 2434 },  -- confirmed in-game
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
        areas = {
            { subzone = "Silvermoon Pet Shop", bossIndex = 1 },  -- Kystia Manaheart; confirmed in-game
            { subzone = "The Illicit Rain",    bossIndex = 2 },  -- Zaen Bladesorrow; confirmed in-game
            { subzone = "Augurs' Terrace",     bossIndex = 3 },  -- Xathuux the Annihilator; confirmed in-game
            { subzone = "Lithiel's Landing",   bossIndex = 4 },  -- Lithiel Cinderfury; confirmed in-game
        },
    },
    {
        instanceID = 2825,  -- BigWigs, unverified in-game
        uiMapID    = 2514,
        altMapIDs  = { 2564, 2513 },  -- 2564 = Dreamer's Passage/Heart of Rage; 2513 = Heart of Rage (confirmed in-game)
        name       = "Den of Nalorakk",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses = {
            { encounterID = 3207, name = "The Hoardmonger",    tip = "At 90%/60%/30%, boss retreats to empower; destroy Rotten Mushrooms before burst (Toxic Spores debuff); dodge frontals." },
            { encounterID = 3208, name = "Sentinel of Winter", tip = "Dodge Raging Squalls and Snowdrift pools; major healer CDs for Eternal Winter — sustained group damage and pushback." },
            { encounterID = 3209, name = "Nalorakk",           tip = "Fury of the War God: intercept charging echoes to protect Zul'jarra; spread when Echoing Maul marks you." },
        },
        areas = {
            { subzone = "Enduring Winter",   bossIndex = 1 },  -- first two bosses share this subzone (Hoardmonger + Sentinel of Winter); confirmed in-game (mapID 2514); bossIndex=1 shows Hoardmonger tip on entry — ENCOUNTER_START overrides for Sentinel of Winter
            { subzone = "The Heart of Rage", bossIndex = 3 },  -- Nalorakk's arena; confirmed in-game (mapIDs 2564, 2513)
        },
    },
    {
        instanceID = 2874,  -- confirmed in-game
        uiMapID    = 2501,  -- confirmed in-game
        name       = "Maisara Caverns",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = true,
        bosses = {
            { encounterID = 3212, name = "Muro'jin and Nekraxx",     tip = "Kill simultaneously — Muro'jin dies first: Nekraxx enrages (Bestial Wrath); Nekraxx dies first: Muro'jin revives him. Use Freezing Trap victims to interrupt Nekraxx's Carrion Swoop." },
            { encounterID = 3213, name = "Vordaza",                  tip = "Burst the Deathshroud shield during Necrotic Convergence with damage CDs; kite Unstable Phantoms into each other to detonate them — killing them directly applies Lingering Dread to the group; dodge Unmake line." },
            { encounterID = 3214, name = "Rak'tul, Vessel of Souls", tip = "In spirit realm: interrupt Malignant Souls for Spectral Residue (+25% dmg/heal/speed); avoid Restless Masses roots. Destroy Crush Souls totems before returning." },
        },
        trash = {
            { npcID = 242964, name = "Keen Headhunter",   tip = "Interrupt Hooked Snare. If it lands, use a freedom effect to clear the root and bleed." },
            { npcID = 248686, name = "Dread Souleater",   tip = "Avoid Rain of Toads pools. Defensives for Necrotic Wave — it leaves a healing absorb on hit players." },
            { npcID = 248685, name = "Ritual Hexxer",     tip = "Interrupt Hex first. Use spare kicks on Shadow Bolt." },
            { npcID = 248678, name = "Hulking Juggernaut", tip = "Defensive before Deafening Roar lands — it spell-locks anyone mid-cast. Tank watch Rending Gore bleed stacks." },
            { npcID = 249020, name = "Hexbound Eagle",    tip = "Sidestep Shredding Talons — step to the side of the eagle as it winds up." },
            { npcID = 249022, name = "Bramblemaw Bear",   tip = "Crunch Armor stacks per bear — avoid pulling multiple bears simultaneously; rotate defensive cooldowns." },
            { npcID = 248692, name = "Reanimated Warrior", tip = "CC or stop Reanimation at 0 HP or it revives. Any crowd-control effect works." },
            { npcID = 248690, name = "Grim Skirmisher",   tip = "Grim Ward shield: don't purge multiple at once — each break hits the whole group. Stagger dispels." },
            { npcID = 249030, name = "Restless Gnarldin",  tip = "Out-range Ancestral Crush. Spectral Strike autos deal shadow — healer watch sustained damage." },
            { npcID = 249036, name = "Tormented Shade",   tip = "Interrupt Spirit Rend. Dispel the magic DoT if the kick was missed." },
            { npcID = 253683, name = "Rokh'zal",          tip = "Ritual Sacrifice chains an ally to an altar — break the shackles to free them; freedom effects also work." },
            { npcID = 249025, name = "Bound Defender",    tip = "Attack from behind to bypass Vigilant Defense frontal immunity. Dodge Soulstorm tornadoes." },
            { npcID = 249024, name = "Hollow Soulrender",  tip = "Interrupt Shadowfrost Blast. Step away from allies before Frost Nova hits — it chains to nearby players." },
        },
        areas = {
            { subzone = "Wailing Depths",    bossIndex = 1 },  -- Muro'jin and Nekraxx; confirmed in-game
            { subzone = "Dais of Suffering", bossIndex = 2 },  -- Vordaza's arena; confirmed in-game
            { subzone = "Echoing Span",      bossIndex = 3 },  -- Rak'tul's arena; gauntlet runs during the fight (spirit realm bridge); confirmed in-game
        },
    },

    -- --------------------------------------------------------
    -- NEW MIDNIGHT DUNGEONS — Max Level (88–90)
    -- --------------------------------------------------------
    {
        instanceID = 2811,  -- confirmed in-game
        uiMapID    = 2511,  -- confirmed in-game
        altMapIDs  = { 2424, 2515, 2516, 2517, 2519, 2520 },  -- all confirmed in-game except 2424
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
        areas = {
            { subzone = "Observation Grounds",   bossIndex = 1 },  -- Arcanotron Custos; confirmed in-game
            { subzone = "Grand Magister Asylum",  bossIndex = 2 },  -- Seranel Sunlash; confirmed in-game
            { subzone = "Constellarium",         bossIndex = 3 },  -- Gemellus; confirmed in-game
            { subzone = "Celestial Orrery",      bossIndex = 4 },  -- Degentrius; confirmed in-game
        },
    },
    {
        instanceID = 2915,  -- confirmed in-game
        uiMapID    = 2556,  -- confirmed in-game
        name       = "Nexus-Point Xenas",
        location   = "Voidstorm",
        season     = "midnight",
        type       = "max",
        mythicPlus = true,
        bosses = {
            { encounterID = 3328, name = "Chief Corewright Kasreth", tip = "Never cross active Leyline Arrays — lethal. When targeted by Reflux Charge, use it to destroy a nearby array for bonus damage." },
            { encounterID = 3332, name = "Corewarden Nysarra",       tip = "Kill Null Vanguard adds before Lightscar Flare; then stand in the wound during 18s stun for 300% damage." },
            { encounterID = 3333, name = "Lothraxion",               tip = "At 100 energy, find and interrupt the real Lothraxion among his images — he's the only one without glowing horns; wrong target = Core Exposure (group damage + 20% increased Holy damage taken for 1 min)." },
        },
        trash = {
            { npcID = 241643, name = "Shadowguard Defender",  tip = "Null Sunder stacks per Defender active — control pull size; tank rotate or pop a cooldown on high-stack groups." },
            { npcID = 241647, name = "Flux Engineer",          tip = "Interrupt Erratic Surge before it fires — random-target bolts that chain to nearby allies." },
            { npcID = 248708, name = "Nexus Adept",            tip = "Interrupt Umbra Bolt — high-damage shadow nuke; use a stun or stop if interrupt is on cooldown." },
            { npcID = 248373, name = "Circuit Seer",           tip = "Top interrupt priority — Mana Battery channel deals a sustained group DoT for its full duration." },
            { npcID = 248706, name = "Cursed Voidcaller",      tip = "Interrupt the summon channel or kill quickly — Void Gate calls additional adds if it completes." },
            { npcID = 251853, name = "Grand Nullifier",        tip = "Interrupt Null Pulse to prevent party-wide silence; its Nullification aura passively reduces healing output." },
            { npcID = 241660, name = "Duskfright Herald",      tip = "Dark Beckoning frontal is lethal — step out of the cone the instant the cast begins." },
            { npcID = 251024, name = "Dreadflail",             tip = "Corewarden Nysarra add — kill before burning the boss; Lightscar wound opens the 18s vulnerability window after." },
        },
        areas = {
            { subzone = "Corespark Engineway",    bossIndex = 1 },  -- Chief Corewright Kasreth; confirmed in-game
            { subzone = "Core Defense Nullward",  bossIndex = 2 },  -- Corewarden Nysarra; confirmed in-game
            { subzone = "The Nexus Core",         bossIndex = 3 },  -- Lothraxion's boss room; confirmed in-game
        },
    },
    {
        instanceID = 2859,  -- confirmed in-game
        uiMapID    = 2500,  -- confirmed in-game
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
        areas = {
            { subzone = "The Luminous Garden",  bossIndex = 1 },  -- Lightblossom Trinity; confirmed in-game
            { subzone = "The Gilded Tangle",    bossIndex = 2 },  -- Ikuzz the Light Hunter; confirmed in-game
            { subzone = "Warden's Retreat",     bossIndex = 3 },  -- Lightwarden Ruia; confirmed in-game
            { subzone = "Conviction's Crucible", bossIndex = 4 }, -- Ziekket; confirmed in-game
        },
    },
    {
        instanceID = 2923,  -- confirmed in-game
        uiMapID    = 2572,  -- confirmed in-game
        altMapIDs  = { 2573, 2574 },  -- 2573/2574 = confirmed in-game sub-zones
        name       = "Voidscar Arena",
        location   = "Voidstorm",
        season     = "midnight",
        type       = "max",
        mythicPlus = false,
        bosses = {
            { encounterID = 3285, name = "Taz'Rah",  tip = "Stay out of Dark Rift gravity pull; dodge shade Nether Dash lines." },
            { encounterID = 3286, name = "Atroxus",  npcID = 239008, tip = "Avoid Noxious Breath frontal; when Toxic Creepers fixate on a player, that player and nearby allies spread out to avoid the 8-yard toxic aura." },
            { encounterID = 3287, name = "Charonus", npcID = 248015, tip = "Lead Gravitic Orbs into Singularities to consume them; avoid the Unstable Singularity gravity well." },
        },
        areas = {
            { subzone = "The Den", bossIndex = 1 },  -- Taz'Rah's arena; confirmed in-game
        },
    },

    -- --------------------------------------------------------
    -- SEASON 1 MYTHIC+ — Legacy Dungeons
    -- --------------------------------------------------------
    {
        instanceID = 2526,  -- BigWigs Loader.lua
        uiMapID    = 0,     -- TODO: verify in-game with /run print(C_Map.GetBestMapForUnit("player"))
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
        instanceID = 658,  -- BigWigs Loader.lua
        uiMapID    = 0,    -- TODO: verify in-game with /run print(C_Map.GetBestMapForUnit("player"))
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
        instanceID = 1753,  -- BigWigs Loader.lua
        uiMapID    = 0,     -- TODO: verify in-game with /run print(C_Map.GetBestMapForUnit("player"))
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
        instanceID = 1209,  -- BigWigs Loader.lua
        uiMapID    = 0,     -- TODO: verify in-game with /run print(C_Map.GetBestMapForUnit("player"))
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

-- Boss NPC lookup: npcID → { dungeon, boss }
-- Fallback for rooms where ENCOUNTER_START hasn't fired yet and no subzone text exists.
-- Populated from boss entries that have an npcID field (sourced from Wowhead).
KwikTip.BOSS_BY_NPCID = {}
for _, dungeon in ipairs(KwikTip.DUNGEONS) do
    for _, boss in ipairs(dungeon.bosses) do
        if boss.npcID and boss.npcID ~= 0 then
            KwikTip.BOSS_BY_NPCID[boss.npcID] = { dungeon = dungeon, boss = boss }
        end
    end
end
