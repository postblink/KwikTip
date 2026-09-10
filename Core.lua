-- KwikTip: Core.lua (Event tracking, logging, commands, detection)
local ADDON_NAME, KwikTip = ...
local L = KwikTip.L

local frame = CreateFrame("Frame", "KwikTipCoreFrame", UIParent)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("CHALLENGE_MODE_START")
frame:RegisterEvent("CHALLENGE_MODE_RESET")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
-- NOTE: In Midnight 12.x, UnitGUID() for hostile NPCs returns a tainted "secret value" —
-- COMBAT_LOG_EVENT_UNFILTERED is also a protected event and cannot be registered.
-- NPC-based trash tip detection is impossible; detection uses subzone/area events only.
-- UNIT_SPELLCAST_START is registered dynamically for debug spell logging only.
local _loggedSpells = {}  -- [npcID..":"..spellID] = true; reset on PLAYER_ENTERING_WORLD and /kwik clearlog
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        _loggedSpells = {}  -- reset per-run dedup on every full zone load (loading screen)
        KwikTip:UpdateContent()
        KwikTip:UpdateVisibility()
        KwikTip:LogMapID()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        KwikTip:UpdateContent()
        KwikTip:UpdateVisibility()
        KwikTip:LogMapID()
    elseif event == "ZONE_CHANGED" then
        -- Defer by one frame: ZONE_CHANGED fires before GetSubZoneText() returns the new
        -- subzone, so reading it synchronously here would match the old area and miss boss
        -- room tips. A zero-second timer lets the game state settle before we query it.
        C_Timer.After(0, function()
            KwikTip:UpdateContent()
            KwikTip:UpdateVisibility()
            KwikTip:LogMapID()
        end)
    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID, groupSize = ...
        KwikTip:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    elseif event == "ENCOUNTER_END" then
        local _, _, _, _, success = ...
        KwikTip:OnEncounterEnd(success)
    elseif event == "PLAYER_ROLES_ASSIGNED" then
        KwikTip:UpdateContent()
    elseif event == "CHALLENGE_MODE_START" then
        KwikTip:OnChallengeModeStart()
    elseif event == "CHALLENGE_MODE_RESET" or event == "CHALLENGE_MODE_COMPLETED" then
        KwikTip:UpdateContent()
        KwikTip:UpdateVisibility()
    elseif event == "SCENARIO_CRITERIA_UPDATE" then
        -- Banked Enemy Forces % updates as mobs die; re-render the HUD.
        KwikTip:UpdateContent()
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, _, spellID = ...
        KwikTip:OnSpellCastStart(unit, spellID)
    end
end)

-- Returns true if the current instance type should be handled by KwikTip.
local function IsSupportedInstance(inInstance, instanceType)
    if not inInstance then return false end
    if instanceType == "scenario" then return KwikTipDB and KwikTipDB.delves end
    return instanceType == "party" or instanceType == "raid"
end

local GOLD  = "|cffffcc00"
local WHITE = "|cffffffff"
local GRAY  = "|cffbbbbbb"
local RESET = "|r"

-- Defensive tostring for debug output (secret values are unprintable).
local function SafeStr(v)
    local ok, s = pcall(tostring, v)
    return ok and s or "<unprintable>"
end

-- Returns the player's current assigned role as a lowercase string matching the
-- notes role keys ("tank", "healer", "dps"), or nil if unassigned/solo.
local function GetPlayerRole()
    local r = UnitGroupRolesAssigned("player")
    if r == "TANK"    then return "tank"   end
    if r == "HEALER"  then return "healer" end
    if r == "DAMAGER" then return "dps"    end
    return nil
end

-- Role note rendering
-- Colors
local TANK_COLOR = "|cff0099ff"
local HEAL_COLOR = "|cff33cc33"
local DPS_COLOR  = "|cffff6633"
-- Icons: Interface\Icons\ texture paths — same format as the confirmed-working interrupt icon
local TANK_ICON = "|TInterface\\Icons\\Ability_Warrior_DefensiveStance:13:13|t"
local HEAL_ICON = "|TInterface\\Icons\\Spell_Holy_Renew:13:13|t"
local DPS_ICON  = "|TInterface\\Icons\\Ability_DualWield:13:13|t"
local INT_ICON  = "|TInterface\\Icons\\Ability_Kick:13:13|t"

local ROLE_FMT = {
    tank      = { icon = TANK_ICON, color = TANK_COLOR },
    healer    = { icon = HEAL_ICON, color = HEAL_COLOR },
    dps       = { icon = DPS_ICON,  color = DPS_COLOR  },
    interrupt = { icon = INT_ICON,  color = GOLD       },
    general   = { icon = nil,       color = GRAY       },
}

