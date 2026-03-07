-- KwikTip: Core.lua (Event tracking, logging, commands, detection)
local ADDON_NAME, KwikTip = ...

local frame = CreateFrame("Frame", "KwikTipCoreFrame", UIParent)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
-- PLAYER_TARGET_CHANGED and UPDATE_MOUSEOVER_UNIT are registered dynamically
-- inside UpdateContent() only while the player is inside a supported instance.
frame:SetScript("OnEvent", function(self, event, ...)     if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then         KwikTip:UpdateContent()         KwikTip:UpdateVisibility()         KwikTip:LogMapID()     elseif event == "ENCOUNTER_START" then         local encounterID = ...         KwikTip:OnEncounterStart(encounterID)     elseif event == "ENCOUNTER_END" then         local _, _, _, _, success = ...         KwikTip:OnEncounterEnd(success)     elseif event == "PLAYER_TARGET_CHANGED" then         KwikTip:OnTargetChanged()     elseif event == "UPDATE_MOUSEOVER_UNIT" then         KwikTip:OnMouseoverUnit()     end end)

local GOLD  = "|cffffcc00"
local WHITE = "|cffffffff"
local GRAY  = "|cff999999"
local RESET = "|r"

-- Build the HUD string for an active boss encounter.
local function FormatBossContent(dungeon, boss)
    local header = GOLD .. dungeon.name .. RESET .. "\n" .. WHITE .. boss.name .. RESET
    if boss.tip and boss.tip ~= "" then
        return header .. "\n" .. GRAY .. boss.tip .. RESET
    end
    return header
end

-- Build the HUD string for a trash mob target.
local function FormatTrashContent(dungeon, mob)
    local header = GOLD .. dungeon.name .. RESET .. "\n" .. WHITE .. mob.name .. RESET
    if mob.tip and mob.tip ~= "" then
        return header .. "\n" .. GRAY .. mob.tip .. RESET
    end
    return header
end

-- Build the HUD string for the current sub-zone area.
-- Matches GetSubZoneText() against dungeon.areas[].subzone.
-- If the area entry has a bossIndex field, the boss tip is shown instead
-- of a generic area tip — used for boss room sub-zones so the tip appears
-- as the group enters, before ENCOUNTER_START fires.
-- Returns nil if the current sub-zone has no defined tip.
local function FormatAreaContent(dungeon)
    local subzone = GetSubZoneText()
    if not subzone or subzone == "" then return nil end
    for _, a in ipairs(dungeon.areas) do
        if a.subzone == subzone then
            if a.bossIndex then
                local boss = dungeon.bosses[a.bossIndex]
                if boss then
                    return FormatBossContent(dungeon, boss)
                end
            end
            return GOLD .. dungeon.name .. RESET .. "\n"
                .. WHITE .. subzone .. RESET .. "\n"
                .. GRAY .. (a.tip or "") .. RESET
        end
    end
    return nil
end

-- ============================================================
-- Debug sub-zone ticker
-- Logs when the player enters a new sub-zone inside an instance.
-- Fires on a 2 s poll as a safety net; ZONE_CHANGED events handle
-- most transitions and drive UpdateContent directly.
-- Gated on the debugLog setting.
-- ============================================================

local debugTicker

local function StopDebugTicker()
    if debugTicker then
        debugTicker:Cancel()
        debugTicker = nil
    end
end

local function StartDebugTicker()
    if not KwikTipDB or not KwikTipDB.debugLog then return end
    if debugTicker then return end
    debugTicker = C_Timer.NewTicker(2, function()
        local subzone = GetSubZoneText() or ""
        local mapID   = C_Map.GetBestMapForUnit("player")
        -- Skip if LogMapID (event-driven) already captured this exact state.
        if subzone == KwikTip._lastSubzone and mapID == KwikTip._lastMapID then return end
        local instanceName, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
        local dungeon = instanceID and KwikTip.DUNGEON_BY_INSTANCEID[instanceID]
        print(string.format("|cff00ff00KwikTip|r subzone=%q  %s  mapID=%s  instanceID=%s",
            subzone,
            dungeon and dungeon.name or (instanceName or "unknown"),
            tostring(mapID),
            tostring(instanceID)))
        table.insert(KwikTipDB.mapIDLog, {
            mapID        = mapID,
            instanceID   = instanceID,
            instanceName = instanceName,
            instanceType = instanceType,
            subzone      = subzone,
            time         = date("%Y-%m-%d %H:%M:%S"),
        })
        -- Update shared dedup state so LogMapID won't re-log this.
        KwikTip._lastSubzone    = subzone
        KwikTip._lastMapID      = mapID
        KwikTip._lastInstanceID = instanceID
        if #KwikTipDB.mapIDLog > 2000 then
            KwikTipDB.mapIDLog = KwikTip:PruneArray(KwikTipDB.mapIDLog, 2000)
        end
    end)
