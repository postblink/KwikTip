-- Forever-only local test data. No Retail or Timewalking data is loaded.
local ADDON_NAME, KwikTip = ...

-- IDs: Wago Map/DungeonEncounter CSVs for build 1.60.1.70707.
-- Strategy: Method's Hall of Thanes guide (2026-10-15), cross-checked with
-- Icy Veins (2026-10-19). See docs/FOREVER_HALL_OF_THANES_RESEARCH.md.
-- These static IDs do not establish an in-game pass. UiMap/NPC/subzone
-- identifiers remain unverified and are deliberately omitted, not set to 0.
KwikTip.DUNGEONS = {
    {
        instanceID = 3065,
        name = "The Hall of Thanes",
        season = "forever",
        type = "dungeon",
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
}