-- Render a structured notes array into HUD text.
-- Each entry: { role = "general"|"tank"|"healer"|"dps"|"interrupt", text = "..." }
-- filterRole: if provided, only notes of that role + "general" + "interrupt" are shown.
-- Pass nil to show all notes (used for preview and flat-tip fallback).
-- Returns nil if notes is nil, empty, or all entries are filtered out.
local function FormatNotes(notes, filterRole)
    if not notes or #notes == 0 then return nil end
    local lines = {}
    for _, note in ipairs(notes) do
        if not filterRole
            or note.role == "general"
            or note.role == "interrupt"
            or note.role == filterRole
        then
            local fmt = ROLE_FMT[note.role] or ROLE_FMT.general
            if fmt.icon then
                table.insert(lines, fmt.icon .. " " .. fmt.color .. note.text .. RESET)
            else
                table.insert(lines, fmt.color .. note.text .. RESET)
            end
        end
    end
    if #lines == 0 then return nil end
    return table.concat(lines, "\n")
end

-- Normalize a localizable prose field: an empty string means "not translated"
-- and must never suppress the English content behind it. Translation tooling
-- routinely emits "" for untranslated fields, so every fallback chain treats
-- "" exactly like nil.
local function Prose(value)
    if value and value ~= "" then return value end
    return nil
end

-- Shared header: "Dungeon Name\nEntity Name"
local function FormatHeader(dungeonName, entityName)
    return GOLD .. dungeonName .. RESET .. "\n" .. WHITE .. entityName .. RESET
end

-- Build a compact single-line affix bar for appending to boss/area tips.
-- Returns nil when not in an active M+ run.
-- Format: "+7  Tyrannical  ·  Bolstering"
local function FormatAffixBar()
    if not C_ChallengeMode then return nil end
    local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
    if not level or not affixes or #affixes == 0 then return nil end
    local names = {}
    for _, id in ipairs(affixes) do
        local data = KwikTip.AFFIXES and KwikTip.AFFIXES[id]
        local info = C_ChallengeMode.GetAffixInfo(id)
        local name = (data and data.name) or (info and info.name) or ("Affix#"..id)
        table.insert(names, name)
    end
    return GRAY .. "+" .. level .. "  " .. GOLD .. table.concat(names, "  ·  ") .. RESET
end

-- Build the full affix tip block for the M+ holding screen.
-- Returns nil when not in an active M+ run.
local function FormatAffixDetails()
    if not C_ChallengeMode then return nil end
    local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
    if not level or not affixes or #affixes == 0 then return nil end
    local lines = { GOLD .. string.format(L.AFFIX_HEADING, level) .. RESET }
    for _, id in ipairs(affixes) do
        local data = KwikTip.AFFIXES and KwikTip.AFFIXES[id]
        local info = C_ChallengeMode.GetAffixInfo(id)
        local name = (data and data.name) or (info and info.name) or ("Affix#"..id)
        local tip  = data and data.tip
        if tip then
            table.insert(lines, GOLD .. name .. RESET .. ": " .. GRAY .. tip .. RESET)
        else
            -- Fall back to in-game description; truncate if long
            local desc = info and info.description
            if desc and #desc > 80 then desc = desc:sub(1, 77) .. "..." end
            table.insert(lines, GOLD .. name .. RESET .. (desc and (": " .. GRAY .. desc .. RESET) or ""))
        end
    end
    return table.concat(lines, "\n")
end

-- ============================================================
-- Mythic+ banked Enemy Forces progress (display-only)
-- ============================================================
-- Reads the banked (already-earned) Enemy Forces percentage that
-- Blizzard already exposes for display in the scenario objective
-- tracker. This is the aggregate Blizzard shows — never the per-mob
-- contribution, which is a secret value inside a key and must not be
-- reconstructed by addon code (see Secret Values model).
--
-- Stateless by design: recomputed from C_ScenarioInfo on every call.
-- No cached state, no polling. Returns Blizzard's own localized
-- quantityString (e.g. "63.4%") or nil when not in a Mythic+ run or
-- no weighted criterion is present.
local function GetMPlusProgressString()
    if not C_ScenarioInfo then return nil end
    local ok, info = pcall(C_ScenarioInfo.GetScenarioInfo)
    if not ok or not info then return nil end
    if info.scenarioType ~= LE_SCENARIO_TYPE_CHALLENGE_MODE then return nil end
    local _, _, _, numCriteria = C_ScenarioInfo.GetStepInfo()
    if not numCriteria or numCriteria <= 0 then return nil end
    for i = 1, numCriteria do
        local c = C_ScenarioInfo.GetCriteriaInfo(i)
        if c and c.isWeightedProgress and c.quantityString and c.quantityString ~= "" then
            return c.quantityString
        end
    end
    return nil