end

-- ============================================================
-- Boss encounter state
-- ============================================================

-- Called by ENCOUNTER_START. Locks the HUD to the boss tip for the fight duration.
function KwikTip:OnEncounterStart(encounterID)
    self.bossActive = true
    StopDebugTicker()
    local entry = KwikTip.BOSS_BY_ENCOUNTERID[encounterID]
    if entry then
        self:SetContent(FormatBossContent(entry.dungeon, entry.boss))
    else
        self:SetContent(GRAY .. "No tip for this boss." .. RESET)
    end
    self:UpdateVisibility()
end

-- Called by ENCOUNTER_END. On a kill, leaves the boss tip visible until the
-- next natural tip trigger (area change, trash target, or new encounter).
-- On a wipe/reset, restores normal area/trash detection immediately.
function KwikTip:OnEncounterEnd(success)
    self.bossActive = false
    if success == 1 then
        -- Boss killed — leave current tip up; resume debug ticker if needed.
        StartDebugTicker()
        self:UpdateVisibility()
    else
        -- Wipe or reset — clear and return to normal detection.
        self.bossTargetActive = false
        self:SetContent("")
        self:UpdateContent()
        self:UpdateVisibility()
    end
end

-- ============================================================
-- Mob logging
-- ============================================================
-- Logs the NPC name, sub-zone, and instance context when targeting or
-- mousing over a hostile NPC, for future trash tip data collection.

local _lastLoggedNpcID = nil  -- deduplicate mouseover spam

local function LogMobPosition(npcID, unitToken)
    if not KwikTipDB or not KwikTipDB.debugLog then return end
    local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    table.insert(KwikTipDB.mobLog, {
        npcID        = npcID,
        npcName      = UnitName(unitToken),
        mapID        = C_Map.GetBestMapForUnit("player"),
        instanceID   = instanceID,
        instanceName = instanceName,
        subzone      = GetSubZoneText(),
        time         = date("%Y-%m-%d %H:%M:%S"),
    })
    if #KwikTipDB.mobLog > 5000 then
        KwikTipDB.mobLog = KwikTip:PruneArray(KwikTipDB.mobLog, 5000)
    end
    _lastLoggedNpcID = npcID
end

-- ============================================================
-- Trash target state
-- ============================================================

-- Called by PLAYER_TARGET_CHANGED. Logs the mob and shows a tip if known.
-- Logging always runs (regardless of areaActive) so mob data is collected even
-- in named sub-zones. The HUD display is still gated: area tips take priority
-- over trash tips and trashActive is only set when no area tip is shown.
function KwikTip:OnTargetChanged()
    local guid = UnitGUID("target")
    if self.bossActive then return end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario") then
        if self.trashActive or self.bossTargetActive then
            self.trashActive = false
            self.bossTargetActive = false
            self:UpdateVisibility()
        end
        return
    end
    if guid then
        local npcID = C_CreatureInfo.GetCreatureID(guid)
        if npcID then
            LogMobPosition(npcID, "target")  -- log dead or alive; areaActive must not gate this
        end
        if npcID and UnitCanAttack("player", "target") then
            -- Boss NPC check — shows tip before ENCOUNTER_START fires (e.g. rooms with no subzone text).
            local bossEntry = KwikTip.BOSS_BY_NPCID[npcID]
            if bossEntry then
                self.bossTargetActive = true
                self.trashActive = false
                self:SetContent(FormatBossContent(bossEntry.dungeon, bossEntry.boss))
                self:UpdateVisibility()
                return
            end
            if not self.areaActive then
                local entry = KwikTip.TRASH_BY_NPCID[npcID]
                if entry then
                    self.bossTargetActive = false
                    self.trashActive = true
                    self:SetContent(FormatTrashContent(entry.dungeon, entry.mob))
                    self:UpdateVisibility()
                    return
                end
            end
        end
    end

    -- No known target — clear boss target and trash state.
    if self.trashActive or self.bossTargetActive then
        self.trashActive = false
        self.bossTargetActive = false
        self:SetContent("")
        self:UpdateContent()
        self:UpdateVisibility()
    end
end

