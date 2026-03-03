-- KwikTip: HUD frame and layout API
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- HUD Frame
-- ============================================================
local hud = CreateFrame("Frame", "KwikTipHUD", UIParent, "BackdropTemplate")
KwikTip.HUD = hud

hud:SetFrameStrata("MEDIUM")
hud:SetClampedToScreen(true)
hud:SetMovable(true)
hud:EnableMouse(false)  -- mouse passthrough by default; enabled only in move mode
hud:Hide()

hud:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
})
hud:SetBackdropColor(0, 0, 0, 0.75)
hud:SetBackdropBorderColor(0, 0, 0, 1)

-- Content text label
local contentText = hud:CreateFontString(nil, "OVERLAY", "GameFontNormal")
contentText:SetPoint("TOPLEFT",     hud, "TOPLEFT",     6, -6)
contentText:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT", -6,  6)
contentText:SetJustifyH("LEFT")
contentText:SetJustifyV("TOP")
contentText:SetWordWrap(true)
contentText:SetText("")
KwikTip.HUDText = contentText

-- ============================================================
-- Drag support
-- ============================================================
hud:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)

hud:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    KwikTipDB.point = point
    KwikTipDB.x     = x
    KwikTipDB.y     = y
end)

-- ============================================================
-- Public API
-- ============================================================

-- Apply saved settings to the HUD (size, opacity, position).
function KwikTip:ApplySettings()
    local db = KwikTipDB
    hud:SetSize(db.width, db.height)
    hud:SetBackdropColor(0, 0, 0, db.alpha)
    hud:ClearAllPoints()
    hud:SetPoint(db.point or "CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)
end

-- Show the HUD when in a dungeon/raid, or when move mode is active.
-- Respects the persistentHide flag set from the config window.
function KwikTip:UpdateVisibility()
    if KwikTipDB.persistentHide and not self.moveMode then
        hud:Hide()
        return
    end

    local inInstance, instanceType = IsInInstance()
    local inContent = inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario")

    if self.moveMode or inContent then
        hud:Show()
    else
        hud:Hide()
    end
end

-- Toggle between move mode (draggable, gold border) and locked mode.
-- Config.lua defines _UpdateConfigMoveBtn; it will be a no-op until that file loads.
function KwikTip:ToggleMoveMode()
    self.moveMode = not self.moveMode

    if self.moveMode then
        hud:EnableMouse(true)
        hud:Show()
        hud:SetBackdropBorderColor(1, 0.82, 0, 1)  -- gold outline = move mode active
    else
        hud:EnableMouse(false)
        hud:SetBackdropBorderColor(0, 0, 0, 1)
        -- Persist final position before potentially hiding
        local point, _, _, x, y = hud:GetPoint()
        KwikTipDB.point = point
        KwikTipDB.x     = x
        KwikTipDB.y     = y
        self:UpdateVisibility()
    end

    -- Sync the button label in the config window if it is open
    if self._UpdateConfigMoveBtn then
        self:_UpdateConfigMoveBtn()
    end
end

-- Set the text displayed inside the HUD box.
function KwikTip:SetContent(str)
    contentText:SetText(str or "")
end
