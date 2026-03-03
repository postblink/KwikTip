-- KwikTip: Config window and minimap button
local ADDON_NAME, KwikTip = ...

local MINIMAP_RADIUS = 80

-- ============================================================
-- Minimap Button
-- ============================================================
local minimapBtn = CreateFrame("Button", "KwikTipMinimapBtn", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:SetClampedToScreen(true)
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:Hide()
KwikTip.MinimapBtn = minimapBtn

local mmIcon = minimapBtn:CreateTexture(nil, "BACKGROUND")
mmIcon:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktmini.tga")
mmIcon:SetBlendMode("BLEND")
mmIcon:SetSize(31, 31)
mmIcon:SetPoint("CENTER")


local mmHighlight = minimapBtn:CreateTexture(nil, "HIGHLIGHT")
mmHighlight:SetColorTexture(1, 1, 1, 0.2)
mmHighlight:SetAllPoints(minimapBtn)

minimapBtn:SetScript("OnClick", function(self, btn)
    if btn == "LeftButton" then
        KwikTip:ToggleConfig()
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("KwikTip")
    GameTooltip:AddLine("Click to open settings", 1, 1, 1)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Drag around the minimap edge
minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local cx, cy   = Minimap:GetCenter()
        local scale    = UIParent:GetEffectiveScale()
        local px, py   = GetCursorPosition()
        px, py         = px / scale, py / scale
        KwikTipDB.minimapAngle = math.deg(math.atan2(py - cy, px - cx))
        KwikTip:_PlaceMinimapBtn()
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

local function _PlaceMinimapBtn()
    local angle = KwikTipDB and KwikTipDB.minimapAngle or 225
    local x = math.cos(math.rad(angle)) * MINIMAP_RADIUS
    local y = math.sin(math.rad(angle)) * MINIMAP_RADIUS
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function KwikTip:_PlaceMinimapBtn()
    _PlaceMinimapBtn()
end

-- ============================================================
-- Config Window
-- ============================================================
local cfg = CreateFrame("Frame", "KwikTipConfig", UIParent, "BasicFrameTemplate")
cfg:SetSize(280, 512)
cfg:SetPoint("CENTER")
cfg:SetFrameStrata("HIGH")
cfg:SetMovable(true)
cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", cfg.StartMoving)
cfg:SetScript("OnDragStop",  cfg.StopMovingOrSizing)
cfg:SetClampedToScreen(true)
cfg:Hide()
KwikTip.Config = cfg

cfg.TitleText:SetText("KwikTip Settings")

local titleIcon = cfg:CreateTexture(nil, "OVERLAY")
titleIcon:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktmini.tga")
titleIcon:SetBlendMode("BLEND")
titleIcon:SetSize(16, 16)
titleIcon:SetPoint("RIGHT", cfg.TitleText, "LEFT", -4, 0)

-- ---- POSITION section ----------------------------------------
local posHeader = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
posHeader:SetPoint("TOPLEFT", cfg, "TOPLEFT", 12, -32)
posHeader:SetText("POSITION")
posHeader:SetTextColor(0.6, 0.6, 0.6)

local moveBtn = CreateFrame("Button", "KwikTipConfigMoveBtn", cfg, "UIPanelButtonTemplate")
moveBtn:SetSize(110, 22)
moveBtn:SetPoint("TOPLEFT", posHeader, "BOTTOMLEFT", 0, -6)
moveBtn:SetText("Move Window")

moveBtn:SetScript("OnClick", function()
    KwikTip:ToggleMoveMode()
end)

-- X/Y position rows with pixel nudge and manual entry
local posXEdit, posYEdit  -- forward-declared so ApplyXY closure can reference them

local function ApplyXY(x, y)
    x = math.floor(tonumber(x) or KwikTipDB.x or 0)
    y = math.floor(tonumber(y) or KwikTipDB.y or 0)
    KwikTipDB.x = x
    KwikTipDB.y = y
    KwikTip.HUD:ClearAllPoints()
    KwikTip.HUD:SetPoint(KwikTipDB.point or "CENTER", UIParent, "CENTER", x, y)
    posXEdit:SetText(tostring(x))
    posYEdit:SetText(tostring(y))
end

local function MakeNudgeRow(label, parent, anchor)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetSize(256, 24)
    wrap:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)

    local lbl = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", wrap, "LEFT", 0, 0)
    lbl:SetText(label)
    lbl:SetWidth(18)

    local minusBtn = CreateFrame("Button", nil, wrap, "UIPanelButtonTemplate")
    minusBtn:SetSize(24, 22)
    minusBtn:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
    minusBtn:SetText("-")

    local ebBg = CreateFrame("Frame", nil, wrap, "BackdropTemplate")
    ebBg:SetSize(72, 22)
    ebBg:SetPoint("LEFT", minusBtn, "RIGHT", 2, 0)
    ebBg:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    ebBg:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    ebBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local eb = CreateFrame("EditBox", nil, ebBg)
    eb:SetSize(66, 18)
    eb:SetPoint("CENTER", ebBg, "CENTER")
    eb:SetFontObject(GameFontNormal)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(8)
    eb:SetJustifyH("CENTER")

    local plusBtn = CreateFrame("Button", nil, wrap, "UIPanelButtonTemplate")
    plusBtn:SetSize(24, 22)
    plusBtn:SetPoint("LEFT", ebBg, "RIGHT", 2, 0)
    plusBtn:SetText("+")

    return wrap, eb, minusBtn, plusBtn
end

local posXRow, posXMinus, posXPlus
posXRow, posXEdit, posXMinus, posXPlus = MakeNudgeRow("X:", cfg, moveBtn)
posXEdit:SetScript("OnEnterPressed", function(self)
    ApplyXY(self:GetText(), KwikTipDB.y)
    self:ClearFocus()
end)
posXEdit:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(math.floor(KwikTipDB.x or 0)))
    self:ClearFocus()