end

-- Footer line for the HUD: "M+ Progress  63.4%".
-- Returns nil when not applicable so non-M+ content is untouched.
local function FormatMPlusProgress()
    local pct = GetMPlusProgressString()
    if not pct then return nil end
    return GRAY .. L.MPLUS_PROGRESS .. "  " .. WHITE .. pct .. RESET
end

-- Append the M+ progress footer to a HUD content string.
-- No-op (returns content unchanged) when not in an active M+ run.
local function AppendMPlusProgress(content)
    local foot = FormatMPlusProgress()
    if not foot then return content end
    if content and content ~= "" then
        return content .. "\n" .. foot
    end
    return foot
end

-- Build the HUD string for an active boss encounter.
-- Filters structured notes to the player's assigned role (+ general + interrupt).
-- If boss.difficulties[difficultyID] exists, its tip/notes override the base ones.
-- Falls back to the flat tip string if no notes are defined.
--
-- Fallback chain for translated content (TIP_OVERRIDE_BY_ENCOUNTERID):
--   1. difficulty-specific translation
--   2. English difficulty-specific content
--   3. base translation
--   4. English base content
-- A flat tip at a more-specific level wins immediately. Translated structured
-- notes fill missing roles from the matching English level; base content is
-- consulted only when the difficulty level produces no body. This preserves
-- the legacy English difficulty override while allowing per-role translation.
local function FormatBossContent(dungeon, boss, difficultyID)
    local override = difficultyID and boss.difficulties and boss.difficulties[difficultyID]
    local role = GetPlayerRole()

    -- Check TIP_OVERRIDE_BY_ENCOUNTERID for translated content (keyed by encounterID)
    local tipOver = KwikTip.TIP_OVERRIDE_BY_ENCOUNTERID and KwikTip.TIP_OVERRIDE_BY_ENCOUNTERID[boss.encounterID]
    local tipOverDiff = tipOver and difficultyID and tipOver.difficulties and tipOver.difficulties[difficultyID]

    local function NoteApplies(note)
        return not role
            or note.role == "general"
            or note.role == "interrupt"
            or note.role == role
    end

    -- Resolve one specificity level. The translated source owns any role it
    -- defines; the matching English source supplies only missing role fields.
    -- All notes for an owned role are retained (bosses commonly have several
    -- general notes). If no translated note applies, its flat tip wins before
    -- consulting English content at this level.
    -- A translated note with empty text is untranslated: it neither renders nor
    -- claims its role, so the English note for that role is still used.
    local function ResolveLevel(translated, english)
        local translatedNotes = {}
        local translatedRoles = {}
        if translated and translated.notes then
            for _, note in ipairs(translated.notes) do
                if NoteApplies(note) and Prose(note.text) then
                    table.insert(translatedNotes, note)
                    translatedRoles[note.role] = true
                end
            end
        end

        if #translatedNotes == 0 and translated and Prose(translated.tip) then
            return GRAY .. translated.tip .. RESET
        end

        if #translatedNotes > 0 then
            local merged = translatedNotes
            if english and english.notes then
                for _, note in ipairs(english.notes) do
                    if NoteApplies(note) and not translatedRoles[note.role] then
                        table.insert(merged, note)
                    end
                end
            end
            return FormatNotes(merged, role)
        end

        -- With no applicable translated field, retain the exact legacy English
        -- rule: applicable structured notes first, then the flat tip.
        local body = english and FormatNotes(english.notes, role)
        if not body and english and Prose(english.tip) then
            body = GRAY .. english.tip .. RESET
        end
        return body
    end

    local body = ResolveLevel(tipOverDiff, override)
    if not body then body = ResolveLevel(tipOver, boss) end

    -- Header: the instance name is always available localized. Blizzard only
    -- supplies the localized boss name to this addon through ENCOUNTER_START,
    -- so pre-encounter and next-boss previews intentionally keep the authored
    -- English boss.name fallback rather than fabricating locale translations.
    local bossName = boss.name
    if KwikTip._activeEncounterName then
        bossName = KwikTip._activeEncounterName
    end
    local dungeonName = dungeon.name
    local instanceName = GetInstanceInfo()
    if instanceName and instanceName ~= "" then
        dungeonName = instanceName
    end

    local header = FormatHeader(dungeonName, bossName)
    return body and (header .. "\n" .. body) or header
