-- KwikTip: Dungeon and boss data for World of Warcraft: Midnight
--
-- Map IDs (uiMapID) are used for instance detection.
-- IDs marked 0 (TODO) need to be confirmed in-game:
--   /run print(C_Map.GetBestMapForUnit("player"))
-- Run this command while standing inside each dungeon and fill in the value.
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- Dungeon Data
-- ============================================================
-- Fields per dungeon:
--   uiMapID    : uiMapID from C_Map.GetBestMapForUnit("player") inside the instance
--   name       : display name
--   location   : zone the entrance is in
--   season     : "midnight" = new dungeon  |  "legacy" = returning M+ dungeon
--   type       : "level" = leveling (81-88)  |  "max" = max-level (88-90)
--   mythicPlus : true if in the Season 1 Mythic+ key rotation, false = Mythic 0 only
--   bosses     : ordered list; each entry has:
--     name     : boss name as shown in the game
--     tip      : short contextual tip shown in the HUD (fill in as content is written)
--
-- Season 1 M+ rotation (8 dungeons total):
--   New Midnight: Magisters' Terrace, Maisara Caverns, Nexus-Point Xenas, Windrunner Spire
--   Legacy:       Algeth'ar Academy, Pit of Saron, Seat of the Triumvirate, Skyreach

