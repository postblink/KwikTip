-- KwikTip: Main entry point
local ADDON_NAME, KwikTip = ...

-- Default settings (merged into KwikTipDB on first load)
KwikTip.DEFAULTS = {
    width             = 220,
    height            = 80,
    alpha             = 0.75,   -- background opacity (0 = invisible, 1 = solid)
    x                 = 0,
    y                 = -200,
    showMinimapButton = true,
    persistentHide    = false,
    showInDungeon     = false,
    minimapAngle      = 225,
    debugLog          = false,
    mapIDLog          = {},
    mobLog            = {},
}

-- ============================================================
-- Event handling
-- ============================================================
local frame = CreateFrame("Frame", "KwikTipFrame", UIParent)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            KwikTip:OnLoad()
        end
    elseif event == "PLAYER_LOGIN" then
        KwikTip:OnLogin()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        KwikTip:UpdateVisibility()
        KwikTip:UpdateContent()
        KwikTip:LogMapID()
    elseif event == "ENCOUNTER_START" then
        local encounterID = ...
        KwikTip:OnEncounterStart(encounterID)
    elseif event == "ENCOUNTER_END" then
        KwikTip:OnEncounterEnd()
    elseif event == "PLAYER_TARGET_CHANGED" then
        KwikTip:OnTargetChanged()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        KwikTip:OnMouseoverUnit()
    end
end)

-- ============================================================
-- Lifecycle
-- ============================================================

function KwikTip:OnLoad()
    KwikTipDB = KwikTipDB or {}
    -- Seed any missing keys with defaults
    for k, v in pairs(self.DEFAULTS) do
        if KwikTipDB[k] == nil then
            KwikTipDB[k] = type(v) == "table" and {} or v
        end
    end
    -- Apply saved settings now so position is restored on /reload.
    -- (PLAYER_LOGIN does not fire on reload, so OnLogin's call is not enough.)
    self:ApplySettings()
end

function KwikTip:OnLogin()
    self:ApplySettings()
    self:InitMinimapButton()
    self:UpdateVisibility()
    self:UpdateContent()
    print("|cff00ff00KwikTip|r loaded. Type /kwik for settings.")
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
    table.insert(KwikTipDB.mapIDLog, {
        mapID        = mapID,
        instanceID   = instanceID,
        instanceName = instanceName,
        instanceType = instanceType,
        subzone      = GetSubZoneText(),
        time         = date("%Y-%m-%d %H:%M:%S"),
    })
    -- Cap log size to avoid SavedVariables bloat
    if #KwikTipDB.mapIDLog > 2000 then
        table.remove(KwikTipDB.mapIDLog, 1)
    end
end

-- ============================================================
-- Export / Import
-- ============================================================

-- Serialize mapIDLog to a compact shareable string.
-- Format: KT1|instanceID:mapID:x,y;x,y;...|...
-- Deduplicates positions (rounded to 3 decimal places) and groups by dungeon.
-- Returns: str, pointCount  (nil, 0 if nothing to export)
function KwikTip:ExportLog()
    if not KwikTipDB.mapIDLog or #KwikTipDB.mapIDLog == 0 then
        return nil, 0
    end

    local groups    = {}  -- gKey → { instanceID, mapID, posSet, positions }
    local groupOrder = {}

    for _, entry in ipairs(KwikTipDB.mapIDLog) do
        if entry.x and entry.y then
            -- Use workingMapID when available: x/y are in that map's coordinate space.
            local posMapID = entry.workingMapID or entry.mapID or 0
            local gKey = (entry.instanceID or 0) .. ":" .. posMapID
            if not groups[gKey] then
                groups[gKey] = {
                    instanceID = entry.instanceID or 0,
                    mapID      = posMapID,
                    posSet     = {},
                    positions  = {},
                }
                table.insert(groupOrder, gKey)
            end
            local g  = groups[gKey]
            local rx = string.format("%.3f", tonumber(entry.x))
            local ry = string.format("%.3f", tonumber(entry.y))
            local pk = rx .. "," .. ry
            if not g.posSet[pk] then
                g.posSet[pk] = true
                table.insert(g.positions, pk)
            end
        end
    end

    local totalPoints = 0
    local parts       = { "KT1" }
    for _, gKey in ipairs(groupOrder) do
        local g = groups[gKey]
        if #g.positions > 0 then
            table.insert(parts, g.instanceID .. ":" .. g.mapID .. ":" .. table.concat(g.positions, ";"))
            totalPoints = totalPoints + #g.positions
        end
    end

    if #parts == 1 then return nil, 0 end
    return table.concat(parts, "|"), totalPoints
end

-- Parse an export string and merge new positions into mapIDLog.
-- Returns: added (number), errMsg (string or nil)
function KwikTip:ImportLog(str)
    if not str or str == "" then return 0, "Empty string." end

    local rest = str:match("^KT1|(.+)$")
    if not rest then return 0, "Unrecognised format — expected a KT1 export string." end

    -- Build a set of existing positions for deduplication
    local existingSet = {}
    for _, entry in ipairs(KwikTipDB.mapIDLog) do
        if entry.x and entry.y then
            local k = (entry.instanceID or 0) .. ":" .. (entry.mapID or 0) .. ":" .. entry.x .. ":" .. entry.y
            existingSet[k] = true
        end
    end

    local added = 0
    for segment in rest:gmatch("[^|]+") do
        local iID, mID, posPart = segment:match("^(%d+):(%d+):(.+)$")
        if iID and mID and posPart then
            iID = tonumber(iID)
            mID = tonumber(mID)
            for pos in posPart:gmatch("[^;]+") do
                local x, y = pos:match("^([%d%.]+),([%d%.]+)$")
                if x and y then
                    local k = iID .. ":" .. mID .. ":" .. x .. ":" .. y
                    if not existingSet[k] then
                        existingSet[k] = true
                        table.insert(KwikTipDB.mapIDLog, {
                            mapID        = mID,
                            instanceID   = iID,
                            instanceName = "imported",
                            instanceType = "party",
                            time         = "imported",
                            x            = x,
                            y            = y,
                        })
                        added = added + 1
                    end
                end
            end
        end
    end

    -- Honour the existing cap
    while #KwikTipDB.mapIDLog > 2000 do
        table.remove(KwikTipDB.mapIDLog, 1)
    end

    return added, nil
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
        print(string.format("  inInstance=%s  type=%s  boss=%s  trash=%s  area=%s  dungeon=%s",
            tostring(inInstance), tostring(instanceType),
            tostring(KwikTip.bossActive), tostring(KwikTip.trashActive),
            tostring(KwikTip.areaActive), tostring(KwikTip.dungeonActive)))
        print(string.format("  instanceID=%s  mapID=%s  dungeon=%s",
            tostring(instanceID), tostring(mapID), dungeon and dungeon.name or "none"))
        print(string.format("  subzone=%q", subzone or ""))
        print(string.format("  mapIDLog=%d  mobLog=%d",
            KwikTipDB.mapIDLog and #KwikTipDB.mapIDLog or 0,
            KwikTipDB.mobLog   and #KwikTipDB.mobLog   or 0))
    elseif cmd == "export" then
        KwikTip:ShowDataDialog()
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
        print("  /kwik export   — open position data export/import dialog")
        print("  /kwik clearlog — clear mapIDLog and mobLog")
    end
end