end


-- Match a player's current subzone string against an area entry.
-- Checks the canonical English subzone and any localized aliases stored
-- in a separate table keyed by area.id (populated by locale overlay files).
-- This avoids mutating the English DungeonData table.
local function SubzoneMatches(area, playerSubzone)
    if not playerSubzone or playerSubzone == "" then return false end
    if area.subzone and area.subzone == playerSubzone then return true end
    if area.id and KwikTip.SUBZONE_LOCALE_BY_AREA_ID then
        local aliases = KwikTip.SUBZONE_LOCALE_BY_AREA_ID[area.id]
        if aliases then
            for _, loc in ipairs(aliases) do
                if loc == playerSubzone then return true end
            end
        end
    end
    -- Legacy fallback: area.subzoneLocales (deprecated, kept for backward compat)
    if area.subzoneLocales then
        for _, loc in ipairs(area.subzoneLocales) do
            if loc == playerSubzone then return true end
        end
    end
    return false
end

-- Build the HUD string for the current sub-zone area.
-- Matches GetSubZoneText() against dungeon.areas[].subzone.
-- If the area entry has a bossIndex field, the boss tip is shown instead
-- of a generic area tip — used for boss room sub-zones so the tip appears
-- as the group enters, before ENCOUNTER_START fires.
-- Returns nil if the current sub-zone has no defined tip.
local function FormatAreaContent(dungeon, difficultyID)
    local subzone = GetSubZoneText()
    local mapID   = C_Map.GetBestMapForUnit("player")
    for _, a in ipairs(dungeon.areas) do
        local match = (subzone ~= "" and SubzoneMatches(a, subzone))
                   or (a.mapID  and a.mapID  == mapID)
        if match then
            if a.bossIndex then
                local boss = dungeon.bosses[a.bossIndex]
                if boss then
                    return FormatBossContent(dungeon, boss, difficultyID)
                end
            end
            -- Check for translated area tip via AREA_OVERRIDE_BY_ID.
            -- An empty translated tip is untranslated and falls back to English.
            local areaText = nil
            if a.id and KwikTip.AREA_OVERRIDE_BY_ID and KwikTip.AREA_OVERRIDE_BY_ID[a.id] then
                areaText = Prose(KwikTip.AREA_OVERRIDE_BY_ID[a.id].tip)
            end
            if not areaText then
                areaText = Prose(a.tip)
            end
            -- Guard: if neither bossIndex nor tip is present, skip rather than showing a blank body.
            if not areaText then return nil end
            -- Header: prefer localized instance name from Blizzard API
            local displayName = dungeon.name
            local instanceName = GetInstanceInfo()
            if instanceName and instanceName ~= "" then
                displayName = instanceName
            end
            return GOLD .. displayName .. RESET .. "\n"
                .. WHITE .. (subzone ~= "" and subzone or "") .. RESET .. "\n"
                .. GRAY .. areaText .. RESET
        end
    end
    return nil
end

-- ============================================================
-- User notes
-- ============================================================

-- Returns the SavedVariables key for the player's current area, or nil if not
-- in a recognized instance. Format: "instanceID:subzone" (or "instanceID" alone
-- when GetSubZoneText() is empty, e.g. transition corridors).
function KwikTip:GetNoteKey()
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if not instanceID or instanceID == 0 then return nil end
    local subzone = GetSubZoneText()
    if subzone and subzone ~= "" then
        return tostring(instanceID) .. ":" .. subzone
    end
    return tostring(instanceID)
end

-- Appends the user's saved note for the current area to a content string.
-- Returns the string unchanged when no note exists.
local function AppendUserNote(content)
    if not KwikTipDB or not KwikTipDB.notes then return content end
    local key = KwikTip:GetNoteKey()
    if not key then return content end
    local note = KwikTipDB.notes[key]
    if not note or note == "" then return content end
    return content .. "\n|cffffdd88" .. note .. "|r"
end

-- ============================================================
-- Boss encounter state
-- ============================================================

