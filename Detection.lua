-- KwikTip: Dungeon detection and HUD content engine
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- Content formatting
-- ============================================================

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
-- Returns nil if the current sub-zone has no defined tip.
local function FormatAreaContent(dungeon)
    local subzone = GetSubZoneText()
    if not subzone or subzone == "" then return nil end
    for _, a in ipairs(dungeon.areas) do
        if a.subzone == subzone then
            return GOLD .. dungeon.name .. RESET .. "\n"
                .. WHITE .. subzone .. RESET .. "\n"
                .. GRAY .. a.tip .. RESET
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
local _lastLoggedSubzone = nil

local function StopDebugTicker()
    if debugTicker then
        debugTicker:Cancel()
        debugTicker = nil
    end
    _lastLoggedSubzone = nil
end

local function StartDebugTicker()
    if not KwikTipDB or not KwikTipDB.debugLog then return end
    if debugTicker then return end
    _lastLoggedSubzone = nil
    debugTicker = C_Timer.NewTicker(2, function()
        local subzone = GetSubZoneText() or ""
        if subzone == _lastLoggedSubzone then return end
        _lastLoggedSubzone = subzone
        local instanceName, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
        local mapID  = C_Map.GetBestMapForUnit("player")
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
        if #KwikTipDB.mapIDLog > 2000 then
            table.remove(KwikTipDB.mapIDLog, 1)
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

-- Called by ENCOUNTER_END. Restores normal area/trash detection.
function KwikTip:OnEncounterEnd()
    self.bossActive = false
    self:SetContent("")
    self:UpdateContent()
    self:UpdateVisibility()
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
        table.remove(KwikTipDB.mobLog, 1)
    end
    _lastLoggedNpcID = npcID
end

-- ============================================================
-- Trash target state
-- ============================================================

-- Called by PLAYER_TARGET_CHANGED. Logs the mob and shows a tip if known.
function KwikTip:OnTargetChanged()
    if self.bossActive then return end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario") then
        if self.trashActive then
            self.trashActive = false
            self:UpdateVisibility()
        end
        return
    end

    local guid = UnitGUID("target")
    if guid then
        local npcID = tonumber(guid:match("-(%d+)-%x+$"))
        if npcID and UnitCanAttack("player", "target") then
            LogMobPosition(npcID, "target")
            local entry = KwikTip.TRASH_BY_NPCID[npcID]
            if entry then
                self.trashActive = true
                self:SetContent(FormatTrashContent(entry.dungeon, entry.mob))
                self:UpdateVisibility()
                return
            end
        end
    end

    -- No known trash target — clear trash state and let area detection take over.
    if self.trashActive then
        self.trashActive = false
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
    local npcID = tonumber(guid:match("-(%d+)-%x+$"))
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
    if self.bossActive then return end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario") then
        StopDebugTicker()
        self.areaActive    = false
        self.dungeonActive = false
        self.trashActive   = false
        self:SetContent("")
        return
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

    -- Trash target takes priority over area/dungeon content.
    if self.trashActive then return end

    local prevAreaActive    = self.areaActive
    local prevDungeonActive = self.dungeonActive

    local areaContent = dungeon and dungeon.areas and FormatAreaContent(dungeon)

    if areaContent then
        self.areaActive    = true
        self.dungeonActive = false
        self:SetContent(areaContent)
    elseif dungeon and KwikTipDB.showInDungeon and dungeon.bosses and dungeon.bosses[1] then
        -- No area match — default to first boss tip when showInDungeon is on.
        self.areaActive    = false
        self.dungeonActive = true
        self:SetContent(FormatBossContent(dungeon, dungeon.bosses[1]))
    else
        self.areaActive    = false
        self.dungeonActive = false
        self:SetContent("")
    end

    if prevAreaActive ~= self.areaActive or prevDungeonActive ~= self.dungeonActive then
        self:UpdateVisibility()
    end
end
