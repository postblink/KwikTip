-- KwikTip: Config window & minimap button
local ADDON_NAME, KwikTip = ...
local L = KwikTip.L

-- ============================================================
-- Support link
-- ============================================================
-- The client cannot open a browser, so the only useful thing a "support" button
-- can do is hand over selectable text. The popup's edit box is read-only by way
-- of rewriting any edit straight back to the URL, so a stray keypress cannot
-- leave the player copying something broken.
local SUPPORT_URL = "https://ko-fi.com/postblink"

local function SupportEditBox(dialog)
    return dialog.editBox or dialog.EditBox
end

StaticPopupDialogs["KWIKTIP_SUPPORT"] = {
    text         = "%s",
    button1      = CLOSE,
    hasEditBox   = true,
    editBoxWidth = 250,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoids tainting Blizzard's own popup slots
    OnShow = function(self)
        local eb = SupportEditBox(self)
        if not eb then return end
        eb:SetText(SUPPORT_URL)
        eb:HighlightText()
        eb:SetFocus()
    end,
    EditBoxOnTextChanged = function(self)
        if self:GetText() ~= SUPPORT_URL then
            self:SetText(SUPPORT_URL)
            self:HighlightText()
        end
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

function KwikTip:ShowSupportPopup()
    StaticPopup_Show("KWIKTIP_SUPPORT", L.SUPPORT_POPUP .. "\n\n" .. L.SUPPORT_COPY_HINT)
end

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
        GameTooltip:AddLine(L.TOOLTIP_MINIMAP_LEFT, 0.7, 0.7, 0.7)
        GameTooltip:AddLine(L.TOOLTIP_MINIMAP_RIGHT, 0.7, 0.7, 0.7)
        GameTooltip:AddLine(L.TOOLTIP_MINIMAP_DRAG, 0.7, 0.7, 0.7)
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
    cfg:SetSize(550, 450)
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

    cfg.TitleText:SetText(L.SETTINGS_TITLE)

    local titleIcon = cfg:CreateTexture(nil, "OVERLAY")
    titleIcon:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktmini.tga")
    titleIcon:SetBlendMode("BLEND")
    titleIcon:SetSize(16, 16)
    titleIcon:SetPoint("RIGHT", cfg.TitleText, "LEFT", -4, 0)

    -- ============================================================
    -- Layout constants
    -- ============================================================
    local NAV_W     = 140
    local TITLE_H   = 28
    local CONTENT_W = 550 - NAV_W - 5   -- ~405px
    local INNER_W   = CONTENT_W - 24    -- ~381px (12px margin each side)
    local MARGIN    = 12

    -- ============================================================
    -- Nav pane
    -- ============================================================
    local navPane = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
    navPane:SetPoint("TOPLEFT",    cfg, "TOPLEFT",    0, -TITLE_H)
    navPane:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", 0, 4)
    navPane:SetWidth(NAV_W)
    navPane:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    navPane:SetBackdropColor(0.06, 0.06, 0.08, 1)
    navPane:SetBackdropBorderColor(0, 0, 0, 0)

    -- Vertical divider between nav and content
    local navDivider = cfg:CreateTexture(nil, "OVERLAY")
    navDivider:SetColorTexture(0.22, 0.22, 0.25, 1)
    navDivider:SetWidth(1)
    navDivider:SetPoint("TOPLEFT",    cfg, "TOPLEFT",    NAV_W, -TITLE_H)
    navDivider:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", NAV_W, 4)

    -- Content pane (logical container — tab frames fill this)
    local contentPane = CreateFrame("Frame", nil, cfg)
    contentPane:SetPoint("TOPLEFT",     cfg, "TOPLEFT",     NAV_W + 1, -TITLE_H)
    contentPane:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -4, 4)

    -- Logo at bottom of nav pane
    local navLogo = navPane:CreateTexture(nil, "ARTWORK")
    navLogo:SetTexture("Interface\\AddOns\\KwikTip\\assets\\ktlogo.tga")
    navLogo:SetBlendMode("BLEND")
    navLogo:SetSize(110, 60)
    navLogo:SetPoint("BOTTOM", navPane, "BOTTOM", 0, 12)

    -- Support link, sitting just above the logo: present for anyone who goes
    -- looking, silent otherwise. Never gated, never nagged in chat.
    local supportBtn = CreateFrame("Button", nil, navPane)
    supportBtn:SetSize(NAV_W - 16, 16)
    supportBtn:SetPoint("BOTTOM", navLogo, "TOP", 0, 4)

    local supportText = supportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    supportText:SetPoint("CENTER", supportBtn, "CENTER")
    supportText:SetText(L.SUPPORT_LABEL)
    supportText:SetTextColor(0.55, 0.55, 0.58)

    supportBtn:SetScript("OnEnter", function() supportText:SetTextColor(1, 0.82, 0) end)
    supportBtn:SetScript("OnLeave", function() supportText:SetTextColor(0.55, 0.55, 0.58) end)
    supportBtn:SetScript("OnClick", function() KwikTip:ShowSupportPopup() end)

    -- ============================================================
    -- Shared helpers
    -- ============================================================

    -- parent: frame that owns the created textures/fontstrings
    -- anchor: frame/fontstring the header is positioned relative to
    local function MakeSectionHeader(text, parent, anchor, yOffset, xOffset)
        local gap  = yOffset or -14
        local xOff = xOffset or 0
        local div = parent:CreateTexture(nil, "OVERLAY")
        div:SetColorTexture(0.25, 0.25, 0.28, 0.8)
        div:SetSize(INNER_W - math.abs(xOff), 1)
        div:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOff, math.floor(gap / 2))
        local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOff, gap)
        h:SetText(text)
        h:SetTextColor(0.9, 0.75, 0.3, 1)
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

    local function AddTooltip(frame, text)
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(text)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local function MakeNudgeRow(label, parent, anchor)
        local wrap = CreateFrame("Frame", nil, parent)
        wrap:SetSize(320, 24)
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

    -- sliderWidth: optional override; defaults to full inner content width
    local function MakeSlider(name, parent, anchor, minVal, maxVal, step, initLabel, lowText, highText, sliderWidth)
        local W = sliderWidth or (INNER_W - 10)

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

    -- ============================================================
    -- Tab system
    -- ============================================================
    local TAB_NAMES  = { L.TAB_GENERAL, L.TAB_LAYOUT, L.TAB_APPEARANCE }
    local TAB_BTN_H  = 34
    local TAB_BTN_W  = NAV_W - 2
    local tabButtons = {}
    local tabFrames  = {}

    -- Hoisted so SelectTab can close them when switching tabs
    local chatDropList, fontDropList, outlineDropList

    -- Gold accent bar that slides to the active tab button
    local accentBar = navPane:CreateTexture(nil, "OVERLAY")
    accentBar:SetColorTexture(0.9, 0.75, 0.3, 1)
    accentBar:SetSize(3, TAB_BTN_H)

    local function SelectTab(index)
        chatDropList:Hide()
        fontDropList:Hide()
        outlineDropList:Hide()
        for i = 1, #tabFrames do
            tabFrames[i]:SetShown(i == index)
            if i == index then
                tabButtons[i]:SetBackdropColor(0.18, 0.18, 0.22, 1)
                tabButtons[i]._lbl:SetTextColor(1, 1, 1)
            else
                tabButtons[i]:SetBackdropColor(0.09, 0.09, 0.11, 1)
                tabButtons[i]._lbl:SetTextColor(0.6, 0.6, 0.6)
            end
        end
        accentBar:ClearAllPoints()
        accentBar:SetPoint("TOPLEFT", tabButtons[index], "TOPLEFT", 0, 0)
    end

    for i, name in ipairs(TAB_NAMES) do
        local btn = CreateFrame("Button", nil, navPane, "BackdropTemplate")
        btn:SetSize(TAB_BTN_W, TAB_BTN_H)
        btn:SetPoint("TOPLEFT", navPane, "TOPLEFT", 1, -(i - 1) * (TAB_BTN_H + 3) - 12)
        btn:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets   = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        btn:SetBackdropColor(0.09, 0.09, 0.11, 1)
        btn:SetBackdropBorderColor(0, 0, 0, 0)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", btn, "LEFT", 14, 0)
        lbl:SetText(name)
        lbl:SetTextColor(0.6, 0.6, 0.6)
        btn._lbl = lbl

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetColorTexture(1, 1, 1, 0.05)
        hl:SetAllPoints(btn)

        local idx = i
        btn:SetScript("OnClick", function() SelectTab(idx) end)

        tabButtons[i] = btn

        local tf = CreateFrame("Frame", nil, contentPane)
        tf:SetAllPoints(contentPane)
        tf:Hide()
        tabFrames[i] = tf
    end

    -- Preview button: centered in nav pane, 16px below the last tab button
    local previewBtn = CreateFrame("Button", "KwikTipConfigPreviewBtn", navPane, "UIPanelButtonTemplate")
    previewBtn:SetSize(120, 22)
    previewBtn:SetPoint("TOP", navPane, "TOP", 0, -(3 * (TAB_BTN_H + 3) + 12 + 16))
    previewBtn:SetText(L.PREVIEW_BTN)
    previewBtn:SetScript("OnClick", function() KwikTip:TogglePreview() end)

    -- ============================================================
    -- TAB 1: General
    -- ============================================================
    local tf1 = tabFrames[1]

    local t1Top = CreateFrame("Frame", nil, tf1)
    t1Top:SetSize(1, 1)
    t1Top:SetPoint("TOPLEFT", tf1, "TOPLEFT", MARGIN, 0)

    local displayHeader = MakeSectionHeader(L.SECTION_DISPLAY, tf1, t1Top, -12)

    local hideHUDCB       = MakeCheckbox("KwikTipHideHUDCB",       tf1, displayHeader,   L.CHECK_DISABLE,               -6)
    local minimapBtnCB    = MakeCheckbox("KwikTipMinimapBtnCB",    tf1, hideHUDCB,       L.CHECK_MINIMAP)
    local showInDungeonCB = MakeCheckbox("KwikTipShowInDungeonCB", tf1, minimapBtnCB,    L.CHECK_PERSISTENT)
    minimapBtnCB:SetScript("OnClick", function(self)
        KwikTipDB.showMinimapBtn = self:GetChecked()
        if KwikTip._PlaceMinimapBtn     then KwikTip:_PlaceMinimapBtn()     end
        if KwikTip._UpdateMinimapButton then KwikTip:_UpdateMinimapButton() end
    end)
    hideHUDCB:SetScript("OnClick", function(self)
        KwikTipDB.persistentHide = self:GetChecked()
        KwikTip:UpdateVisibility()
    end)
    AddTooltip(hideHUDCB, L.TOOLTIP_HIDE)
    showInDungeonCB:SetScript("OnClick", function(self)
        KwikTipDB.showInDungeon = self:GetChecked()
        KwikTip:UpdateContent()
        KwikTip:UpdateVisibility()
    end)
    AddTooltip(showInDungeonCB, L.TOOLTIP_PERSISTENT)
    local showNoteBtnCB = MakeCheckbox("KwikTipShowNoteBtnCB", tf1, showInDungeonCB, L.CHECK_NOTES)
    showNoteBtnCB:SetScript("OnClick", function(self)
        KwikTipDB.showNoteBtn = self:GetChecked()
        if KwikTip._UpdateNoteBtn then KwikTip:_UpdateNoteBtn() end
    end)
    AddTooltip(showNoteBtnCB, L.TOOLTIP_NOTES)

    local enableDelvesCB = MakeCheckbox("KwikTipEnableDelvesCB", tf1, showNoteBtnCB, L.CHECK_DELVES)
    enableDelvesCB:SetScript("OnClick", function(self)
        KwikTipDB.delves = self:GetChecked()
        KwikTip:UpdateContent()
        KwikTip:UpdateVisibility()
    end)
    AddTooltip(enableDelvesCB, L.TOOLTIP_DELVES)

    local chatHeader = MakeSectionHeader(L.SECTION_CHAT, tf1, enableDelvesCB, -14)

    local CHAT_OPTIONS = {
        { label = L.LABEL_NONE,     value = "NONE"          },
        { label = L.CHAT_SAY,      value = "SAY"           },
        { label = L.CHAT_INSTANCE, value = "INSTANCE_CHAT" },
        { label = L.CHAT_PARTY,    value = "PARTY"         },
        { label = L.CHAT_RAID,     value = "RAID"          },
    }

    local chatDropBtn

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

    chatDropBtn = CreateFrame("Button", nil, tf1, "UIPanelButtonTemplate")
    chatDropBtn:SetSize(180, 22)
    chatDropBtn:SetPoint("TOPLEFT", chatHeader, "BOTTOMLEFT", 0, -6)

    chatDropList = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    chatDropList:SetSize(180, #CHAT_OPTIONS * 22)
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
        row:SetSize(178, 20)
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


    -- ============================================================
    -- TAB 2: Layout
    -- ============================================================
    local tf2 = tabFrames[2]

    local t2Top = CreateFrame("Frame", nil, tf2)
    t2Top:SetSize(1, 1)
    t2Top:SetPoint("TOPLEFT", tf2, "TOPLEFT", MARGIN, 0)

    local posHeader = MakeSectionHeader(L.SECTION_POSITION, tf2, t2Top, -12)

    local moveBtn = CreateFrame("Button", "KwikTipConfigMoveBtn", tf2, "UIPanelButtonTemplate")
    moveBtn:SetSize(130, 22)
    moveBtn:SetPoint("TOPLEFT", posHeader, "BOTTOMLEFT", 0, -6)
    moveBtn:SetText(L.BTN_MOVE)
    moveBtn:SetScript("OnClick", function() KwikTip:ToggleMoveMode() end)

    local sizingHeader = MakeSectionHeader(L.SECTION_SIZING, tf2, moveBtn, -14)

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
    widthRow, widthEdit, widthMinus, widthPlus = MakeNudgeRow(L.LABEL_WIDTH, tf2, sizingHeader)
    widthEdit:SetScript("OnEnterPressed",  function(self) ApplySize(self:GetText(), KwikTipDB.height) self:ClearFocus() end)
    widthEdit:SetScript("OnEscapePressed", function(self) self:SetText(tostring(KwikTipDB.width or 220)) self:ClearFocus() end)
    widthMinus:SetScript("OnClick", function() ApplySize((KwikTipDB.width  or 220) - 1, KwikTipDB.height) end)
    widthPlus:SetScript("OnClick",  function() ApplySize((KwikTipDB.width  or 220) + 1, KwikTipDB.height) end)

    local heightRow, heightMinus, heightPlus
    heightRow, heightEdit, heightMinus, heightPlus = MakeNudgeRow(L.LABEL_HEIGHT, tf2, widthRow)
    heightEdit:SetScript("OnEnterPressed",  function(self) ApplySize(KwikTipDB.width, self:GetText()) self:ClearFocus() end)
    heightEdit:SetScript("OnEscapePressed", function(self) self:SetText(tostring(KwikTipDB.height or 80)) self:ClearFocus() end)
    heightMinus:SetScript("OnClick", function() ApplySize(KwikTipDB.width, (KwikTipDB.height or 80) - 1) end)
    heightPlus:SetScript("OnClick",  function() ApplySize(KwikTipDB.width, (KwikTipDB.height or 80) + 1) end)

    local autoExpandCB = MakeCheckbox("KwikTipAutoExpandCB", tf2, heightRow, L.CHECK_AUTOEXPAND, -6)
    autoExpandCB:SetScript("OnClick", function(self)
        KwikTipDB.autoExpand = self:GetChecked()
        KwikTip:UpdateContent()
    end)

    -- ============================================================
    -- TAB 3: Appearance
    -- ============================================================
    local tf3 = tabFrames[3]

    local t3Top = CreateFrame("Frame", nil, tf3)
    t3Top:SetSize(1, 1)
    t3Top:SetPoint("TOPLEFT", tf3, "TOPLEFT", MARGIN, 0)

    local windowHeader = MakeSectionHeader(L.SECTION_WINDOW, tf3, t3Top, -12)

    local opacitySlider = MakeSlider("KwikTipOpacitySlider", tf3, windowHeader, 0, 100, 5, L.SLIDER_OPACITY, "0%", "100%")
    opacitySlider:SetScript("OnValueChanged", function(self, value)
        KwikTipDB.alpha = value / 100
        if KwikTip.HUD then KwikTip.HUD:SetBackdropColor(0, 0, 0, KwikTipDB.alpha) end
        self._lbl:SetText(string.format(L.FMT_OPACITY, value))
    end)

    local borderEnabledCB = MakeCheckbox("KwikTipBorderEnabledCB", tf3, opacitySlider._wrap, L.CHECK_BORDER, -4)
    borderEnabledCB:SetScript("OnClick", function(self)
        KwikTipDB.borderEnabled = self:GetChecked()
        KwikTip:ApplySettings()
    end)

    local borderColorLabel = tf3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    borderColorLabel:SetPoint("TOPLEFT", borderEnabledCB, "BOTTOMLEFT", 0, -8)
    borderColorLabel:SetText(L.LABEL_BORDER_COLOR)

    local borderSwatchBtn = CreateFrame("Button", nil, tf3, "BackdropTemplate")
    borderSwatchBtn:SetSize(20, 20)
    borderSwatchBtn:SetPoint("LEFT", borderColorLabel, "RIGHT", 6, 0)
    borderSwatchBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    borderSwatchBtn:SetBackdropColor(0, 0, 0, 1)
    borderSwatchBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local function ApplyBorderColor(r, g, b)
        KwikTipDB.borderColorR = r
        KwikTipDB.borderColorG = g
        KwikTipDB.borderColorB = b
        borderSwatchBtn:SetBackdropColor(r, g, b, 1)
        if KwikTip.HUD and KwikTipDB.borderEnabled ~= false then
            KwikTip.HUD:SetBackdropBorderColor(r, g, b, KwikTipDB.borderColorA or 1)
        end
    end

    borderSwatchBtn:SetScript("OnClick", function()
        local db = KwikTipDB
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                ApplyBorderColor(r, g, b)
            end,
            cancelFunc = function(prev)
                ApplyBorderColor(prev.r, prev.g, prev.b)
            end,
            hasOpacity = false,
            r = db.borderColorR or 0,
            g = db.borderColorG or 0,
            b = db.borderColorB or 0,
        })
    end)

    -- xOffset = -8: compensates for the 8px slider indent so TEXT header aligns with WINDOW header
    local textHeader = MakeSectionHeader(L.SECTION_TEXT, tf3, borderColorLabel, -14, -8)

    -- Font selector (LibSharedMedia-3.0 aware; falls back to 3 built-in fonts)
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

    local fontDropBtn

    local function SetFont(name)
        KwikTipDB.fontName = name
        KwikTipDB.fontPath = ResolveFontPath(name)
        if fontDropBtn then fontDropBtn:SetText(name) end
        KwikTip:ApplySettings()
    end

    local DROP_W   = 200
    local ROW_H    = 20
    local MAX_ROWS = 10

    fontDropBtn = CreateFrame("Button", nil, tf3, "UIPanelButtonTemplate")
    fontDropBtn:SetSize(DROP_W, 22)
    fontDropBtn:SetPoint("TOPLEFT", textHeader, "BOTTOMLEFT", 0, -6)

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

    -- Font size slider matches the dropdown width so they visually pair up
    local fontSizeSlider = MakeSlider("KwikTipFontSizeSlider", tf3, fontDropBtn, 9, 18, 1, string.format(L.FMT_SIZE, 11), "9", "18", DROP_W)
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        KwikTipDB.fontSize = value
        KwikTip:ApplySettings()
        self._lbl:SetText(string.format(L.FMT_SIZE, value))
    end)

    local shadowCB = MakeCheckbox("KwikTipShadowCB", tf3, fontSizeSlider._wrap, L.CHECK_SHADOW, -4)
    shadowCB:SetScript("OnClick", function(self)
        KwikTipDB.textShadow = self:GetChecked()
        KwikTip:ApplySettings()
    end)

    local outlineLabel = tf3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    outlineLabel:SetPoint("TOPLEFT", shadowCB, "BOTTOMLEFT", 0, -8)
    outlineLabel:SetText(L.LABEL_OUTLINE)

    local OUTLINE_OPTIONS = {
        { label = L.LABEL_NONE,          value = ""             },
        { label = L.OUTLINE_OUTLINE,       value = "OUTLINE"      },
        { label = L.OUTLINE_THICK, value = "THICKOUTLINE" },
    }

    local outlineDropBtn

    local function SetOutline(value)
        KwikTipDB.textOutline = value
        for _, opt in ipairs(OUTLINE_OPTIONS) do
            if opt.value == value then
                if outlineDropBtn then outlineDropBtn:SetText(opt.label) end
                break
            end
        end
        KwikTip:ApplySettings()
    end

    outlineDropBtn = CreateFrame("Button", nil, tf3, "UIPanelButtonTemplate")
    outlineDropBtn:SetSize(180, 22)
    outlineDropBtn:SetPoint("TOPLEFT", outlineLabel, "BOTTOMLEFT", 0, -4)

    outlineDropList = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    outlineDropList:SetSize(180, #OUTLINE_OPTIONS * 22)
    outlineDropList:SetFrameStrata("TOOLTIP")
    outlineDropList:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    outlineDropList:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    outlineDropList:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    outlineDropList:Hide()

    for i, opt in ipairs(OUTLINE_OPTIONS) do
        local row = CreateFrame("Button", nil, outlineDropList)
        row:SetSize(178, 20)
        row:SetPoint("TOPLEFT", outlineDropList, "TOPLEFT", 1, -(i - 1) * 20 - 1)

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetColorTexture(1, 1, 1, 0.08)
        hl:SetAllPoints(row)

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowLbl:SetPoint("LEFT", row, "LEFT", 6, 0)
        rowLbl:SetText(opt.label)

        local value = opt.value
        row:SetScript("OnClick", function()
            SetOutline(value)
            outlineDropList:Hide()
        end)
    end

    outlineDropBtn:SetScript("OnClick", function()
        if outlineDropList:IsShown() then
            outlineDropList:Hide()
        else
            outlineDropList:ClearAllPoints()
            outlineDropList:SetPoint("TOPLEFT", outlineDropBtn, "BOTTOMLEFT", 0, -2)
            outlineDropList:Show()
        end
    end)

    -- Hide all floating dropdowns when the config window closes
    cfg:HookScript("OnHide", function()
        chatDropList:Hide()
        fontDropList:Hide()
        outlineDropList:Hide()
    end)

    -- Initialise tab state (tab 1 shown, others hidden)
    SelectTab(1)

    -- ============================================================
    -- Internal helpers bound to KwikTip namespace
    -- ============================================================
    function self:_UpdateConfigMoveBtn()
        if not moveBtn then return end
        moveBtn:SetText(self.moveMode and L.BTN_LOCK or L.BTN_MOVE)
    end

    function self:PopulateConfig()
        local db = KwikTipDB
        minimapBtnCB:SetChecked(db.showMinimapBtn ~= false)
        hideHUDCB:SetChecked(db.persistentHide)
        showInDungeonCB:SetChecked(db.showInDungeon)
        autoExpandCB:SetChecked(db.autoExpand ~= false)
        showNoteBtnCB:SetChecked(db.showNoteBtn ~= false)
        enableDelvesCB:SetChecked(db.delves == true)
        SetChatChannel(db.printChannel or "NONE")
        opacitySlider:SetValue(math.floor(db.alpha * 100 + 0.5))
        SetFont(db.fontName or "Friz Quadrata")
        fontSizeSlider:SetValue(db.fontSize or 11)
        widthEdit:SetText(tostring(db.width or 220))
        heightEdit:SetText(tostring(db.height or 80))
        shadowCB:SetChecked(db.textShadow)
        SetOutline(db.textOutline or "")
        borderEnabledCB:SetChecked(db.borderEnabled ~= false)
        borderSwatchBtn:SetBackdropColor(db.borderColorR or 0, db.borderColorG or 0, db.borderColorB or 0, 1)
        self:_UpdateConfigMoveBtn()
    end

    -- Assigned last so a construction failure leaves self.Config nil and allows retry
    self.Config = cfg
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