-- Called by ENCOUNTER_START. Locks the HUD to the boss tip for the fight duration.
-- Always logs the encounterID to encounterLog (not gated on debugLog) so legacy
-- dungeon encounter IDs can be collected without enabling full debug mode.
function KwikTip:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    -- Always-on encounter logging — used to resolve encounterID = 0 stubs in DungeonData.
    if KwikTipDB then
        local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
        table.insert(KwikTipDB.encounterLog, {
            encounterID   = encounterID,
            encounterName = encounterName,
            difficultyID  = difficultyID,
            groupSize     = groupSize,
            instanceID    = instanceID,
            instanceName  = instanceName,
            mapID         = C_Map.GetBestMapForUnit("player"),
            time          = date("%Y-%m-%d %H:%M:%S"),
        })
        if #KwikTipDB.encounterLog > 500 then
            KwikTipDB.encounterLog = self:PruneArray(KwikTipDB.encounterLog, 500)
        end
    end

    self._activeEncounterID  = encounterID
    self._activeEncounterName = encounterName
    self._activeBossEntry    = nil
    self._activeDifficultyID = difficultyID

    -- Guard HUD update against disabled instance types (raids off, delves off, etc.).
    -- encounterLog above is intentionally unconditional — always-on for debug purposes.
    local inInstance, instanceType = IsInInstance()
    if not IsSupportedInstance(inInstance, instanceType) then return end

    local entry = KwikTip.BOSS_BY_ENCOUNTERID[encounterID]
    if not entry then return end

    self._activeBossEntry = entry
    self.bossActive = true
    local content = FormatBossContent(entry.dungeon, entry.boss, difficultyID)
    local bar = entry.dungeon.mythicPlus and FormatAffixBar()
    local cStart = bar and (content .. "\n" .. bar) or content
    self:SetContent(AppendUserNote(AppendMPlusProgress(cStart)))
    self:UpdateVisibility()
end

-- Called by ENCOUNTER_END. On a kill, advances to the next boss tip in the
-- dungeon sequence so areas without subzone/mapID coverage (e.g. Pit of Saron)
-- still surface the upcoming boss immediately after a kill. In dungeons with
-- normal area coverage the next ZONE_CHANGED_NEW_AREA will override it anyway.
-- On a wipe/reset, restores normal area/trash detection immediately.
function KwikTip:OnEncounterEnd(success)
    local lastEntry          = self._activeBossEntry  -- capture before clear
    local lastDifficultyID   = self._activeDifficultyID
    self._activeBossEntry    = nil
    self._activeEncounterID  = nil
    self._activeEncounterName = nil
    self._activeDifficultyID = nil
    self.bossActive = false
    if success == 1 then
        -- Try to advance to the next boss tip in the dungeon sequence.
        local advanced = false
        if lastEntry then
            local dungeon = lastEntry.dungeon
            for i, boss in ipairs(dungeon.bosses) do
                if boss == lastEntry.boss then
                    local nextBoss = dungeon.bosses[i + 1]
                    if nextBoss then
                        local bar     = dungeon.mythicPlus and FormatAffixBar()
                        local content = FormatBossContent(dungeon, nextBoss, lastDifficultyID)
                        local cNext   = bar and (content .. "\n" .. bar) or content
                        self:SetContent(AppendUserNote(AppendMPlusProgress(cNext)))
                        advanced = true
                    end
                    break
                end
            end
        end
        -- No next boss (last boss of dungeon) — leave current tip up.
        self:UpdateVisibility()
    else
        -- Wipe or reset — clear and return to normal detection.
        self:SetContent("")
        self:UpdateContent()
        self:UpdateVisibility()
    end
end


-- Called by CHALLENGE_MODE_START. Logs the keystone and refreshes content so
-- the affix bar/details appear in the HUD immediately on entering the key.
function KwikTip:OnChallengeModeStart()
    if KwikTipDB and C_ChallengeMode then
        local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
        if level then
            local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
            local affixData = {}
            if affixes then
                for _, id in ipairs(affixes) do
                    local info = C_ChallengeMode.GetAffixInfo(id)
                    table.insert(affixData, { id = id, name = info and info.name or "unknown" })
                end
            end
            table.insert(KwikTipDB.keystoneLog, {
                level      = level,
                affixes    = affixData,
                instanceID = instanceID,
                time       = date("%Y-%m-%d %H:%M:%S"),
            })
            if #KwikTipDB.keystoneLog > 200 then
                KwikTipDB.keystoneLog = self:PruneArray(KwikTipDB.keystoneLog, 200)
            end
        end
    end
    self:UpdateContent()
    self:UpdateVisibility()
end

-- ============================================================
-- Spell cast logging
-- ============================================================
-- Logs hostile NPC spell casts from the current target.
-- Gated on debugLog. Deduplicates per (npcID, spellID) pair so each unique
-- cast is only recorded once per session.
-- Purpose: surface interrupt priorities and dangerous mechanics for tip writing.