KwikTip.DUNGEONS = {

    -- --------------------------------------------------------
    -- NEW MIDNIGHT DUNGEONS — Level-Up (81–88)
    -- --------------------------------------------------------
    {
        uiMapID    = 2492,
        name       = "Windrunner Spire",
        location   = "Eversong Woods",
        season     = "midnight",
        type       = "level",
        mythicPlus = true,
        bosses   = {
            { name = "Emberdawn",           tip = "Tank in corner; players hit by Flaming Updraft drop it near the corner and use a personal defensive; dodge Twisters spawned from puddles; healer major CDs on Burning Gale." },
            { name = "Derelict Duo",        tip = "Keep both at equal health throughout — Broken Bond stacks if they're uneven and enrages the survivor; interrupt Kalis's Shadow Bolt; tank use active mitigation for Latch's Bone Hack." },
            { name = "Commander Kroluk",    tip = "Burn adds at 66%/33%; boss immune (Shield Wall) until warparty dies; stay grouped — Intimidating Shout fears isolated players." },
            { name = "The Restless Heart",  tip = "Dodge Arrow Rain; sidestep targeted Bolt Gale; at 100 energy, boss fires wind arrow spawning expanding Billowing Wind rings — stay out; never touch Turbulent Arrows (knockup + removes Squall Leap)." },
        },
    },
    {
        uiMapID    = 2813,
        name       = "Murder Row",
        location   = "Silvermoon City",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses   = {
            { name = "Kystia Manaheart",          tip = "Dispel Illicit Infusion from Nibbles for 15s stun + 100% dmg window — Kystia radiates Chaos AoE during this phase so healer CDs needed; dodge Nibbles' Fel Spray cone while she's hostile; interrupt Mirror Images." },
            { name = "Zaen Bladesorrow",          tip = "Stand behind Forbidden Freight during Murder in a Row; move Fire Bomb away from freight (it destroys cover); Heartstop Poison halves tank max health — prioritize tank healing." },
            { name = "Xathuux the Annihilator",   tip = "Dodge Axe Toss impact zones and the Fel Light left behind; stay mobile to avoid Burning Steps." },
            { name = "Lithiel Cinderfury",        tip = "Kill Wild Imps before Malefic Wave reaches them (they gain haste if hit); use Gateways to avoid the wave; interrupt Chaos Bolt." },
        },
    },
    {
        uiMapID    = 2514,
        altMapIDs  = { 2564 },  -- 2564 = entrance/antechamber sub-zone
        name       = "Den of Nalorakk",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = false,
        bosses   = {
            { name = "The Hoardmonger",    tip = "At 90%/60%/30%, boss retreats to empower; destroy Rotten Mushrooms before burst (Toxic Spores debuff); dodge frontals." },
            { name = "Sentinel of Winter", tip = "Dodge Raging Squalls; stand in Snowdrift zones to resist the Eternal Winter knockback." },
            { name = "Nalorakk",           tip = "Fury of the War God: intercept charging echoes to protect Zul'jarra; spread when Echoing Maul marks you." },
        },
    },
    {
        uiMapID    = 2501,
        name       = "Maisara Caverns",
        location   = "Zul'Aman",
        season     = "midnight",
        type       = "level",
        mythicPlus = true,
        bosses   = {
            { name = "Muro'jin and Nekraxx",     tip = "Kill simultaneously — Muro'jin dies first: Nekraxx enrages (Bestial Wrath); Nekraxx dies first: Muro'jin revives him. Use Freezing Trap victims to interrupt Nekraxx's Carrion Swoop." },
            { name = "Vordaza",                  tip = "Vordaza is immune during Necrotic Convergence — use healer CDs for the damage; kill phantoms (Lingering Dread damages group); dodge Unmake." },
            { name = "Rak'tul, Vessel of Souls", tip = "In spirit realm: interrupt Malignant Souls for Spectral Residue (+25% dmg/heal/speed); avoid Restless Masses roots. Destroy Crush Souls totems before returning." },
        },
    },

    -- --------------------------------------------------------
    -- NEW MIDNIGHT DUNGEONS — Max Level (88–90)
    -- --------------------------------------------------------
    {
        uiMapID    = 2511,
        altMapIDs  = { 2424, 2515, 2519, 2520 },  -- antechamber, entrance, sub-zones
        name       = "Magisters' Terrace",
        location   = "Isle of Quel'Danas",
        season     = "midnight",
        type       = "max",
        mythicPlus = true,
        bosses   = {
            { name = "Arcanotron Custos", tip = "Intercept orbs before they reach the boss; avoid Arcane Residue zones left after the knockback." },
            { name = "Seranel Sunlash",   tip = "At 100 energy, be inside a Suppression Zone or Wave of Silence pacifies you for 8s (unable to cast); also step into a zone to resolve Runic Mark (Feedback) — but zones purge your buffs." },
            { name = "Gemellus",          tip = "All copies share health; touch correct clone to clear Neural Link." },
            { name = "Degentrius",        tip = "One player per quadrant soaks Void Essence as it bounces; miss = Void Destruction stack (wipe at 2). Never touch Void Torrent beams — they stun." },
        },
    },
    {
        uiMapID    = 2915,
        name       = "Nexus-Point Xenas",
        location   = "Voidstorm",
        season     = "midnight",
        type       = "max",
        mythicPlus = true,
        bosses   = {
            { name = "Chief Corewright Kasreth", tip = "Never cross active Leyline Arrays — lethal. When targeted by Reflux Charge, use it to destroy a nearby array for bonus damage." },
            { name = "Corewarden Nysarra",       tip = "Kill Null Vanguard adds before Lightscar Flare; then stand in the wound during 18s stun for 300% damage." },
            { name = "Lothraxion",               tip = "At 100 energy, find and interrupt the real Lothraxion among his images; wrong target = Core Exposure (group damage + 20% increased Holy damage taken for 1 min)." },
        },
    },
    {
        uiMapID    = 2500,
        name       = "The Blinding Vale",
        location   = "Harandar",
        season     = "midnight",
        type       = "max",
        mythicPlus = false,
        bosses   = {
            { name = "Lightblossom Trinity",   tip = "Block Lightblossom Beams to prevent Light-Gorged stacks on flowers before they detonate; interrupt Lightsower Dash to stop seed planting; all three bosses share damage." },
            { name = "Ikuzz the Light Hunter", tip = "Destroy Bloodthorn Roots quickly — rooted players are also hit by Crushing Footfalls; Bloodthirsty Gaze fixates Ikuzz on a player for 10s — maintain distance or be Incised." },
            { name = "Lightwarden Ruia",       tip = "Heal players to full to clear Grievous Thrash bleeds; at 40%, Ruia enters Haranir form (Spirits of the Vale) and rapidly cycles all abilities — tank rotate to avoid stacking Pulverizing Strikes damage-taken debuff." },
            { name = "Ziekket",                tip = "Position so Ziekket's Concentrated Lightbeam sweeps over Dormant Lashers to vaporize them; dodge the beam and avoid the Lightsap puddles it leaves behind." },
        },
    },
    {
        uiMapID    = 2923,
        name       = "Voidscar Arena",
        location   = "Voidstorm",
        season     = "midnight",
        type       = "max",
        mythicPlus = false,
        bosses   = {
            { name = "Taz'Rah",  tip = "Stay out of Dark Rift gravity pull; dodge shade Nether Dash lines." },
            { name = "Atroxus",  tip = "Avoid Noxious Breath frontal; when Toxic Creepers fixate on a player, that player and nearby allies spread out to avoid the 8-yard toxic aura." },
            { name = "Charonus", tip = "Lead Gravitic Orbs into Singularities to consume them; avoid the Unstable Singularity gravity well." },
        },
    },

    -- --------------------------------------------------------
    -- SEASON 1 MYTHIC+ — Legacy Dungeons
    -- --------------------------------------------------------
    {
        uiMapID    = 2526,
        name       = "Algeth'ar Academy",
        location   = "Thaldraszus",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses   = {
            -- Overgrown Ancient, Crawth, and Vexamus can be done in any order;
            -- Echo of Doragosa unlocks only after all three are defeated.
            { name = "Overgrown Ancient", tip = "Dodge Burst Pods; free allies from Germinate roots; interrupt Lumbering Swipe." },
            { name = "Crawth",            tip = "Interrupt Screech; spread for quill barrage; kill wind adds quickly." },
            { name = "Vexamus",           tip = "Interrupt Spellvoid; dodge Overloaded explosions; spread Arcane Puddle soaks." },
            { name = "Echo of Doragosa",  tip = "Spread for Astral Breath; interrupt Nullifying Pulse; dodge Arcane Rifts." },
        },
    },
    {
        uiMapID    = 658,
        name       = "Pit of Saron",
        location   = "Icecrown",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses   = {
            { name = "Forgemaster Garfrost", tip = "LoS boss behind ice boulders to shed Permafrost stacks before they stack too high." },
            { name = "Ick & Krick",          tip = "Run from Ick during Pursuit; spread for Explosive Barrage." },
            { name = "Scourgelord Tyrannus", tip = "Dodge Overlord's Brand; spread to avoid chained Unholy Power debuffs." },
        },
    },
    {
        uiMapID    = 1753,
        name       = "Seat of the Triumvirate",
        location   = "Argus",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses   = {
            { name = "Zuraal the Ascended", tip = "Step through void portals immediately when teleported to avoid damage." },
            { name = "Saprish",             tip = "Kill Darkfang before Saprish's energy caps; boss is vulnerable without his pet." },
            { name = "Viceroy Nezhar",      tip = "Interrupt Dark Bulwark; dodge Void Lashing tentacle swipes." },
            { name = "L'ura",               tip = "Collect soul fragments promptly; avoid standing in void pools." },
        },
    },
    {
        uiMapID    = 1209,
        name       = "Skyreach",
        location   = "Spires of Arak",
        season     = "legacy",
        type       = "max",
        mythicPlus = true,
        bosses   = {
            { name = "Ranjit",          tip = "Hide behind wind barriers for Fan of Blades; interrupt Four Winds." },
            { name = "Araknath",        tip = "Dodge Burn ground fissures; spread to reduce Solarflare chain damage." },
            { name = "Rukhran",         tip = "Burn Spire Eagle adds fast; stay out of Solar Breath frontal cone." },
            { name = "High Sage Viryx", tip = "Interrupt Lens Flare; kill Initiates before they carry players off the platform." },
        },
    },
}

-- ============================================================
-- Runtime lookup: uiMapID → dungeon entry
-- ============================================================
-- Built at load time so dungeon identification is an O(1) table lookup.
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