-- Called by UPDATE_MOUSEOVER_UNIT. Logs NPC; deduplicates against last logged npcID.
function KwikTip:OnMouseoverUnit()
    if not KwikTipDB or not KwikTipDB.debugLog then return end
    if self.bossActive then return end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario") then return end

    local guid = UnitGUID("mouseover")
    if not guid then return end
    local npcID = C_CreatureInfo.GetCreatureID(guid)
    if not npcID then return end
    if not UnitCanAttack("player", "mouseover") then return end
    if npcID == _lastLoggedNpcID then return end

    LogMobPosition(npcID, "mouseover")
end

-- ============================================================
-- Detection
-- ============================================================

-- Identify the current dungeon and update HUD content.
-- Area detection uses GetSubZoneText() matched against dungeon.areas[].subzone.
-- ZONE_CHANGED fires on sub-zone transitions so no polling ticker is needed
-- for area updates — events drive UpdateContent directly.
function KwikTip:UpdateContent()
    if self.bossActive or self.bossTargetActive then return end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario") then
        StopDebugTicker()
        self.areaActive    = false
        self.dungeonActive = false
        self.trashActive   = false
        self:SetContent("")
        if self._targetEventsRegistered then
            frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
            frame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
            self._targetEventsRegistered = false
        end
        return
    end

    if not self._targetEventsRegistered then
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        self._targetEventsRegistered = true
    end

    -- Primary lookup: instanceID from GetInstanceInfo()
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local dungeon = instanceID and KwikTip.DUNGEON_BY_INSTANCEID[instanceID]

    -- Fallback: uiMapID for dungeons with instanceID = 0
    if not dungeon then
        local mapID = C_Map.GetBestMapForUnit("player")
        dungeon = mapID and KwikTip.DUNGEON_BY_UIMAPID[mapID]
    end

    -- Manage debug ticker
    if KwikTipDB and KwikTipDB.debugLog then
        StartDebugTicker()
    else
        StopDebugTicker()
    end

    local prevAreaActive    = self.areaActive
    local prevDungeonActive = self.dungeonActive

    -- DungeonData area tips take priority. Trash target info is a secondary
    -- fallback used only when no area tip is defined for the current sub-zone.
    local areaContent = dungeon and dungeon.areas and FormatAreaContent(dungeon)

    if areaContent then
        self.trashActive   = false
        self.areaActive    = true
        self.dungeonActive = false
        self:SetContent(areaContent)
    elseif self.trashActive then
        -- Known trash target is already displayed; nothing to update.
        return
    elseif dungeon and KwikTipDB.showInDungeon then
        -- No area match and no trash — keep HUD open with a holding message.
        self.areaActive    = false
        self.dungeonActive = true
        self:SetContent(GRAY .. "Waiting for relevant encounter..." .. RESET)
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
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario") then return end
    
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

    table.insert(KwikTipDB.mapIDLog, {
        mapID        = mapID,
        instanceID   = instanceID,
        instanceName = instanceName,
        instanceType = instanceType,
        subzone      = subzone,
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
        local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
        local dungeon = (instanceID and KwikTip.DUNGEON_BY_INSTANCEID[instanceID])
            or (mapID and KwikTip.DUNGEON_BY_UIMAPID[mapID])
        local subzone = GetSubZoneText()
        print("|cff00ff00KwikTip|r debug:")
        print(string.format("  inInstance=%s  type=%s  boss=%s  bossTarget=%s  trash=%s  area=%s  dungeon=%s",
            tostring(inInstance), tostring(instanceType),
            tostring(KwikTip.bossActive), tostring(KwikTip.bossTargetActive),
            tostring(KwikTip.trashActive),
            tostring(KwikTip.areaActive), tostring(KwikTip.dungeonActive)))
        print(string.format("  instanceID=%s  mapID=%s  dungeon=%s",
            tostring(instanceID), tostring(mapID), dungeon and dungeon.name or "none"))
        print(string.format("  subzone=%q", subzone or ""))
        print(string.format("  mapIDLog=%d  mobLog=%d",
            KwikTipDB.mapIDLog and #KwikTipDB.mapIDLog or 0,
            KwikTipDB.mobLog   and #KwikTipDB.mobLog   or 0))
    elseif cmd == "clearlog" then
        KwikTipDB.mapIDLog = {}
        KwikTipDB.mobLog   = {}
        print("|cff00ff00KwikTip|r mapIDLog and mobLog cleared.")
    elseif cmd == "config" or cmd == "" then
        KwikTip:ToggleConfig()
    else
        print("|cff00ff00KwikTip|r commands:")
        print("  /kwik          — open settings")
        print("  /kwik move     — toggle move/lock mode")
        print("  /kwik debug    — print detection state and position")
        print("  /kwik clearlog — clear mapIDLog and mobLog")
    end
end