function KwikTip:OnSpellCastStart(unit, spellID)
    if not KwikTipDB or not KwikTipDB.debugLog then return end
    if unit ~= "target" then return end
    local inInstance, instanceType = IsInInstance()
    if not IsSupportedInstance(inInstance, instanceType) then return end
    if not spellID then return end
    if not UnitCanAttack("player", "target") then return end
    if UnitIsPlayer("target") then return end

    local guid = UnitGUID("target")
    if not guid then return end
    -- pcall required: in Midnight 12.x hostile NPC GUIDs are tainted secret values — GetCreatureID rejects them at the C level.
    local ok, npcID = pcall(C_CreatureInfo.GetCreatureID, guid)
    if not ok then return end
    if not npcID or npcID == 0 then return end

    local key = npcID .. ":" .. spellID
    if _loggedSpells[key] then return end
    _loggedSpells[key] = true

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local spellName = spellInfo and spellInfo.name or ("spell:"..spellID)
    local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    table.insert(KwikTipDB.spellLog, {
        spellID      = spellID,
        spellName    = spellName,
        npcID        = npcID,
        npcName      = UnitName("target"),
        instanceID   = instanceID,
        instanceName = instanceName,
        mapID        = C_Map.GetBestMapForUnit("player"),
        subzone      = GetSubZoneText(),
        time         = date("%Y-%m-%d %H:%M:%S"),
    })
    if #KwikTipDB.spellLog > 2000 then
        KwikTipDB.spellLog = self:PruneArray(KwikTipDB.spellLog, 2000)
    end
end

-- ============================================================
-- Detection
-- ============================================================

-- Identify the current dungeon and update HUD content.
-- Area detection uses GetSubZoneText() matched against dungeon.areas[].subzone.
-- ZONE_CHANGED fires on sub-zone transitions so no polling ticker is needed
-- for area updates — events drive UpdateContent directly.
function KwikTip:UpdateContent()
    if self.bossActive or self.previewActive then return end

    local inInstance, instanceType = IsInInstance()
    if not IsSupportedInstance(inInstance, instanceType) then
        self.areaActive    = false
        self.dungeonActive = false
        self:SetContent("")
        if self._targetEventsRegistered then
            frame:UnregisterEvent("UNIT_SPELLCAST_START")
            self._targetEventsRegistered = false
        end
        return
    end

    if not self._targetEventsRegistered then
        frame:RegisterEvent("UNIT_SPELLCAST_START")
        self._targetEventsRegistered = true
    end

    -- Primary lookup: instanceID from GetInstanceInfo()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local dungeon = instanceID and KwikTip.DUNGEON_BY_INSTANCEID[instanceID]

    -- Fallback: uiMapID for dungeons with instanceID = 0
    if not dungeon then
        local mapID = C_Map.GetBestMapForUnit("player")
        dungeon = mapID and KwikTip.DUNGEON_BY_UIMAPID[mapID]
    end

    local prevAreaActive    = self.areaActive
    local prevDungeonActive = self.dungeonActive

    local areaContent = dungeon and dungeon.areas and FormatAreaContent(dungeon, difficultyID)

    if areaContent then
        self.areaActive    = true
        self.dungeonActive = false
        local bar = dungeon.mythicPlus and FormatAffixBar()
        local cArea = bar and (areaContent .. "\n" .. bar) or areaContent
        self:SetContent(AppendUserNote(AppendMPlusProgress(cArea)))
    elseif dungeon and KwikTipDB.showInDungeon then
        -- No area match — show M+ affix details if active, otherwise a holding message.
        self.areaActive    = false
        self.dungeonActive = true
        local affixDetails = dungeon.mythicPlus and FormatAffixDetails()
        if affixDetails then
            local instanceName = GetInstanceInfo()
            local displayName = (instanceName and instanceName ~= "") and instanceName or dungeon.name
            local cAffix = GOLD .. displayName .. RESET .. "\n" .. affixDetails
            self:SetContent(AppendMPlusProgress(cAffix))
        elseif dungeon.mythicPlus then
            self:SetContent(AppendMPlusProgress(GRAY .. L.WAITING_ENCOUNTER .. RESET))
        else
            self:SetContent("")
        end
    else
        self.areaActive    = false
        self.dungeonActive = false
        self:SetContent("")
    end

    if prevAreaActive ~= self.areaActive or prevDungeonActive ~= self.dungeonActive then
        self:UpdateVisibility()
    end
end

-- ============================================================
-- Debug logging
-- ============================================================