end)
posXMinus:SetScript("OnClick", function() ApplyXY((KwikTipDB.x or 0) - 1, KwikTipDB.y) end)
posXPlus:SetScript("OnClick",  function() ApplyXY((KwikTipDB.x or 0) + 1, KwikTipDB.y) end)

local posYRow, posYMinus, posYPlus
posYRow, posYEdit, posYMinus, posYPlus = MakeNudgeRow("Y:", cfg, posXRow)
posYEdit:SetScript("OnEnterPressed", function(self)
    ApplyXY(KwikTipDB.x, self:GetText())
    self:ClearFocus()
end)
posYEdit:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(math.floor(KwikTipDB.y or 0)))
    self:ClearFocus()
end)
posYMinus:SetScript("OnClick", function() ApplyXY(KwikTipDB.x, (KwikTipDB.y or 0) - 1) end)
posYPlus:SetScript("OnClick",  function() ApplyXY(KwikTipDB.x, (KwikTipDB.y or 0) + 1) end)

-- ---- DISPLAY section -----------------------------------------
local dispHeader = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dispHeader:SetPoint("TOPLEFT", posYRow, "BOTTOMLEFT", 0, -14)
dispHeader:SetText("DISPLAY")
dispHeader:SetTextColor(0.6, 0.6, 0.6)

-- Checkbox: Show Minimap Button
local showMinimapCB = CreateFrame("CheckButton", "KwikTipShowMinimapCB", cfg, "UICheckButtonTemplate")
showMinimapCB:SetSize(24, 24)
showMinimapCB:SetPoint("TOPLEFT", dispHeader, "BOTTOMLEFT", 0, -4)

local showMinimapLbl = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
showMinimapLbl:SetPoint("LEFT", showMinimapCB, "RIGHT", 2, 0)
showMinimapLbl:SetText("Show Minimap Button")

showMinimapCB:SetScript("OnClick", function(self)
    KwikTipDB.showMinimapButton = self:GetChecked()
    KwikTip:UpdateMinimapButton()
end)

