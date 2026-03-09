-- KwikTip: Initialization & Defaults
local ADDON_NAME, KwikTip = ...

KwikTip.DEFAULTS = {
    width          = 220,
    height         = 80,
    alpha          = 0.75,   -- background opacity (0 = invisible, 1 = solid)
    x              = 0,
    y              = -200,
    persistentHide = false,
    showInDungeon  = false,
    showMinimapBtn = true,
    printChannel   = "NONE",
    fontPath       = "Fonts\\FRIZQT__.TTF",
    fontName       = "Friz Quadrata",
    fontSize       = 11,
    minimapAngle   = 0,      -- radians; position around minimap
    debugLog       = false,
    mapIDLog       = {},
    mobLog         = {},
    encounterLog   = {},     -- always-on; records every ENCOUNTER_START encounterID seen
    debugSnapshots = {},     -- written by /kwik debug; inspection log for post-session review
}

-- ============================================================
-- Event handling
-- ============================================================
local frame = CreateFrame("Frame", "KwikTipInitFrame", UIParent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            KwikTip:OnLoad()
        end
    elseif event == "PLAYER_LOGIN" then
        KwikTip:OnLogin()
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
    if self.InitHUD then self:InitHUD() end
    if self.ApplySettings then self:ApplySettings() end
end

function KwikTip:OnLogin()
    if self.InitHUD then self:InitHUD() end
    if self.ApplySettings then self:ApplySettings() end
    if self.UpdateVisibility then self:UpdateVisibility() end
    if self.UpdateContent then self:UpdateContent() end
    if self._PlaceMinimapBtn then self:_PlaceMinimapBtn() end
    print("|cff00ff00KwikTip|r loaded. Type /kwik for settings.")
end
