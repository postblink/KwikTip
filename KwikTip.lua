-- KwikTip: Main entry point
local ADDON_NAME, KwikTip = ...

-- Default settings (merged into KwikTipDB on first load)
KwikTip.DEFAULTS = {
    width             = 220,
    height            = 80,
    alpha             = 0.75,   -- background opacity (0 = invisible, 1 = solid)
    point             = "CENTER",
    x                 = 0,
    y                 = -200,
    showMinimapButton = true,
    persistentHide    = false,
    minimapAngle      = 225,
    debugLog          = false,
    mapIDLog          = {},
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
            KwikTipDB[k] = v
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
    local instanceName = GetInstanceInfo()
    table.insert(KwikTipDB.mapIDLog, {
        mapID        = mapID,
        instanceName = instanceName,
        instanceType = instanceType,
        time         = date("%Y-%m-%d %H:%M:%S"),
    })
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
        local mapID   = C_Map.GetBestMapForUnit("player")
        local dungeon = mapID and KwikTip.DUNGEON_BY_UIMAPID[mapID]
        print("|cff00ff00KwikTip|r debug:")
        print(string.format("  inInstance=%s  type=%s", tostring(inInstance), tostring(instanceType)))
        print(string.format("  mapID=%s  dungeon=%s", tostring(mapID), dungeon and dungeon.name or "none"))
    elseif cmd == "config" or cmd == "" then
        KwikTip:ToggleConfig()
    else
        print("|cff00ff00KwikTip|r commands:")
        print("  /kwik          — open settings")
        print("  /kwik move     — toggle move/lock mode")
        print("  /kwik debug    — print detection state")
    end
end
