-- Forever-specific detection guards; the shared Retail engine is unchanged.
local ADDON_NAME, KwikTip = ...

local function inDungeon(dungeon)
    local inInstance, instanceType = IsInInstance()
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    return inInstance and instanceType == "party" and instanceID == dungeon.instanceID
end

local OnEncounterStart = KwikTip.OnEncounterStart
function KwikTip:OnEncounterStart(encounterID, ...)
    local entry = self.BOSS_BY_ENCOUNTERID[encounterID]
    if entry and not inDungeon(entry.dungeon) then
        self:UpdateContent()
        self:UpdateVisibility()
        return
    end
    OnEncounterStart(self, encounterID, ...)
    -- The shared handler logs an unknown encounter and clears its entry, but
    -- can leave bossActive from a previous fight. Fail closed instead of
    -- retaining that previous fight's tip indefinitely.
    if not entry and self.bossActive then
        self.bossActive = false
        self:UpdateContent()
        self:UpdateVisibility()
    end
end

local UpdateContent = KwikTip.UpdateContent
function KwikTip:UpdateContent()
    -- A zone change can arrive without ENCOUNTER_END (teleport/disconnect).
    -- Clear a stale fight before the shared engine's bossActive early return.
    if self._activeBossEntry and not inDungeon(self._activeBossEntry.dungeon) then
        self._activeBossEntry = nil
        self._activeEncounterID = nil
        self._activeEncounterName = nil
        self._activeDifficultyID = nil
        self.bossActive = false
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
