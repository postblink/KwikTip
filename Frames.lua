-- KwikTip: HUD frame and layout API
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- HUD Frame
-- ============================================================
local hud
local contentText
local cornerHandles = {}

-- ============================================================
-- Drag and resize support
-- ============================================================

local function SaveHUDLayout()
    KwikTipDB.width  = math.floor(hud:GetWidth()  + 0.5)
    KwikTipDB.height = math.floor(hud:GetHeight() + 0.5)
    KwikTipDB.x      = math.floor(hud:GetLeft()   + hud:GetWidth()  / 2 - UIParent:GetWidth()  / 2 + 0.5)
    KwikTipDB.y      = math.floor(hud:GetBottom()  + hud:GetHeight() / 2 - UIParent:GetHeight() / 2 + 0.5)
end

function KwikTip:InitHUD()
    if self.HUD then return end

    hud = CreateFrame("Frame", "KwikTipHUD", UIParent, "BackdropTemplate")
    self.HUD = hud

    hud:SetFrameStrata("MEDIUM")
    hud:SetClampedToScreen(true)
    hud:SetMovable(true)
    hud:SetResizable(true)
    hud:SetResizeBounds(100, 40, 600, 400)
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
    contentText = hud:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contentText:SetPoint("TOPLEFT",     hud, "TOPLEFT",     6, -6)
    contentText:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT", -6,  6)
    contentText:SetJustifyH("LEFT")
    contentText:SetJustifyV("TOP")
    contentText:SetWordWrap(true)
    contentText:SetText("")
    KwikTip.HUDText = contentText

    hud:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    hud:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        SaveHUDLayout()
    end)

    -- Corner resize handles — small gold squares, visible only in move mode.
    for _, c in ipairs({
        { point = "TOPLEFT",     dir = "TOPLEFT"     },
        { point = "TOPRIGHT",    dir = "TOPRIGHT"    },
        { point = "BOTTOMLEFT",  dir = "BOTTOMLEFT"  },
        { point = "BOTTOMRIGHT", dir = "BOTTOMRIGHT" },
    }) do
        local handle = CreateFrame("Frame", nil, hud)
        handle:SetSize(7, 7)
        handle:SetPoint(c.point)
        handle:SetFrameLevel(hud:GetFrameLevel() + 2)
        handle:EnableMouse(true)
        handle:Hide()

        local tex = handle:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(1, 0.82, 0, 0.9)
        tex:SetAllPoints(handle)

        local dir = c.dir
        handle:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                hud:StartSizing(dir)
            end
        end)
        handle:SetScript("OnMouseUp", function()
            hud:StopMovingOrSizing()
            SaveHUDLayout()
        end)

        table.insert(cornerHandles, handle)
    end
end

-- ============================================================
-- Public API
-- ============================================================

-- Apply saved settings to the HUD (size, opacity, position).
function KwikTip:ApplySettings()
    if not hud then return end
    local db = KwikTipDB
    hud:SetSize(db.width, db.height)
    hud:SetBackdropColor(0, 0, 0, db.alpha)
    hud:ClearAllPoints()
    hud:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)
end

-- Show the HUD when any active state warrants it, or when move mode is active.
--   bossActive  : ENCOUNTER_START is in progress
--   trashActive : player is targeting a known trash mob
--   areaActive  : player is inside a named area bounding box
-- Respects the persistentHide flag set from the config window.
function KwikTip:UpdateVisibility()
    if KwikTipDB.persistentHide and not self.moveMode then
        if hud then hud:Hide() end
        return
    end

    if self.moveMode or self.bossActive or self.bossTargetActive or self.trashActive or self.areaActive or self.dungeonActive then
        self:InitHUD()
        hud:Show()
    else
        if hud then hud:Hide() end
    end
end

-- Toggle between move mode (draggable, gold border) and locked mode.
-- Config.lua defines _UpdateConfigMoveBtn; it will be a no-op until that file loads.
function KwikTip:ToggleMoveMode()
    self:InitHUD()
    self.moveMode = not self.moveMode

    if self.moveMode then
        hud:EnableMouse(true)
        hud:Show()
        hud:SetBackdropBorderColor(1, 0.82, 0, 1)  -- gold outline = move mode active
    else
        hud:EnableMouse(false)
        hud:SetBackdropBorderColor(0, 0, 0, 1)
        SaveHUDLayout()
        self:UpdateContent()
        self:UpdateVisibility()
    end

    for _, handle in ipairs(cornerHandles) do
        if self.moveMode then handle:Show() else handle:Hide() end
    end

    -- Sync the button label in the config window if it is open
    if self._UpdateConfigMoveBtn then
        self:_UpdateConfigMoveBtn()
    end
end

-- ============================================================
-- Set the text displayed inside the HUD box.
-- Guards against redundant SetText calls when content hasn't changed.
function KwikTip:SetContent(str)
    str = str or ""
    if self._lastContent == str then return end
    self._lastContent = str
    if not contentText then self:InitHUD() end
    contentText:SetText(str)
end
