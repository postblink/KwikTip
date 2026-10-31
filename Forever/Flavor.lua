-- Forever-specific detection guards; the shared Retail engine is unchanged.
local ADDON_NAME, KwikTip = ...

local function inDungeon(dungeon)
    local inInstance, instanceType = IsInInstance()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    if not inInstance or instanceType ~= "party" or instanceID ~= dungeon.instanceID then return false end
    if dungeon.difficultyIDs then
        for _, id in ipairs(dungeon.difficultyIDs) do
            if id == difficultyID then return true end
        end
        return false
    end
    return true
end

local function clearBoss(self)
    self._activeBossEntry = nil
    self._activeEncounterID = nil
    self._activeEncounterName = nil
    self._activeDifficultyID = nil
    self.bossActive = false
end

local OnEncounterStart = KwikTip.OnEncounterStart
function KwikTip:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    local entry = self.BOSS_BY_ENCOUNTERID[encounterID]
    local _, _, instanceDifficulty = GetInstanceInfo()
    if entry and (not inDungeon(entry.dungeon) or difficultyID ~= instanceDifficulty) then
        -- A contradictory mode on this dungeon's event invalidates the old
        -- fight lock too. A foreign dungeon's ordinary event does not replace
        -- a valid fight in the current instance.
        if difficultyID ~= instanceDifficulty and self._activeBossEntry
            and self._activeBossEntry.dungeon == entry.dungeon then clearBoss(self) end
        self:UpdateContent()
        self:UpdateVisibility()
        return
    end
    OnEncounterStart(self, encounterID, encounterName, difficultyID, groupSize)
    -- The shared handler logs an unknown encounter and clears its entry, but
    -- can leave bossActive from a previous fight. Fail closed instead of
    -- retaining that previous fight's tip indefinitely.
    if not entry and self.bossActive then
        self.bossActive = false
        self:UpdateContent()
        self:UpdateVisibility()
    end
end

local OnEncounterEnd = KwikTip.OnEncounterEnd
function KwikTip:OnEncounterEnd(success)
    local entry = self._activeBossEntry
    OnEncounterEnd(self, success)
    if success == 1 and entry
        and (entry.dungeon.previewNextBoss == false or not inDungeon(entry.dungeon)) then
        -- Preserve normal encounter cleanup, then restore the overview/quiet
        -- state for dungeons whose actual route has not been verified.
        self:UpdateContent()
        self:UpdateVisibility()
    end
end

local UpdateContent = KwikTip.UpdateContent
function KwikTip:UpdateContent()
    -- A zone change can arrive without ENCOUNTER_END (teleport/disconnect).
    -- Clear a stale fight before the shared engine's bossActive early return.
    if self._activeBossEntry and not inDungeon(self._activeBossEntry.dungeon) then
        clearBoss(self)
    end
    UpdateContent(self)
    if self.previewActive then return end
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local dungeon = self.DUNGEON_BY_INSTANCEID[instanceID]
    if dungeon and not inDungeon(dungeon) then
        self.areaActive, self.dungeonActive = false, false
        self:SetContent("")
        self:UpdateVisibility()
        return
    end
    if self.bossActive or self.areaActive or not KwikTipDB or not KwikTipDB.showInDungeon
        or not dungeon or not dungeon.overview then return end
    local displayName = GetInstanceInfo()
    if not displayName or displayName == "" then displayName = dungeon.name end
    local content = "|cffffcc00" .. displayName .. "|r\n"
        .. "|cffffffffDungeon overview|r\n|cffbbbbbb" .. dungeon.overview .. "|r"
    local key = self:GetNoteKey()
    local note = key and KwikTipDB.notes and KwikTipDB.notes[key]
    if note and note ~= "" then content = content .. "\n|cffffdd88" .. note .. "|r" end
    self.dungeonActive = true
    self:SetContent(content)
    self:UpdateVisibility()
end
