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
                encounterID = 3056,
                name        = "Emberdawn",
                tip         = "Drop Flaming Updraft puddles at the room's outer edges; play close to the boss during Burning Gale (16s) to minimize movement when dodging Twisters and Fire Breath frontals; healer major CDs on Burning Gale.",
                notes = {
                    { role = "general",   text = "Drop Flaming Updraft puddles at the room's outer edges." },
                    { role = "general",   text = "During Burning Gale (16s) stay close to the boss — dodge Twisters and Fire Breath frontals." },
                    { role = "healer",    text = "Major CDs on Burning Gale." },
                },
            },
            {
                encounterID = 3057,
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
                encounterID = 3058,
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
                encounterID = 3059,
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
                encounterID = 3101,
                name        = "Kystia Manaheart",
                tip         = "Dispel Illicit Infusion from Nibbles for 15s stun + 100% dmg window — Kystia radiates Chaos AoE during this phase so healer CDs needed; dodge Nibbles' Fel Spray cone while she's hostile; interrupt Mirror Images.",
                notes = {
                    { role = "healer",    text = "Dispel Illicit Infusion from Nibbles — triggers 15s stun and 100% dmg window; major CDs during this phase (Chaos AoE)." },
                    { role = "general",   text = "Dodge Nibbles' Fel Spray cone while she's hostile." },
                    { role = "interrupt", text = "Mirror Images." },
                },
            },
            {
                encounterID = 3102,
                name        = "Zaen Bladesorrow",
                tip         = "Stand behind Forbidden Freight during Murder in a Row; move Fire Bomb away from freight (it destroys cover); Heartstop Poison halves tank max health — prioritize tank healing.",
                notes = {
                    { role = "general",   text = "Stand behind Forbidden Freight during Murder in a Row; move Fire Bomb away from freight — it destroys cover." },
                    { role = "tank",      text = "Heartstop Poison halves your max health — call for an external." },
                    { role = "healer",    text = "Prioritize tank healing after Heartstop Poison." },
                },
            },
            {
                encounterID = 3103,
                name        = "Xathuux the Annihilator",
                tip         = "At 100 energy, Demonic Rage pulses heavy group AoE and buffs boss attack speed — use defensives and healer CDs. Dodge Axe Toss impact zones (Fel Light persists on ground); avoid Burning Steps hazards. Tank: Legion Strike applies 80% healing reduction — call for an external.",
                notes = {
                    { role = "general",   text = "Dodge Axe Toss impact zones (Fel Light persists); avoid Burning Steps." },
                    { role = "tank",      text = "Legion Strike applies 80% healing reduction — call for an external immediately." },
                    { role = "healer",    text = "Major CDs during Demonic Rage (100 energy) — heavy group AoE + boss attack speed buff." },
                },
            },
            {
                encounterID = 3105,
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
        instanceID = 2825,  -- BigWigs, unverified in-game
        uiMapID    = 2514,
        altMapIDs  = { 2564, 2513 },  -- 2564 = Dreamer's Passage/Heart of Rage; 2513 = Heart of Rage (confirmed in-game)
        name       = "Den of Nalorakk",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses = {
            {
                encounterID = 3207,
                name        = "The Hoardmonger",
                tip         = "At 90%/60%/30%, boss retreats to empower; destroy Rotten Mushrooms before burst (Toxic Spores debuff); dodge frontals.",
                notes = {
                    { role = "general",   text = "At 90%/60%/30% boss retreats to empower — dodge frontals." },
                    { role = "dps",       text = "Destroy Rotten Mushrooms before each burst phase (Toxic Spores debuff)." },
                },
            },
            {
                encounterID = 3208,
                name        = "Sentinel of Winter",
                tip         = "Dodge Raging Squalls and Snowdrift pools; at 100 energy boss channels Eternal Winter (shields self + heavy group damage) — use damage CDs to break the shield fast, healer CDs to survive.",
                notes = {
                    { role = "general",   text = "Dodge Raging Squalls and Snowdrift pools." },
                    { role = "dps",       text = "At 100 energy, burn the Eternal Winter shield fast with damage CDs." },
                    { role = "healer",    text = "CDs during Eternal Winter — heavy group damage while the shield is active." },
                },
            },
            {
                encounterID = 3209,
                name        = "Nalorakk",
                tip         = "Fury of the War God: intercept charging echoes to protect Zul'jarra; spread when Echoing Maul marks you.",
                notes = {
                    { role = "general",   text = "Intercept charging echoes (Fury of the War God) to protect Zul'jarra." },
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
                tip         = "Keep equal health — if Nekraxx dies first Muro'jin revives him at 35%; if Muro'jin dies first Nekraxx gains 20% dmg every 4s. Carrion Swoop target: step into a Freezing Trap to block the charge and stun Nekraxx 5s. Dispel Infected Pinions disease.",
                notes = {
                    { role = "general",   text = "Keep equal health — if Nekraxx dies first Muro'jin revives him at 35%; if Muro'jin dies first Nekraxx gains 20% dmg every 4s." },
                    { role = "general",   text = "Carrion Swoop target: step into a Freezing Trap to block the charge and stun Nekraxx 5s." },
                    { role = "healer",    text = "Dispel Infected Pinions disease." },
                },
            },
            {
                encounterID = 3213,
                name        = "Vordaza",
                tip         = "Burst the Deathshroud shield during Necrotic Convergence with damage CDs; kite Unstable Phantoms into each other to detonate them — killing them directly applies Lingering Dread to the group; dodge Unmake line.",
                notes = {
                    { role = "general",   text = "Kite Unstable Phantoms into each other to detonate — killing directly applies Lingering Dread to the group; dodge Unmake line." },
                    { role = "dps",       text = "Burst the Deathshroud shield during Necrotic Convergence with damage CDs." },
                },
            },
            {
                encounterID = 3214,
                name        = "Rak'tul, Vessel of Souls",
                tip         = "In spirit realm: interrupt Malignant Souls for Spectral Residue (+25% dmg/heal/speed); avoid Restless Masses roots. Destroy Crush Souls totems before returning.",
                notes = {
                    { role = "general",   text = "In spirit realm: avoid Restless Masses roots; destroy Crush Souls totems before returning." },
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
                encounterID = 3071,
                name        = "Arcanotron Custos",
                tip         = "Intercept orbs before they reach the boss; avoid Arcane Residue zones left after the knockback.",
                notes = {
                    { role = "general",   text = "Intercept orbs before they reach the boss; avoid Arcane Residue zones after the knockback." },
                },
            },
            {
                encounterID = 3072,
                name        = "Seranel Sunlash",
                tip         = "At 100 energy, be inside a Suppression Zone or Wave of Silence pacifies you for 8s (unable to cast); also step into a zone to resolve Runic Mark (Feedback) — but zones purge your buffs.",
                notes = {
                    { role = "general",   text = "At 100 energy, be inside a Suppression Zone or Wave of Silence pacifies you for 8s." },
                    { role = "general",   text = "Step into a zone to resolve Runic Mark (Feedback) — but zones purge your buffs." },
                },
            },
            {
                encounterID = 3073,
                name        = "Gemellus",
                tip         = "All copies share health; touch correct clone to clear Neural Link.",
                notes = {
                    { role = "general",   text = "All copies share health; touch the correct clone to clear Neural Link." },
                },
            },
            {
                encounterID = 3074,
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
                encounterID = 3328,
                name        = "Chief Corewright Kasreth",
                tip         = "Don't cross Leyline Arrays (damage + slow). When targeted by Reflux Charge, touch an array intersection to destroy it and open space. At full energy: Corespark Detonation hits a player with a massive knockback and healing absorb DoT — watch positioning to avoid being knocked into puddles.",
                notes = {
                    { role = "general",   text = "Don't cross Leyline Arrays (damage + slow); if targeted by Reflux Charge, touch an intersection to destroy it and open space." },
                    { role = "general",   text = "At full energy: Corespark Detonation — massive knockback + healing absorb DoT; don't get knocked into puddles." },
                },
            },
            {
                encounterID = 3332,
                name        = "Corewarden Nysarra",
                tip         = "Avoid Lothraxion's beam during Lightscar Flare; stand in the boss's frontal cone during the 18s stun for 300% damage amp (30% healing amp too). Kill Null Vanguard adds before the stun ends — surviving adds get consumed and buff the boss.",
                notes = {
                    { role = "general",   text = "Avoid Lothraxion's beam during Lightscar Flare." },
                    { role = "dps",       text = "Stand in the boss's frontal cone during the 18s stun for 300% damage amp; kill Null Vanguard adds before the stun ends." },
                    { role = "healer",    text = "30% healing amp is active during the stun — use CDs." },
                },
            },
            {
                encounterID = 3333,
                name        = "Lothraxion",
                tip         = "At 100 energy, find and interrupt the real Lothraxion among his images — he's the only one without glowing horns; wrong target = Core Exposure (group damage + 20% increased Holy damage taken for 1 min).",
                notes = {
                    { role = "interrupt", text = "At 100 energy, find and interrupt the real Lothraxion — no glowing horns; wrong target = Core Exposure (group damage + 20% Holy taken for 1 min)." },
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
                encounterID = 3199,
                name        = "Lightblossom Trinity",
                tip         = "Block Lightblossom Beams to prevent Light-Gorged stacks on flowers before they detonate; interrupt Lightsower Dash to stop seed planting; all three bosses share damage.",
                notes = {
                    { role = "general",   text = "Block Lightblossom Beams to prevent Light-Gorged stacks on flowers; all three bosses share damage." },
                    { role = "interrupt", text = "Lightsower Dash — stops seed planting." },
                },
            },
            {
                encounterID = 3200,
                name        = "Ikuzz the Light Hunter",
                tip         = "Destroy Bloodthorn Roots quickly — rooted players are also hit by Crushing Footfalls; Bloodthirsty Gaze fixates Ikuzz on a player for 10s — maintain distance or be Incised.",
                notes = {
                    { role = "general",   text = "Bloodthirsty Gaze fixates Ikuzz on a player for 10s — that player maintains distance." },
                    { role = "dps",       text = "Destroy Bloodthorn Roots quickly — rooted players are also hit by Crushing Footfalls." },
                },
            },
            {
                encounterID = 3201,
                name        = "Lightwarden Ruia",
                tip         = "Heal players to full to clear Grievous Thrash bleeds; at 40%, Ruia enters Haranir form (Spirits of the Vale) and rapidly cycles all abilities — tank moves to avoid stacking Pulverizing Strikes damage-taken debuff.",
                notes = {
                    { role = "tank",      text = "At 40%, Ruia enters Haranir form — tank moves to avoid stacking Pulverizing Strikes damage-taken debuff." },
                    { role = "healer",    text = "Heal players to full to clear Grievous Thrash bleeds." },
                },
            },
            {
                encounterID = 3202,
                name        = "Ziekket",
                tip         = "Intercept Lightbloom's Essence globules before the boss absorbs them — each absorbed globule grants a Florescent Outburst stack (stacking shield); touching them yourself grants Lightbloom's Might (+dmg/healing). Position boss's Lightbeam sweep over Dormant Lashers to vaporize them; dodge the beam and Lightsap puddles.",
                notes = {
                    { role = "general",   text = "Intercept Lightbloom's Essence globules — each one the boss absorbs grants a stacking shield (Florescent Outburst); touching them yourself grants Lightbloom's Might." },
                    { role = "general",   text = "Position boss's Lightbeam sweep over Dormant Lashers to vaporize them; dodge the beam and Lightsap puddles." },
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
                name        = "Taz'Rah",
                tip         = "Stay out of Dark Rift gravity pull; dodge shade Nether Dash lines.",
                notes = {
                    { role = "general",   text = "Stay out of Dark Rift gravity pull; dodge shade Nether Dash lines." },
                },
            },
            {
                encounterID = 3286,
                name        = "Atroxus",
                npcID       = 239008,
                tip         = "Avoid Noxious Breath frontal; when Toxic Creepers fixate on a player, that player and nearby allies spread out to avoid the 8-yard toxic aura.",
                notes = {
                    { role = "general",   text = "Avoid Noxious Breath frontal." },
                    { role = "general",   text = "When Toxic Creepers fixate, spread to avoid the 8-yard toxic aura." },
                },
            },
            {
                encounterID = 3287,
                name        = "Charonus",
                npcID       = 248015,
                tip         = "Lead Gravitic Orbs into Singularities to consume them; avoid the Unstable Singularity gravity well.",
                notes = {
                    { role = "general",   text = "Lead Gravitic Orbs into Singularities to consume them; avoid the Unstable Singularity gravity well." },
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
        instanceID = 658,   -- BigWigs Loader.lua
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
                tip         = "Step through void portals immediately when teleported to avoid damage.",
                notes = {
                    { role = "general",   text = "Step through void portals immediately when teleported to avoid damage." },
                },
            },
            {
                encounterID = 0,
                name        = "Saprish",
                tip         = "Kill Darkfang before Saprish's energy caps; boss is vulnerable without his pet.",
                notes = {
                    { role = "dps",       text = "Kill Darkfang before Saprish's energy caps — boss is vulnerable without his pet." },
                },
            },
            {
                encounterID = 0,
                name        = "Viceroy Nezhar",
                tip         = "Interrupt Dark Bulwark; dodge Void Lashing tentacle swipes.",
                notes = {
                    { role = "general",   text = "Dodge Void Lashing tentacle swipes." },
                    { role = "interrupt", text = "Dark Bulwark." },
                },
            },
            {
                encounterID = 0,
                name        = "L'ura",
                tip         = "Collect soul fragments promptly; avoid standing in void pools.",
                notes = {
                    { role = "general",   text = "Collect soul fragments promptly; avoid standing in void pools." },
                },
            },
        },
    },
    {
        instanceID = 1209,  -- BigWigs Loader.lua
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