function KwikTip:LogMapID()
    if not KwikTipDB or not KwikTipDB.debugLog then return end
    local inInstance, instanceType = IsInInstance()
    if not IsSupportedInstance(inInstance, instanceType) then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local subzone = GetSubZoneText()

    -- Deduplication to prevent redundant GC thrashing on ZONE_CHANGED
    if self._lastMapID == mapID and self._lastInstanceID == instanceID and self._lastSubzone == subzone then
        return
    end
    self._lastMapID = mapID
    self._lastInstanceID = instanceID
    self._lastSubzone = subzone

    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    table.insert(KwikTipDB.mapIDLog, {
        mapID        = mapID,
        x            = pos and pos.x,
        y            = pos and pos.y,
        instanceID   = instanceID,
        instanceName = instanceName,
        instanceType = instanceType,
        subzone      = subzone,
        noSubzone    = (subzone == "") or nil,  -- flag transitions where subzone text is absent; omitted when false to keep log tidy
        time         = date("%Y-%m-%d %H:%M:%S"),
    })

    -- Cap log size to avoid SavedVariables bloat
    if #KwikTipDB.mapIDLog > 2000 then
        KwikTipDB.mapIDLog = self:PruneArray(KwikTipDB.mapIDLog, 2000)
    end
end

-- ============================================================
-- Utility: PruneArray
-- O(N) array slicing to avoid catastrophic O(N^2) from table.remove(arr, 1) in loops
-- ============================================================
function KwikTip:PruneArray(arr, maxLen)
    local len = #arr
    local over = len - maxLen
    if over > 0 then
        local newArr = {}
        for i = over + 1, len do
            newArr[i - over] = arr[i]
        end
        return newArr
    end
    return arr
end

-- ============================================================
-- Preview (settings demo)
-- ============================================================

-- Static demo notes — module-scoped so ShowPreview doesn't reallocate on every call.
local DEMO_NOTES = {
    { role = "general",   text = L.DEMO_GENERAL },
    { role = "tank",      text = L.DEMO_TANK },
    { role = "healer",    text = L.DEMO_HEALER },
    { role = "dps",       text = L.DEMO_DPS },
    { role = "interrupt", text = L.DEMO_INTERRUPT },
}

-- Show a demo tip in the HUD with one note of every role category.
-- Sets previewActive so UpdateContent won't override it while config is open.
-- Call ClearPreview() (or close the config window) to dismiss.
function KwikTip:ShowPreview()
    self.previewActive = true
    self:InitHUD()
    self:SetContent(FormatHeader(L.DEMO_DUNGEON, L.DEMO_BOSS) .. "\n" .. FormatNotes(DEMO_NOTES))
    self:UpdateVisibility()
end

-- Dismiss the preview and restore normal HUD state.
function KwikTip:ClearPreview()
    if not self.previewActive then return end
    self.previewActive = false
    self:SetContent("")
    self:UpdateContent()
    self:UpdateVisibility()
end

-- Toggle preview on/off — single entry point for UI callers.
function KwikTip:TogglePreview()
    if self.previewActive then
        self:ClearPreview()
    else
        self:ShowPreview()
    end
end

-- ============================================================
-- Slash commands
-- ============================================================
SLASH_KWIKTIP1 = "/kwiktip"
SLASH_KWIKTIP2 = "/kwik"

