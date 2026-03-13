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
--     tip         : short contextual tip shown in the HUD during the boss fight (flat string; legacy/fallback)
--     notes       : (optional) structured role-aware notes; if present, replaces `tip` in the HUD.
--                   Each entry: { role = "general"|"tank"|"healer"|"dps"|"interrupt", text = "..." }
--                   Rendered with role-colored icon prefixes (tank=blue, healer=green, dps=orange,
--                   interrupt=gold). `tip` is kept alongside for reference during migration.
--   trash       : optional list of notable trash mobs; PLAYER_TARGET_CHANGED shows tip on match
--     npcID     : numeric NPC ID extracted from UnitGUID("target"):match("-(%d+)-%x+$")
--     name      : mob display name
--     tip       : contextual tip shown in HUD when this mob is targeted (flat string; legacy/fallback)
--     notes     : (optional) structured role-aware notes; same format as boss notes above
--   areas       : optional list; if present, HUD switches to area-based tips
--                 matched against GetSubZoneText() as the player moves through the dungeon
--     subzone   : exact string returned by GetSubZoneText() for this area (verify in-game)
--     mapID     : (optional) uiMapID match via C_Map.GetBestMapForUnit — fallback for areas
--                 with no subzone text (e.g. arena-style dungeons). Fires on ZONE_CHANGED_NEW_AREA.
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
            {
                encounterID = 3056,  -- confirmed in-game
                name        = "Emberdawn",
                tip         = "Drop Flaming Updraft puddles at the room's outer edges; play close to the boss during Burning Gale (16s) to minimize movement when dodging Twisters and Fire Breath frontals; healer major CDs on Burning Gale.",
                notes = {
                    { role = "general",   text = "Drop Flaming Updraft puddles at the room's outer edges." },
                    { role = "general",   text = "During Burning Gale (16s) stay close to the boss — dodge Twisters and Fire Breath frontals." },
                    { role = "healer",    text = "Major CDs on Burning Gale." },
                },
            },
            {
                encounterID = 3057,  -- confirmed in-game
                name        = "Derelict Duo",
                tip         = "Keep both at equal health — Broken Bond enrages the survivor; interrupt Shadow Bolt; dispel Curse of Darkness to despawn Dark Entity adds; tank defensive for Bone Hack and Splattering Spew (drops puddles — spread loosely); stand behind Kalis so Latch's Heaving Yank pulls her and cancels Debilitating Shriek.",
                notes = {
                    { role = "general",   text = "Keep both at equal health — Broken Bond enrages the survivor." },
                    { role = "general",   text = "Stand behind Kalis so Latch's Heaving Yank cancels Debilitating Shriek." },
                    { role = "tank",      text = "Defensive for Bone Hack and Splattering Spew (spread loosely — drops puddles)." },
                    { role = "healer",    text = "Dispel Curse of Darkness — despawns Dark Entity adds." },
                    { role = "interrupt", text = "Shadow Bolt." },
                },
            },
            {
                encounterID = 3058,  -- confirmed in-game
                name        = "Commander Kroluk",
                tip         = "Reckless Leap targets furthest player — stack in melee with one defensive player baiting it; stay near an ally or Intimidating Shout fears you; at 66%/33% kill adds (interrupt Phantasmal Mystic at 50% or it enrages the pull).",
                notes = {
                    { role = "general",   text = "Stack in melee — Reckless Leap targets the furthest player; one player baits it with a defensive." },
                    { role = "general",   text = "Stay near an ally or Intimidating Shout fears you." },
                    { role = "dps",       text = "At 66%/33% kill adds fast." },
                    { role = "interrupt", text = "Phantasmal Mystic adds at 50% — interrupt or they enrage." },
                },
            },
            {
                encounterID = 3059,  -- confirmed in-game
                name        = "The Restless Heart",
                tip         = "Manage Squall Leap DoT stacks — step on Turbulent Arrows to clear them and to vault over Bullseye Windblast shockwave at 100 energy; dodge Bolt Gale frontal; tank use defensive for Tempest Slash knockback and damage-taken amp.",
                notes = {
                    { role = "general",   text = "Step on Turbulent Arrows to clear Squall Leap DoT stacks and to vault over Bullseye Windblast shockwave at 100 energy." },
                    { role = "general",   text = "Dodge Bolt Gale frontal." },
                    { role = "tank",      text = "Defensive for Tempest Slash — knockback + damage-taken amp." },
                },
            },
        },
        trash = {
            { npcID = 232070, name = "Restless Steward",   tip = "Interrupt Spirit Bolt; Magic dispel Soul Torment on debuffed players ASAP, then use defensives or focus healing for the remaining player." },
            { npcID = 232113, name = "Spellguard Magus",   tip = "Defensives for Arcane Salvo; at 50% it drops a Spellguard's Protection zone (99% DR) — tank move the mob and any other mobs out of it immediately." },
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
        altMapIDs  = { 2435, 2434, 2393 },  -- confirmed in-game; 2393 = Silvermoon City entrance plaza (pre-zone-in)
        name       = "Murder Row",
        location   = "Silvermoon City",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses = {
            {
                encounterID = 3101,  -- confirmed in-game
                npcID       = 252458,
                name        = "Kystia Manaheart",
                tip         = "Dispel Illicit Infusion from Nibbles for 15s stun + 100% dmg window — Kystia radiates Chaos AoE during this phase so healer CDs needed; dodge Nibbles' Fel Spray cone while she's hostile; purge Felshield (80% DR) when Kystia casts it; interrupt Mirror Images.",
                notes = {
                    { role = "healer",    text = "Dispel Illicit Infusion from Nibbles — triggers 15s stun and 100% dmg window; major CDs during this phase (Chaos AoE)." },
                    { role = "general",   text = "Dodge Nibbles' Fel Spray cone while she's hostile; purge Felshield when Kystia casts it (80% DR)." },
                    { role = "interrupt", text = "Mirror Images." },
                },
            },
            {
                encounterID = 3102,  -- confirmed in-game
                name        = "Zaen Bladesorrow",
                tip         = "Stand behind Forbidden Freight during Murder in a Row; move Fire Bomb away from freight (it destroys cover); Heartstop Poison halves tank max health — prioritize tank healing.",
                notes = {
                    { role = "general",   text = "Stand behind Forbidden Freight during Murder in a Row; move Fire Bomb away from freight — it destroys cover." },
                    { role = "tank",      text = "Heartstop Poison halves your max health — call for an external." },
                    { role = "healer",    text = "Prioritize tank healing after Heartstop Poison." },
                },
            },
            {
                encounterID = 3103,  -- confirmed in-game
                name        = "Xathuux the Annihilator",
                tip         = "At 100 energy, Demonic Rage pulses heavy group AoE and buffs boss attack speed — use defensives and healer CDs. Dodge Axe Toss impact zones (Fel Light persists on ground); avoid Burning Steps hazards. Tank: Legion Strike applies 80% healing reduction — call for an external.",
                notes = {
                    { role = "general",   text = "Dodge Axe Toss impact zones (Fel Light persists); avoid Burning Steps." },
                    { role = "tank",      text = "Legion Strike applies 80% healing reduction — call for an external immediately." },
                    { role = "healer",    text = "Major CDs during Demonic Rage (100 energy) — heavy group AoE + boss attack speed buff." },
                },
            },
            {
                encounterID = 3105,  -- confirmed in-game
                name        = "Lithiel Cinderfury",
                tip         = "Kill Wild Imps before Malefic Wave reaches them (they gain haste if hit); use Gateways to avoid the wave; interrupt Chaos Bolt.",
                notes = {
                    { role = "general",   text = "Use Gateways to avoid Malefic Wave." },
                    { role = "dps",       text = "Kill Wild Imps before the wave reaches them — they gain haste if hit." },
                    { role = "interrupt", text = "Chaos Bolt." },
                },
            },
        },
        areas = {
            { subzone = "Silvermoon Pet Shop", bossIndex = 1 },  -- Kystia Manaheart; confirmed in-game
            { subzone = "The Illicit Rain",    bossIndex = 2 },  -- Zaen Bladesorrow; confirmed in-game
            { subzone = "Augurs' Terrace",     bossIndex = 3 },  -- Xathuux the Annihilator; confirmed in-game
            { subzone = "Lithiel's Landing",   bossIndex = 4 },  -- Lithiel Cinderfury; confirmed in-game
        },
    },
    {
        instanceID = 2825,  -- confirmed in-game
        uiMapID    = 2514,
        altMapIDs  = { 2564, 2513 },  -- 2564 = Dreamer's Passage/Heart of Rage; 2513 = Heart of Rage (confirmed in-game)
        name       = "Den of Nalorakk",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses = {
            {
                encounterID = 3207,  -- confirmed in-game
                npcID       = 248710,
                name        = "The Hoardmonger",
                tip         = "At 90%/60%/30%, boss retreats to empower; destroy Rotten Mushrooms before burst; healer dispel Toxic Spores; dodge frontals.",
                notes = {
                    { role = "general",   text = "At 90%/60%/30% boss retreats to empower — dodge frontals." },
                    { role = "dps",       text = "Destroy Rotten Mushrooms before each burst phase." },
                    { role = "healer",    text = "Dispel Toxic Spores debuff." },
                },
            },
            {
                encounterID = 3208,  -- confirmed in-game
                npcID       = 261053,
                name        = "Sentinel of Winter",
                tip         = "Dodge Raging Squalls and Snowdrift pools; at 100 energy boss channels Eternal Winter (shields self + heavy group damage) — use damage CDs to break the shield fast, healer CDs to survive.",
                notes = {
                    { role = "general",   text = "Dodge Raging Squalls and Snowdrift pools." },
                    { role = "dps",       text = "At 100 energy, burn the Eternal Winter shield fast with damage CDs." },
                    { role = "healer",    text = "CDs during Eternal Winter — heavy group damage while the shield is active." },
                },
            },
            {
                encounterID = 3209,  -- confirmed in-game
                name        = "Nalorakk",
                tip         = "Fury of the War God: intercept charging echoes to protect Zul'jarra — echoes that reach her deal massive group damage; spread when Echoing Maul marks you.",
                notes = {
                    { role = "general",   text = "Intercept charging echoes (Fury of the War God) — echoes reaching Zul'jarra deal massive group damage." },
                    { role = "general",   text = "Spread when Echoing Maul marks you." },
                },
            },
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
            {
                encounterID = 3212,
                name        = "Muro'jin and Nekraxx",
                tip         = "Keep equal health — if Nekraxx dies first Muro'jin revives him at 35%; if Muro'jin dies first Nekraxx gains 20% dmg every 4s (stacking). Carrion Swoop target: step into a Freezing Trap to block the charge and stun Nekraxx 5s. Barrage: targeted player stand still. Dispel Infected Pinions disease.",
                notes = {
                    { role = "general",   text = "Keep equal health — if Nekraxx dies first Muro'jin revives him at 35%; if Muro'jin dies first Nekraxx gains +20% damage every 4s (continuously stacking)." },
                    { role = "general",   text = "Carrion Swoop target: step into a Freezing Trap to block the charge and stun Nekraxx 5s." },
                    { role = "general",   text = "Barrage targets a player — that player stands still." },
                    { role = "healer",    text = "Dispel Infected Pinions disease." },
                },
            },
            {
                encounterID = 3213,
                name        = "Vordaza",
                tip         = "Burst the Deathshroud shield during Necrotic Convergence with damage CDs; kite Unstable Phantoms into each other to detonate them — killing them directly applies Lingering Dread to the group; dodge Unmake line. Tank: defensive for Drain Soul channel.",
                notes = {
                    { role = "general",   text = "Kite Unstable Phantoms into each other to detonate — killing directly applies Lingering Dread to the group; dodge Unmake line." },
                    { role = "dps",       text = "Burst the Deathshroud shield during Necrotic Convergence with damage CDs." },
                    { role = "tank",      text = "Defensive for Drain Soul channel." },
                },
            },
            {
                encounterID = 3214,
                name        = "Rak'tul, Vessel of Souls",
                tip         = "In spirit realm: interrupt Malignant Souls for Spectral Residue (+25% dmg/heal/speed) — kill the first 5 quickly, then delay the 6th soul to maximize buff duration back in the boss phase; avoid Restless Masses roots; cleave Crush Souls totems before returning.",
                notes = {
                    { role = "general",   text = "In spirit realm: kill first 5 Malignant Souls quickly, then delay the 6th to maximize Spectral Residue buff duration on return." },
                    { role = "general",   text = "Avoid Restless Masses roots; cleave Crush Souls totems before returning." },
                    { role = "interrupt", text = "Malignant Souls (spirit realm) — grants Spectral Residue (+25% dmg/heal/speed)." },
                },
            },
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
            {
                encounterID = 3071,  -- confirmed in-game
                name        = "Arcanotron Custos",
                tip         = "Intercept orbs before they reach the boss — boss is 20% more vulnerable during intermission; save offensive CDs for this window. Avoid Arcane Residue zones; tank defensive for Repulsing Slam.",
                notes = {
                    { role = "general",   text = "Intercept orbs before they reach the boss; avoid Arcane Residue zones." },
                    { role = "dps",       text = "Boss takes 20% increased damage during intermission — save offensive CDs for this window." },
                    { role = "tank",      text = "Defensive for Repulsing Slam." },
                },
            },
            {
                encounterID = 3072,  -- confirmed in-game
                name        = "Seranel Sunlash",
                tip         = "Purge Hastening Ward magic buff from the boss when it appears. At 100 energy, step inside a Suppression Zone before Wave of Silence finishes or you're pacified for 8s. Step into a zone to resolve Runic Mark (Feedback) — but zones purge your buffs.",
                notes = {
                    { role = "general",   text = "At 100 energy, be inside a Suppression Zone before Wave of Silence finishes or you're pacified for 8s." },
                    { role = "general",   text = "Step into a zone to resolve Runic Mark (Feedback) — zones purge your buffs." },
                    { role = "general",   text = "Purge Hastening Ward from the boss." },
                },
            },
            {
                encounterID = 3073,  -- confirmed in-game
                name        = "Gemellus",
                tip         = "All copies share health. Neural Link: follow the arrow indicator to your correct clone and touch it — Astral Grasp pulls you toward the clones so you must fight the pull-in.",
                notes = {
                    { role = "general",   text = "All copies share health; follow Neural Link's arrow indicator to find your correct clone and touch it." },
                    { role = "general",   text = "Astral Grasp pulls players toward the clones — fight the pull-in while navigating." },
                },
            },
            {
                encounterID = 3074,  -- confirmed in-game
                name        = "Degentrius",
                tip         = "One player per quadrant soaks Unstable Void Essence as it bounces — missing applies a 40s DoT to the group. Tank: step back out of melee for Hulking Fragment DoT dispel (drops a puddle). Never stand in Void Torrent beams — they stun.",
                notes = {
                    { role = "general",   text = "One player per quadrant soaks Unstable Void Essence as it bounces — missing applies a 40s DoT to the group." },
                    { role = "general",   text = "Never stand in Void Torrent beams — they stun." },
                    { role = "tank",      text = "Step back out of melee for Hulking Fragment DoT dispel — drops a puddle." },
                },
            },
        },
        trash = {
            { npcID = 257644, name = "Arcane Magister",     tip = "Top interrupt priority — Polymorph targets a random player; dispel if it lands." },
            { npcID = 234486, name = "Lightward Healer",    tip = "Dispel Holy Fire; purge Power Word: Shield from allies." },
            { npcID = 251917, name = "Animated Codex",      tip = "Arcane Volley pulses constant AoE — limit pull size and prepare healing cooldowns." },
            { npcID = 257161, name = "Blazing Pyromancer",  tip = "Interrupt every Pyroblast; use defensives during Ignition; avoid Flamestrike." },
            { npcID = 24761,  name = "Brightscale Wyrm",    tip = "Stagger kills — Energy Release fires on death; killing simultaneously overwhelms the group." },
            { npcID = 234068, name = "Shadowrift Voidcaller", tip = "Use healing cooldowns or line of sight when it casts Consuming Shadows; kill spawned adds from Call of the Void." },
            { npcID = 249086, name = "Void Infuser",        tip = "Interrupt Terror Wave every cast; dispel or use a defensive for Consuming Void debuff." },
            { npcID = 234066, name = "Devouring Tyrant",    tip = "Tank uses defensive and self-healing for Devouring Strike (healing absorb); all players defensive for Void Bomb absorb." },
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
            {
                encounterID = 3328,  -- confirmed in-game
                name        = "Chief Corewright Kasreth",
                tip         = "Don't cross Leyline Arrays (damage + slow). When targeted by Reflux Charge, touch an array intersection to destroy it and open space. At full energy: Corespark Detonation — massive knockback + healing absorb DoT on target; party-wide Sparkburn follows — healer CDs.",
                notes = {
                    { role = "general",   text = "Don't cross Leyline Arrays (damage + slow); if targeted by Reflux Charge, touch an intersection to destroy it and open space." },
                    { role = "general",   text = "At full energy: Corespark Detonation — massive knockback + healing absorb DoT; don't get knocked into puddles." },
                    { role = "healer",    text = "CDs after Corespark Detonation — party-wide Sparkburn DoT follows immediately." },
                },
            },
            {
                encounterID = 3332,  -- confirmed in-game
                name        = "Corewarden Nysarra",
                tip         = "Avoid Lothraxion's beam during Lightscar Flare; stand in the boss's frontal cone during the 18s stun for 300% damage amp (30% healing amp too). Kill Null Vanguard adds before the stun ends — add kill order: Dreadflail first, then interrupt Grand Nullifiers (Nullify), then cleave Haunting Grunts.",
                notes = {
                    { role = "general",   text = "Avoid Lothraxion's beam during Lightscar Flare." },
                    { role = "dps",       text = "Stand in the boss's frontal cone during the 18s stun for 300% damage amp; kill adds before stun ends — Dreadflail → interrupt Grand Nullifiers → cleave Haunting Grunts." },
                    { role = "healer",    text = "30% healing amp is active during the stun — use CDs." },
                },
            },
            {
                encounterID = 3333,  -- confirmed in-game
                name        = "Lothraxion",
                tip         = "At 100 energy, find and interrupt the real Lothraxion among his images — he's the only one without glowing horns; wrong target = Core Exposure (group damage + 20% increased Holy damage taken for 1 min). Spread 8 yards for Brilliant Dispersion.",
                notes = {
                    { role = "interrupt", text = "At 100 energy, find and interrupt the real Lothraxion — no glowing horns; wrong target = Core Exposure (group damage + 20% Holy taken for 1 min)." },
                    { role = "general",   text = "Spread 8 yards for Brilliant Dispersion." },
                },
            },
        },
        trash = {
            { npcID = 241643, name = "Shadowguard Defender",  tip = "Null Sunder stacks per Defender active — control pull size; tank move or pop a cooldown on high-stack groups." },
            { npcID = 241647, name = "Flux Engineer",          tip = "Suppression Field: spread to avoid cleaving the random target, then move as little as possible (movement increases damage taken). Drops a live Mana Battery on death — destroy it before it finishes its 12s cast." },
            { npcID = 248708, name = "Nexus Adept",            tip = "Interrupt Umbra Bolt — high-damage shadow nuke; use a stun or stop if interrupt is on cooldown." },
            { npcID = 248373, name = "Circuit Seer",           tip = "Immune to CC. Defensives and healing CDs for Arcing Mana channel; avoid Erratic Zap and Power Flux circles; watch for nearby Mana Batteries it activates — swap and destroy them before the 12s cast completes." },
            { npcID = 248706, name = "Cursed Voidcaller",      tip = "On death casts Creeping Void — brace for the hit and use Curse dispels to remove the lingering debuff." },
            { npcID = 251853, name = "Grand Nullifier",        tip = "Interrupt Nullify every cast; avoid Dusk Frights fear zones; turns into a Smudge on death that awakens a nearby Dreadflail — CC or cleave it fast." },
            { npcID = 241660, name = "Duskfright Herald",      tip = "Immune to CC. Entropic Leech channels on a random player and applies a healing absorb — use a combat drop or dispel the absorb to end it. Avoid pulsing projectiles from Dark Beckoning." },
            { npcID = 251024, name = "Dreadflail",             tip = "Tank point away from group — Void Lash frontal tank buster; dodge Flailstorm AoE if fixated on you. Also spawned as a Corewarden Nysarra add — kill before the 18s stun ends." },
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
            {
                encounterID = 3199,  -- confirmed in-game
                name        = "Lightblossom Trinity",
                tip         = "Block Lightblossom Beams to prevent Light-Gorged stacks on flowers before they detonate; all three bosses share damage. Avoid Fertile Loam puddles (50% slow). Interrupt Lightsower Dash and Thornblade (Lekshi bleeds).",
                notes = {
                    { role = "general",   text = "Block Lightblossom Beams to prevent Light-Gorged stacks on flowers; all three bosses share damage." },
                    { role = "general",   text = "Avoid Fertile Loam puddles — 50% movement speed slow." },
                    { role = "interrupt", text = "Lightsower Dash — stops seed planting. Thornblade (Lekshi) — stops bleed application." },
                },
            },
            {
                encounterID = 3200,  -- confirmed in-game
                name        = "Ikuzz the Light Hunter",
                tip         = "Destroy Bloodthorn Roots quickly — rooted players are also hit by Crushing Footfalls; Bloodthirsty Gaze fixates Ikuzz on a player for 10s — maintain distance or be Incised.",
                notes = {
                    { role = "general",   text = "Bloodthirsty Gaze fixates Ikuzz on a player for 10s — that player maintains distance." },
                    { role = "dps",       text = "Destroy Bloodthorn Roots quickly — rooted players are also hit by Crushing Footfalls." },
                },
            },
            {
                encounterID = 3201,  -- confirmed in-game
                name        = "Lightwarden Ruia",
                tip         = "Heal players to full to clear Grievous Thrash bleeds. Pulverizing Strikes marks several players — spread marked players apart (100% increased damage taken from subsequent strikes). Don't stand in Lightfire Beams (6s silence). At 40%, Ruia enters Haranir form and rapidly cycles all abilities.",
                notes = {
                    { role = "general",   text = "Pulverizing Strikes marks several players — spread marked players apart (100% increased damage taken from subsequent strikes)." },
                    { role = "general",   text = "Don't stand in Lightfire Beams — 6s silence." },
                    { role = "healer",    text = "Heal players to full to clear Grievous Thrash bleeds; at 40% Haranir form cycles all abilities rapidly — use CDs." },
                },
            },
            {
                encounterID = 3202,  -- confirmed in-game
                name        = "Ziekket",
                tip         = "Intercept Lightbloom's Essence globules before the boss absorbs them — each absorbed globule grants a Florescent Outburst stack (stacking shield); touching them yourself grants Lightbloom's Might (+dmg/healing). Position boss's Lightbeam sweep over Dormant Lashers to vaporize them; dodge the beam and Lightsap puddles. Tank: defensive on Thornspike — stacking impale + bleed.",
                notes = {
                    { role = "general",   text = "Intercept Lightbloom's Essence globules — each one the boss absorbs grants a stacking shield (Florescent Outburst); touching them yourself grants Lightbloom's Might." },
                    { role = "general",   text = "Position boss's Lightbeam sweep over Dormant Lashers to vaporize them; dodge the beam and Lightsap puddles." },
                    { role = "tank",      text = "Use a defensive on Thornspike — it applies a stacking impale + bleed." },
                },
            },
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
            {
                encounterID = 3285,
                npcID       = 238887,
                name        = "Taz'Rah",
                tip         = "Stay out of Dark Rift gravity pull; kill Ethereal Shades quickly to stop Nether Dash chain lines.",
                notes = {
                    { role = "general",   text = "Stay out of Dark Rift gravity pull." },
                    { role = "dps",       text = "Kill Ethereal Shades quickly — each active shade triggers Nether Dash lines." },
                },
            },
            {
                encounterID = 3286,
                npcID       = 239008,
                name        = "Atroxus",
                tip         = "Avoid Noxious Breath frontal; when Toxic Creepers fixate on a player, spread out to avoid the 8-yard toxic aura. Tank: defensive for Hulking Claw — applies a 10s nature DoT.",
                notes = {
                    { role = "general",   text = "Avoid Noxious Breath frontal." },
                    { role = "general",   text = "When Toxic Creepers fixate, spread to avoid the 8-yard toxic aura." },
                    { role = "tank",      text = "Defensive for Hulking Claw — applies a 10s nature DoT." },
                },
            },
            {
                encounterID = 3287,
                npcID       = 248015,
                name        = "Charonus",
                tip         = "Lead Gravitic Orbs into Singularities to consume them before stacks get too high; avoid the gravity well. Cosmic Blast hits the whole group — healer CDs.",
                notes = {
                    { role = "general",   text = "Lead Gravitic Orbs into Singularities to consume them before stacks get too high; avoid the Unstable Singularity gravity well." },
                    { role = "healer",    text = "CDs for Cosmic Blast — group-wide shadow damage + knockback." },
                },
            },
        },
        areas = {
            { subzone = "The Den", bossIndex = 1 },  -- Taz'Rah's arena; confirmed in-game
            { mapID = 2573,        bossIndex = 2 },  -- Atroxus; inferred from encounter order (unconfirmed)
            { mapID = 2574,        bossIndex = 3 },  -- Charonus; inferred from encounter order (unconfirmed)
        },
    },

    -- --------------------------------------------------------
    -- SEASON 1 MYTHIC+ — Legacy Dungeons
    -- --------------------------------------------------------
    {
        instanceID = 2526,  -- confirmed in-game
        uiMapID    = 2097,  -- confirmed in-game
        altMapIDs  = { 2025, 2098 },  -- 2025 = entrance antechamber; 2098 = upper floor (The Pitch); confirmed in-game
        name       = "Algeth'ar Academy",
        location   = "Thaldraszus",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses = {
            {
                encounterID = 2563,  -- confirmed in-game
                name        = "Overgrown Ancient",
                tip         = "Dodge Burst Pods; free allies from Germinate roots; interrupt Lumbering Swipe.",
                notes = {
                    { role = "general",   text = "Dodge Burst Pods; free allies from Germinate roots." },
                    { role = "interrupt", text = "Lumbering Swipe." },
                },
            },
            {
                encounterID = 2564,  -- confirmed in-game
                name        = "Crawth",
                tip         = "Interrupt Screech; spread for quill barrage; kill wind adds quickly.",
                notes = {
                    { role = "general",   text = "Spread for quill barrage; kill wind adds quickly." },
                    { role = "interrupt", text = "Screech." },
                },
            },
            {
                encounterID = 2562,  -- confirmed in-game
                name        = "Vexamus",
                tip         = "Interrupt Spellvoid; dodge Overloaded explosions; spread Arcane Puddle soaks.",
                notes = {
                    { role = "general",   text = "Dodge Overloaded explosions; spread Arcane Puddle soaks." },
                    { role = "interrupt", text = "Spellvoid." },
                },
            },
            {
                encounterID = 2565,  -- confirmed in-game
                name        = "Echo of Doragosa",
                tip         = "Spread for Astral Breath; interrupt Nullifying Pulse; dodge Arcane Rifts.",
                notes = {
                    { role = "general",   text = "Spread for Astral Breath; dodge Arcane Rifts." },
                    { role = "interrupt", text = "Nullifying Pulse." },
                },
            },
        },
        areas = {
            { subzone = "Terrace of Lectures",      bossIndex = 3 },  -- Vexamus; confirmed in-game
            { subzone = "The Botanica",              bossIndex = 1 },  -- Overgrown Ancient; confirmed in-game
            { subzone = "The Pitch",                 bossIndex = 2 },  -- Crawth; spans mapIDs 2097+2098; confirmed in-game
            { subzone = "The Headteacher's Enclave", bossIndex = 4 },  -- Echo of Doragosa; confirmed in-game
        },
    },
    {
        instanceID = 658,   -- confirmed in-game
        uiMapID    = 184,   -- confirmed in-game
        name       = "Pit of Saron",
        location   = "Icecrown",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses = {
            {
                encounterID = 1999,  -- confirmed in-game
                name        = "Forgemaster Garfrost",
                tip         = "LoS boss behind ice boulders to shed Permafrost stacks before they stack too high.",
                notes = {
                    { role = "general",   text = "LoS boss behind ice boulders to shed Permafrost stacks before they stack too high." },
                },
            },
            {
                encounterID = 2001,  -- confirmed in-game
                name        = "Ick & Krick",
                tip         = "Run from Ick during Pursuit; spread for Explosive Barrage.",
                notes = {
                    { role = "general",   text = "Run from Ick during Pursuit; spread for Explosive Barrage." },
                },
            },
            {
                encounterID = 2000,  -- confirmed in-game
                name        = "Scourgelord Tyrannus",
                tip         = "Dodge Overlord's Brand; spread to avoid chained Unholy Power debuffs.",
                notes = {
                    { role = "general",   text = "Dodge Overlord's Brand; spread to avoid chained Unholy Power debuffs." },
                },
            },
        },
        areas = {
            -- Garfrost and Ick & Krick have no named subzone (empty string throughout).
            -- Only Tyrannus has a distinct boss room subzone.
            { subzone = "Scourgelord's Command", bossIndex = 3 },  -- Scourgelord Tyrannus; confirmed in-game
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
            {
                encounterID = 0,
                name        = "Zuraal the Ascended",
                -- Tips sourced from journal API (static-12.0.1); unverified in-game (dungeon locked until M+ S1 launch)
                tip         = "Kill Coalesced Void adds before they reach Zuraal — each one empowers his abilities. Spread for Decimate to minimise pool overlap. Tank: face Null Palm away from the group.",
                notes = {
                    { role = "dps",       text = "Kill Coalesced Void adds immediately — each one that reaches Zuraal empowers his abilities." },
                    { role = "general",   text = "Spread for Decimate to minimise void pool overlap." },
                    { role = "tank",      text = "Face Null Palm away from the group." },
                },
            },
            {
                encounterID = 0,
                name        = "Saprish",
                -- Tips sourced from journal API (static-12.0.1); unverified in-game (dungeon locked until M+ S1 launch)
                tip         = "Kill Darkfang before Saprish hits 100 energy. Spread Void Bombs — at 100 energy Overload ignites all of them simultaneously.",
                notes = {
                    { role = "dps",       text = "Burn Darkfang down — Saprish is weakened without his raptor." },
                    { role = "general",   text = "Spread Void Bombs so Overload doesn't chain-detonate a stack." },
                },
            },
            {
                encounterID = 0,
                name        = "Viceroy Nezhar",
                -- Tips sourced from journal API (static-12.0.1); unverified in-game (dungeon locked until M+ S1 launch)
                tip         = "Move out of Collapsing Void rings before they become Void Storm. Kill Umbral Tentacles to stop Mind Flay.",
                notes = {
                    { role = "general",   text = "Move out of Collapsing Void rings immediately — they expand into an inescapable Void Storm." },
                    { role = "dps",       text = "Kill Umbral Tentacles — their Mind Flay deals continuous damage to a fixated target." },
                },
            },
            {
                encounterID = 0,
                name        = "L'ura",
                -- Tips sourced from journal API (static-12.0.1); unverified in-game (dungeon locked until M+ S1 launch)
                tip         = "Don't overlap Notes of Despair — their Dirge of Despair zones stack. Discordant Beam silences them; once all are silenced, Alleria destroys them with Shattering Shot.",
                notes = {
                    { role = "general",   text = "Spread Notes of Despair — overlapping Dirge of Despair zones stack damage." },
                    { role = "general",   text = "Discordant Beam silences Notes of Despair. Once all are silenced, Alleria destroys them — don't just burn the adds." },
                },
            },
        },
    },
    {
        instanceID = 1209,  -- confirmed in-game
        uiMapID    = 601,   -- confirmed in-game
        altMapIDs  = { 602 },  -- upper tier; confirmed in-game
        name       = "Skyreach",
        location   = "Spires of Arak",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses = {
            {
                encounterID = 1698,  -- confirmed in-game
                name        = "Ranjit",
                tip         = "Hide behind wind barriers for Fan of Blades; interrupt Four Winds.",
                notes = {
                    { role = "general",   text = "Hide behind wind barriers for Fan of Blades." },
                    { role = "interrupt", text = "Four Winds." },
                },
            },
            {
                encounterID = 1699,  -- confirmed in-game
                name        = "Araknath",
                tip         = "Dodge Burn ground fissures; spread to reduce Solarflare chain damage.",
                notes = {
                    { role = "general",   text = "Dodge Burn ground fissures; spread to reduce Solarflare chain damage." },
                },
            },
            {
                encounterID = 1700,  -- confirmed in-game
                name        = "Rukhran",
                tip         = "Burn Spire Eagle adds fast; stay out of Solar Breath frontal cone.",
                notes = {
                    { role = "general",   text = "Stay out of Solar Breath frontal cone." },
                    { role = "dps",       text = "Burn Spire Eagle adds fast." },
                },
            },
            {
                encounterID = 1701,  -- confirmed in-game
                name        = "High Sage Viryx",
                tip         = "Interrupt Lens Flare; kill Initiates before they carry players off the platform.",
                notes = {
                    { role = "dps",       text = "Kill Initiates before they carry players off the platform." },
                    { role = "interrupt", text = "Lens Flare." },
                },
            },
        },
        areas = {
            -- "Grand Spire" appears on both mapID 601 (Araknath) and 602 (High Sage Viryx).
            -- mapID=602 entry must come first — it matches only on that specific map.
            -- The subzone-only entry below it catches mapID 601 without ambiguity.
            { mapID = 602,                    bossIndex = 4 },  -- High Sage Viryx; confirmed in-game
            { subzone = "Lower Quarter",      bossIndex = 1 },  -- Ranjit; confirmed in-game
            { subzone = "Grand Spire",        bossIndex = 2 },  -- Araknath (mapID 601); confirmed in-game
            { subzone = "The Overlook",       bossIndex = 3 },  -- Rukhran; confirmed in-game
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
