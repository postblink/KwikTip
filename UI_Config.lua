-- KwikTip: Config window & minimap button
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- Minimap Button
-- ============================================================
function KwikTip:_PlaceMinimapBtn()
    if self.MinimapBtn then return end
    if not KwikTipDB.showMinimapBtn then return end

    local btn = CreateFrame("Button", "KwikTipMinimapButton", Minimap)
    btn:SetSize(24, 24)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local tex = btn:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktmini.tga")
    tex:SetBlendMode("BLEND")
    tex:SetAllPoints(btn)

    local function UpdatePosition()
        local angle  = KwikTipDB.minimapAngle or 0
        local radius = (Minimap:GetWidth() / 2) + 5  -- edge of minimap + 5px; matches LibDBIcon behaviour
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
    end

    btn:SetScript("OnShow", UpdatePosition)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            KwikTip:ToggleConfig()
        elseif button == "RightButton" then
            KwikTip:ToggleMoveMode()
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function(frame)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale  = UIParent:GetEffectiveScale()  -- GetCenter() is in UIParent virtual space
            local dx = px / scale - mx
            local dy = py / scale - my
            KwikTipDB.minimapAngle = math.atan2(dy, dx)
            UpdatePosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("KwikTip", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Move HUD", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag: Reposition", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdatePosition()
    self.MinimapBtn = btn
end

-- Called when showMinimapBtn setting changes.
function KwikTip:_UpdateMinimapButton()
    if not self.MinimapBtn then return end
    if KwikTipDB.showMinimapBtn then
        self.MinimapBtn:Show()
    else
        self.MinimapBtn:Hide()
    end
end

-- ============================================================
-- Config Window
-- ============================================================

function KwikTip:CreateConfigWindow()
    if self.Config then return end

    local cfg = CreateFrame("Frame", "KwikTipConfig", UIParent, "BasicFrameTemplate")
    cfg:SetSize(280, 630)
    cfg:SetPoint("CENTER")
    cfg:SetFrameStrata("HIGH")
    cfg:SetMovable(true)
    cfg:EnableMouse(true)
    cfg:RegisterForDrag("LeftButton")
    cfg:SetScript("OnDragStart", cfg.StartMoving)
    cfg:SetScript("OnDragStop",  cfg.StopMovingOrSizing)
    cfg:SetClampedToScreen(true)
    cfg:SetScript("OnHide", function()
        if KwikTip.moveMode then
            KwikTip:ToggleMoveMode()
        end
        KwikTip:ClearPreview()
    end)
    cfg:Hide()
    self.Config = cfg

    cfg.TitleText:SetText("KwikTip Settings")

    local titleIcon = cfg:CreateTexture(nil, "OVERLAY")
    titleIcon:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktmini.tga")
    titleIcon:SetBlendMode("BLEND")
    titleIcon:SetSize(16, 16)
    titleIcon:SetPoint("RIGHT", cfg.TitleText, "LEFT", -4, 0)

    -- ============================================================
    -- Shared helpers
    -- ============================================================

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

    local function MakeSlider(name, parent, anchor, minVal, maxVal, step, initLabel, lowText, highText)
        local W = 230

        local wrap = CreateFrame("Frame", nil, parent)
        wrap:SetSize(W + 20, 40)
        wrap:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 8, -14)

        local lbl = wrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", wrap, "TOPLEFT", 0, 0)
        lbl:SetText(initLabel)

        local s = CreateFrame("Slider", name, wrap)
        s:SetSize(W, 12)
        s:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -4)
        s:SetOrientation("HORIZONTAL")
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(step)
        s:SetObeyStepOnDrag(true)
        s:EnableMouseWheel(true)

        local track = s:CreateTexture(nil, "BACKGROUND")
        track:SetColorTexture(0.2, 0.2, 0.2, 0.9)
        track:SetAllPoints(s)

        local thumb = s:CreateTexture(nil, "OVERLAY")
        thumb:SetColorTexture(0.75, 0.75, 0.75, 1)
        thumb:SetSize(10, 20)
        s:SetThumbTexture(thumb)

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

    local function MakeSectionHeader(text, anchor, yOffset)
        local h = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset or -14)
        h:SetText(text)
        h:SetTextColor(0.6, 0.6, 0.6)
        return h
    end

    local function MakeCheckbox(name, parent, anchor, labelText, yGap)
        local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yGap or -2)
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetText(labelText)
        return cb
    end

    -- ============================================================
    -- POSITION
    -- ============================================================
    local posHeader = MakeSectionHeader("POSITION", cfg, nil)
    posHeader:SetPoint("TOPLEFT", cfg, "TOPLEFT", 12, -32)

    local moveBtn = CreateFrame("Button", "KwikTipConfigMoveBtn", cfg, "UIPanelButtonTemplate")
    moveBtn:SetSize(110, 22)
    moveBtn:SetPoint("TOPLEFT", posHeader, "BOTTOMLEFT", 0, -6)
    moveBtn:SetText("Move Window")
    moveBtn:SetScript("OnClick", function() KwikTip:ToggleMoveMode() end)

    local widthEdit, heightEdit

    local function ApplySize(w, h)
        w = math.max(100, math.min(600, math.floor(tonumber(w) or KwikTipDB.width  or 220)))
        h = math.max(40,  math.min(400, math.floor(tonumber(h) or KwikTipDB.height or 80)))
        KwikTipDB.width  = w
        KwikTipDB.height = h
        if KwikTip.HUD then KwikTip.HUD:SetSize(w, h) end
        widthEdit:SetText(tostring(w))
        heightEdit:SetText(tostring(h))
    end

    local widthRow, widthMinus, widthPlus
    widthRow, widthEdit, widthMinus, widthPlus = MakeNudgeRow("W:", cfg, moveBtn)
    widthEdit:SetScript("OnEnterPressed", function(self) ApplySize(self:GetText(), KwikTipDB.height) self:ClearFocus() end)
    widthEdit:SetScript("OnEscapePressed", function(self) self:SetText(tostring(KwikTipDB.width or 220)) self:ClearFocus() end)
    widthMinus:SetScript("OnClick", function() ApplySize((KwikTipDB.width  or 220) - 1, KwikTipDB.height) end)
    widthPlus:SetScript("OnClick",  function() ApplySize((KwikTipDB.width  or 220) + 1, KwikTipDB.height) end)

    local heightRow, heightMinus, heightPlus
    heightRow, heightEdit, heightMinus, heightPlus = MakeNudgeRow("H:", cfg, widthRow)
    heightEdit:SetScript("OnEnterPressed", function(self) ApplySize(KwikTipDB.width, self:GetText()) self:ClearFocus() end)
    heightEdit:SetScript("OnEscapePressed", function(self) self:SetText(tostring(KwikTipDB.height or 80)) self:ClearFocus() end)
    heightMinus:SetScript("OnClick", function() ApplySize(KwikTipDB.width, (KwikTipDB.height or 80) - 1) end)
    heightPlus:SetScript("OnClick",  function() ApplySize(KwikTipDB.width, (KwikTipDB.height or 80) + 1) end)

    -- ============================================================
    -- DISPLAY
    -- ============================================================
    local dispHeader = MakeSectionHeader("DISPLAY", heightRow)

    local minimapBtnCB = MakeCheckbox("KwikTipMinimapBtnCB",   cfg, dispHeader, "Show Minimap Button",        -4)
    local hideHUDCB    = MakeCheckbox("KwikTipHideHUDCB",      cfg, minimapBtnCB, "Hide Info Window")
    local showInDungeonCB = MakeCheckbox("KwikTipShowInDungeonCB", cfg, hideHUDCB, "Keep Open Through Instance")

    minimapBtnCB:SetScript("OnClick", function(self)
        KwikTipDB.showMinimapBtn = self:GetChecked()
        if KwikTip._PlaceMinimapBtn    then KwikTip:_PlaceMinimapBtn()    end
        if KwikTip._UpdateMinimapButton then KwikTip:_UpdateMinimapButton() end
    end)
    hideHUDCB:SetScript("OnClick", function(self)
        KwikTipDB.persistentHide = self:GetChecked()
        KwikTip:UpdateVisibility()
    end)
    showInDungeonCB:SetScript("OnClick", function(self)
        KwikTipDB.showInDungeon = self:GetChecked()
        KwikTip:UpdateContent()
        KwikTip:UpdateVisibility()
    end)

    -- ============================================================
    -- SEND TO CHAT
    -- ============================================================
    local chatHeader = MakeSectionHeader("SEND TO CHAT", showInDungeonCB)

    local CHAT_OPTIONS = {
        { label = "None",     value = "NONE"          },
        { label = "Say",      value = "SAY"           },
        { label = "Instance", value = "INSTANCE_CHAT" },
        { label = "Party",    value = "PARTY"         },
        { label = "Raid",     value = "RAID"          },
    }

    local chatDropBtn, chatDropList  -- forward-declared so SetChatChannel can reference them

    local function SetChatChannel(value)
        KwikTipDB.printChannel = value
        for _, opt in ipairs(CHAT_OPTIONS) do
            if opt.value == value then
                if chatDropBtn then chatDropBtn:SetText(opt.label) end
                break
            end
        end
        if KwikTip._UpdatePrintBtn then KwikTip:_UpdatePrintBtn() end
    end

    chatDropBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    chatDropBtn:SetSize(160, 22)
    chatDropBtn:SetPoint("TOPLEFT", chatHeader, "BOTTOMLEFT", 0, -6)

    chatDropList = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    chatDropList:SetSize(160, #CHAT_OPTIONS * 22)
    chatDropList:SetFrameStrata("TOOLTIP")
    chatDropList:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    chatDropList:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    chatDropList:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    chatDropList:Hide()

    for i, opt in ipairs(CHAT_OPTIONS) do
        local row = CreateFrame("Button", nil, chatDropList)
        row:SetSize(158, 20)
        row:SetPoint("TOPLEFT", chatDropList, "TOPLEFT", 1, -(i - 1) * 20 - 1)

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetColorTexture(1, 1, 1, 0.08)
        hl:SetAllPoints(row)

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowLbl:SetPoint("LEFT", row, "LEFT", 6, 0)
        rowLbl:SetText(opt.label)

        local value = opt.value
        row:SetScript("OnClick", function()
            SetChatChannel(value)
            chatDropList:Hide()
        end)
    end

    chatDropBtn:SetScript("OnClick", function()
        if chatDropList:IsShown() then
            chatDropList:Hide()
        else
            chatDropList:ClearAllPoints()
            chatDropList:SetPoint("TOPLEFT", chatDropBtn, "BOTTOMLEFT", 0, -2)
            chatDropList:Show()
        end
    end)

    cfg:HookScript("OnHide", function() chatDropList:Hide() end)

    -- ============================================================
    -- APPEARANCE
    -- ============================================================
    local appHeader = MakeSectionHeader("APPEARANCE", chatDropBtn)

    local opacitySlider = MakeSlider("KwikTipOpacitySlider", cfg, appHeader, 10, 100, 5, "Opacity", "10%", "100%")
    opacitySlider:SetScript("OnValueChanged", function(self, value)
        KwikTipDB.alpha = value / 100
        if KwikTip.HUD then KwikTip.HUD:SetBackdropColor(0, 0, 0, KwikTipDB.alpha) end
        self._lbl:SetText(string.format("Opacity: %d%%", value))
    end)

    -- Font selector (LibSharedMedia-3.0 aware; falls back to 3 built-in fonts)
    local fontHeader = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontHeader:SetPoint("TOPLEFT", opacitySlider._wrap, "BOTTOMLEFT", -8, -12)
    fontHeader:SetText("FONT")
    fontHeader:SetTextColor(0.6, 0.6, 0.6)

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

    local FONT_FALLBACK = {
        ["Friz Quadrata"] = "Fonts\\FRIZQT__.TTF",
        ["Arial Narrow"]  = "Fonts\\ARIALN.TTF",
        ["Morpheus"]      = "Fonts\\MORPHEUS.TTF",
    }

    local fontNames
    if LSM then
        fontNames = LSM:List("font")
        table.sort(fontNames)
    else
        fontNames = { "Arial Narrow", "Friz Quadrata", "Morpheus" }
    end

    local function ResolveFontPath(name)
        if LSM then return LSM:Fetch("font", name) or FONT_FALLBACK[name] or "Fonts\\FRIZQT__.TTF" end
        return FONT_FALLBACK[name] or "Fonts\\FRIZQT__.TTF"
    end

    local fontDropBtn, fontDropList  -- forward-declared so SetFont can reference them

    local function SetFont(name)
        KwikTipDB.fontName = name
        KwikTipDB.fontPath = ResolveFontPath(name)
        if fontDropBtn then fontDropBtn:SetText(name) end
        KwikTip:ApplySettings()
    end

    local DROP_W   = 200
    local ROW_H    = 20
    local MAX_ROWS = 10

    -- Dropdown button
    fontDropBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    fontDropBtn:SetSize(DROP_W, 22)
    fontDropBtn:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, -6)

    -- Dropdown list — scrollable, floats on TOOLTIP strata
    fontDropList = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    fontDropList:SetSize(DROP_W, math.min(#fontNames, MAX_ROWS) * ROW_H + 2)
    fontDropList:SetFrameStrata("TOOLTIP")
    fontDropList:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    fontDropList:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    fontDropList:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    fontDropList:Hide()

    local fontScroll = CreateFrame("ScrollFrame", nil, fontDropList)
    fontScroll:SetPoint("TOPLEFT",     fontDropList, "TOPLEFT",     1, -1)
    fontScroll:SetPoint("BOTTOMRIGHT", fontDropList, "BOTTOMRIGHT", -1, 1)

    local fontScrollChild = CreateFrame("Frame")
    fontScrollChild:SetSize(DROP_W - 2, #fontNames * ROW_H)
    fontScroll:SetScrollChild(fontScrollChild)

    for i, name in ipairs(fontNames) do
        local row = CreateFrame("Button", nil, fontScrollChild)
        row:SetSize(DROP_W - 2, ROW_H)
        row:SetPoint("TOPLEFT", fontScrollChild, "TOPLEFT", 0, -(i - 1) * ROW_H)

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetColorTexture(1, 1, 1, 0.08)
        hl:SetAllPoints(row)

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowLbl:SetPoint("LEFT", row, "LEFT", 6, 0)
        rowLbl:SetText(name)

        local n = name
        row:SetScript("OnClick", function()
            SetFont(n)
            fontDropList:Hide()
        end)
    end

    fontDropList:EnableMouseWheel(true)
    fontDropList:SetScript("OnMouseWheel", function(self, delta)
        local cur = fontScroll:GetVerticalScroll()
        local max = fontScroll:GetVerticalScrollRange()
        fontScroll:SetVerticalScroll(math.max(0, math.min(max, cur - delta * ROW_H)))
    end)

    fontDropBtn:SetScript("OnClick", function()
        if fontDropList:IsShown() then
            fontDropList:Hide()
        else
            fontDropList:ClearAllPoints()
            fontDropList:SetPoint("TOPLEFT", fontDropBtn, "BOTTOMLEFT", 0, -2)
            fontDropList:Show()
        end
    end)

    cfg:HookScript("OnHide", function() fontDropList:Hide() end)

    -- Font size slider
    local fontSizeSlider = MakeSlider("KwikTipFontSizeSlider", cfg, fontDropBtn, 9, 18, 1, "Size: 11", "9", "18")
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        KwikTipDB.fontSize = value
        KwikTip:ApplySettings()
        self._lbl:SetText(string.format("Size: %d", value))
    end)

    -- Logo
    local cfgLogo = cfg:CreateTexture(nil, "ARTWORK")
    cfgLogo:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktlogo.tga")
    cfgLogo:SetBlendMode("BLEND")
    cfgLogo:SetSize(220, 120)
    cfgLogo:SetPoint("BOTTOM", cfg, "BOTTOM", 0, 16)

    -- ============================================================
    -- Internal helpers bound to KwikTip namespace
    -- ============================================================
    function self:_UpdateConfigMoveBtn()
        if not moveBtn then return end
        moveBtn:SetText(self.moveMode and "Lock Window" or "Move Window")
    end

    function self:PopulateConfig()
        local db = KwikTipDB
        minimapBtnCB:SetChecked(db.showMinimapBtn ~= false)
        hideHUDCB:SetChecked(db.persistentHide)
        showInDungeonCB:SetChecked(db.showInDungeon)
        SetChatChannel(db.printChannel or "NONE")
        opacitySlider:SetValue(math.floor(db.alpha * 100 + 0.5))
        SetFont(db.fontName or "Friz Quadrata")
        fontSizeSlider:SetValue(db.fontSize or 11)
        widthEdit:SetText(tostring(db.width or 220))
        heightEdit:SetText(tostring(db.height or 80))
        self:_UpdateConfigMoveBtn()
    end
end

-- ============================================================
-- Public API
-- ============================================================

function KwikTip:ToggleConfig()
    if not self.Config then
        self:CreateConfigWindow()
    end
    if self.Config:IsShown() then
        self.Config:Hide()
    else
        self:PopulateConfig()
        self.Config:Show()
    end
end