-- Checkbox: Hide Info Window
local hideHUDCB = CreateFrame("CheckButton", "KwikTipHideHUDCB", cfg, "UICheckButtonTemplate")
hideHUDCB:SetSize(24, 24)
hideHUDCB:SetPoint("TOPLEFT", showMinimapCB, "BOTTOMLEFT", 0, -2)

local hideHUDLbl = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hideHUDLbl:SetPoint("LEFT", hideHUDCB, "RIGHT", 2, 0)
hideHUDLbl:SetText("Hide Info Window")

hideHUDCB:SetScript("OnClick", function(self)
    KwikTipDB.persistentHide = self:GetChecked()
    KwikTip:UpdateVisibility()
end)

-- ---- APPEARANCE section ---------------------------------------
local appHeader = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
appHeader:SetPoint("TOPLEFT", hideHUDCB, "BOTTOMLEFT", 0, -14)
appHeader:SetText("APPEARANCE")
appHeader:SetTextColor(0.6, 0.6, 0.6)

-- Slider factory — no Blizzard template dependencies.
-- Each slider is wrapped in an invisible frame so the whole group
-- (label + track + low/high text) anchors as a single unit.
-- Pass the previous slider's ._wrap as the anchor for subsequent sliders.
local function MakeSlider(name, parent, anchor, minVal, maxVal, step, initLabel, lowText, highText)
    local W = 230

    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetSize(W + 20, 40)
    wrap:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 8, -14)

    -- Dynamic label (updated with current value in OnValueChanged)
    local lbl = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", wrap, "TOPLEFT", 0, 0)
    lbl:SetText(initLabel)

    -- Slider track
    local s = CreateFrame("Slider", name, wrap)
    s:SetSize(W, 12)
    s:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -4)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:EnableMouseWheel(true)

    -- Track fill
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0.2, 0.2, 0.2, 0.9)
    track:SetAllPoints(s)

    -- Thumb
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.75, 0.75, 0.75, 1)
    thumb:SetSize(10, 20)
    s:SetThumbTexture(thumb)

    -- Range labels
    local lo = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lo:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -2)
    lo:SetText(lowText)

    local hi = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hi:SetPoint("TOPRIGHT", s, "BOTTOMRIGHT", 0, -2)
    hi:SetText(highText)

    s:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta * self:GetValueStep())
    end)

    s._lbl  = lbl
    s._wrap = wrap
    return s
end

-- Opacity slider (10–100, stored as 0.10–1.00)
local opacitySlider = MakeSlider(
    "KwikTipOpacitySlider", cfg, appHeader,
    10, 100, 5, "Opacity", "10%", "100%"
)
opacitySlider:SetScript("OnValueChanged", function(self, value)
    local alpha = value / 100
    KwikTipDB.alpha = alpha
    KwikTip.HUD:SetBackdropColor(0, 0, 0, alpha)
    self._lbl:SetText(string.format("Opacity: %d%%", value))
end)

-- Width/height nudge rows
local widthEdit, heightEdit  -- forward-declared for ApplySize closure

local function ApplySize(w, h)
    w = math.max(100, math.min(600, math.floor(tonumber(w) or KwikTipDB.width or 220)))
    h = math.max(40,  math.min(400, math.floor(tonumber(h) or KwikTipDB.height or 80)))
    KwikTipDB.width  = w
    KwikTipDB.height = h
    KwikTip.HUD:SetSize(w, h)
    widthEdit:SetText(tostring(w))
    heightEdit:SetText(tostring(h))
end

local widthRow, widthMinus, widthPlus
widthRow, widthEdit, widthMinus, widthPlus = MakeNudgeRow("W:", cfg, opacitySlider._wrap)
widthEdit:SetScript("OnEnterPressed", function(self)
    ApplySize(self:GetText(), KwikTipDB.height)
    self:ClearFocus()
end)
widthEdit:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(KwikTipDB.width or 220))
    self:ClearFocus()