SlashCmdList["KWIKTIP"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
    if cmd == "move" then
        KwikTip:ToggleMoveMode()
    elseif cmd == "debug" then
        local inInstance, instanceType = IsInInstance()
        local mapID = C_Map.GetBestMapForUnit("player")
        local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
        local dungeon = (instanceID and KwikTip.DUNGEON_BY_INSTANCEID[instanceID])
            or (mapID and KwikTip.DUNGEON_BY_UIMAPID[mapID])
        local subzone = GetSubZoneText()
        local dungeonName = dungeon and dungeon.name or "none"
        local mapIDCount     = KwikTipDB.mapIDLog     and #KwikTipDB.mapIDLog     or 0
        local encounterCount = KwikTipDB.encounterLog and #KwikTipDB.encounterLog or 0
        local keystoneCount  = KwikTipDB.keystoneLog  and #KwikTipDB.keystoneLog  or 0
        local spellCount     = KwikTipDB.spellLog     and #KwikTipDB.spellLog     or 0
        local snapshotCount  = KwikTipDB.debugSnapshots and #KwikTipDB.debugSnapshots or 0
        local keyLevel, keyAffixes
        if C_ChallengeMode then keyLevel, keyAffixes = C_ChallengeMode.GetActiveKeystoneInfo() end
        print("|cff00ff00KwikTip|r " .. L.DEBUG_HEADING)
        print(string.format(L.DEBUG_STATE,
            tostring(inInstance), tostring(instanceType),
            tostring(KwikTip.bossActive),
            tostring(KwikTip.areaActive), tostring(KwikTip.dungeonActive)))
        print(string.format(L.DEBUG_INSTANCE,
            tostring(instanceID), tostring(mapID), dungeonName))
        print(string.format(L.DEBUG_SUBZONE, subzone or "", tostring(GetPlayerRole())))
        if keyLevel then
            print(string.format(L.DEBUG_KEYSTONE, keyLevel, keyAffixes and #keyAffixes or 0))
        end
        -- Enemy Forces diagnostic — chat only, no new saved var.
        local efDetail = "n/a (not in M+)"
        if C_ScenarioInfo then
            local ok, info = pcall(C_ScenarioInfo.GetScenarioInfo)
            if ok and info then
                local st = info.scenarioType
                local _, _, _, nc = C_ScenarioInfo.GetStepInfo()
                local weighted, qStr, numF, numR
                if nc and nc > 0 then
                    for i = 1, nc do
                        local c = C_ScenarioInfo.GetCriteriaInfo(i)
                        if c and c.isWeightedProgress then
                            weighted, qStr, numF, numR = c.isWeightedProgress, c.quantityString, c.numFulfilled, c.numRequired
                            break
                        end
                    end
                end
                if weighted then
                    efDetail = string.format("type=%s crit=%s weighted=%s q=%q numF=%s numR=%s",
                        SafeStr(st), SafeStr(nc), SafeStr(weighted),
                        SafeStr(qStr), SafeStr(numF), SafeStr(numR))
                else
                    efDetail = string.format("type=%s crit=%s weighted=none", SafeStr(st), SafeStr(nc))
                end
            else
                efDetail = "GetScenarioInfo failed"
            end
        end
        print("|cff00ff00KwikTip|r " .. string.format(L.DEBUG_EF, efDetail))
        print(string.format(L.DEBUG_COUNTS,
            mapIDCount, encounterCount, keystoneCount, spellCount, snapshotCount))
        -- Save snapshot to SavedVariables for post-session inspection.
        if KwikTipDB then
            table.insert(KwikTipDB.debugSnapshots, {
                time              = date("%Y-%m-%d %H:%M:%S"),
                inInstance        = inInstance,
                instanceType      = instanceType,
                instanceID        = instanceID,
                instanceName      = instanceName,
                mapID             = mapID,
                dungeon           = dungeonName,
                subzone           = subzone,
                role              = GetPlayerRole(),
                keystoneLevel     = keyLevel,
                bossActive        = KwikTip.bossActive,
                areaActive        = KwikTip.areaActive,
                dungeonActive     = KwikTip.dungeonActive,
                mapIDLogCount     = mapIDCount,
                encounterLogCount = encounterCount,
                keystoneLogCount  = keystoneCount,
                spellLogCount     = spellCount,
            })
            if #KwikTipDB.debugSnapshots > 100 then
                KwikTipDB.debugSnapshots = KwikTip:PruneArray(KwikTipDB.debugSnapshots, 100)
            end
        end
    elseif cmd == "debuglog" then
        KwikTipDB.debugLog = not KwikTipDB.debugLog
        KwikTip:UpdateContent()
        print(string.format("|cff00ff00KwikTip|r " .. L.DEBUG_LOGGING,
            KwikTipDB.debugLog and L.ENABLED or L.DISABLED))
    elseif cmd == "preview" then
        KwikTip:TogglePreview()
    elseif cmd == "clearlog" then
        KwikTipDB.mapIDLog       = {}
        KwikTipDB.encounterLog   = {}
        KwikTipDB.keystoneLog    = {}
        KwikTipDB.spellLog       = {}
        KwikTipDB.debugSnapshots = {}
        _loggedSpells = {}
        print("|cff00ff00KwikTip|r " .. L.LOGS_CLEARED)
    elseif cmd == "feedback" then
        print("|cff00ff00KwikTip|r " .. L.FEEDBACK_MSG)
    elseif cmd == "support" then
        print("|cff00ff00KwikTip|r " .. L.SUPPORT_MSG)
    elseif cmd == "config" or cmd == "" then
        KwikTip:ToggleConfig()
    elseif cmd == "help" then
        print("|cff00ff00KwikTip|r " .. L.COMMANDS)
        print(L.CMD_OPEN)
        print(L.CMD_MOVE)
        print(L.CMD_PREVIEW)
        print(L.CMD_DEBUG)
        print(L.CMD_DEBUGLOG)
        print(L.CMD_CLEARLOG)
        print(L.CMD_FEEDBACK)
        print(L.CMD_SUPPORT)
        print(L.CMD_HELP)
    else
        print("|cff00ff00KwikTip|r " .. L.CMD_UNKNOWN)
    end
end