end)
widthMinus:SetScript("OnClick", function() ApplySize((KwikTipDB.width or 220) - 1, KwikTipDB.height) end)
widthPlus:SetScript("OnClick",  function() ApplySize((KwikTipDB.width or 220) + 1, KwikTipDB.height) end)

local heightRow, heightMinus, heightPlus
heightRow, heightEdit, heightMinus, heightPlus = MakeNudgeRow("H:", cfg, widthRow)
heightEdit:SetScript("OnEnterPressed", function(self)
    ApplySize(KwikTipDB.width, self:GetText())
    self:ClearFocus()
end)
heightEdit:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(KwikTipDB.height or 80))
    self:ClearFocus()
end)
heightMinus:SetScript("OnClick", function() ApplySize(KwikTipDB.width, (KwikTipDB.height or 80) - 1) end)
heightPlus:SetScript("OnClick",  function() ApplySize(KwikTipDB.width, (KwikTipDB.height or 80) + 1) end)

-- ---- DEBUG section -------------------------------------------
local debugHeader = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
debugHeader:SetPoint("TOPLEFT", heightRow, "BOTTOMLEFT", -8, -14)
debugHeader:SetText("DEBUG")
debugHeader:SetTextColor(0.6, 0.6, 0.6)

local debugLogCB = CreateFrame("CheckButton", "KwikTipDebugLogCB", cfg, "UICheckButtonTemplate")
debugLogCB:SetSize(24, 24)
debugLogCB:SetPoint("TOPLEFT", debugHeader, "BOTTOMLEFT", 0, -4)

local debugLogLbl = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
debugLogLbl:SetPoint("LEFT", debugLogCB, "RIGHT", 2, 0)
debugLogLbl:SetText("Log Map IDs to SavedVariables")

debugLogCB:SetScript("OnClick", function(self)
    KwikTipDB.debugLog = self:GetChecked()
end)

-- Logo at the bottom of the config window (477×200 source → 220×92 display)
local cfgLogo = cfg:CreateTexture(nil, "ARTWORK")
cfgLogo:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktlogo.tga")
cfgLogo:SetBlendMode("BLEND")
cfgLogo:SetSize(220, 120)
cfgLogo:SetPoint("BOTTOM", cfg, "BOTTOM", 0, 16)

-- ============================================================
-- Internal helpers
-- ============================================================

-- Sync the Move button label with the current move mode state.
function KwikTip:_UpdateConfigMoveBtn()
    if self.moveMode then
        moveBtn:SetText("Lock Window")
    else
        moveBtn:SetText("Move Window")
    end
end

-- Populate all controls from KwikTipDB before showing the config.
local function PopulateConfig()
    local db = KwikTipDB
    showMinimapCB:SetChecked(db.showMinimapButton)
    hideHUDCB:SetChecked(db.persistentHide)
    opacitySlider:SetValue(math.floor(db.alpha * 100 + 0.5))
    widthEdit:SetText(tostring(db.width or 220))
    heightEdit:SetText(tostring(db.height or 80))
    debugLogCB:SetChecked(db.debugLog)
    posXEdit:SetText(tostring(math.floor(db.x or 0)))
    posYEdit:SetText(tostring(math.floor(db.y or 0)))
    KwikTip:_UpdateConfigMoveBtn()
end

-- ============================================================
-- Public API
-- ============================================================

function KwikTip:ToggleConfig()
    if cfg:IsShown() then
        cfg:Hide()
    else
        PopulateConfig()
        cfg:Show()
    end
end

-- Show or hide the minimap button based on KwikTipDB.showMinimapButton.
function KwikTip:UpdateMinimapButton()
    if KwikTipDB.showMinimapButton then
        _PlaceMinimapBtn()
        minimapBtn:Show()
    else
        minimapBtn:Hide()
    end
end

-- Called once on login to position and conditionally show the minimap button.
function KwikTip:InitMinimapButton()
    _PlaceMinimapBtn()
    if KwikTipDB.showMinimapButton then
        minimapBtn:Show()
    end
end
