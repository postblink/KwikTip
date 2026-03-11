-- KwikTip: HUD frame and layout API
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- HUD Frame
-- ============================================================
local hud
local contentText
local printBtn
local cornerHandles = {}

-- Single reusable frame for deferring SendChatMessage past combat lockdown.
-- Allocated once on first use; re-registered each time a send is queued.
-- Multiple clicks during combat overwrite _pendingSend* — last content wins.
local _combatSendFrame
local _pendingSendLines
local _pendingSendChannel

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

    -- Print-to-chat button — small, sits in the bottom-right corner of the HUD.
    -- Always has EnableMouse(true) independently of the parent's mouse passthrough state.
    printBtn = CreateFrame("Button", "KwikTipPrintBtn", hud)
    printBtn:SetSize(16, 16)
    printBtn:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT", -3, 3)
    printBtn:SetFrameLevel(hud:GetFrameLevel() + 3)
    printBtn:EnableMouse(true)
    printBtn:Hide()
    KwikTip.PrintBtn = printBtn

    local printBtnTex = printBtn:CreateTexture(nil, "OVERLAY")
    printBtnTex:SetTexture("Interface\\GossipFrame\\GossipGossipIcon")
    printBtnTex:SetAllPoints(printBtn)
    printBtnTex:SetAlpha(0.7)

    local printBtnHL = printBtn:CreateTexture(nil, "HIGHLIGHT")
    printBtnHL:SetColorTexture(1, 1, 1, 0.2)
    printBtnHL:SetAllPoints(printBtn)

    printBtn:SetScript("OnClick", function()
        local content = KwikTip._lastContent
        if not content or content == "" then return end

        -- Replace role icon textures with text labels, then strip remaining escapes.
        -- SendChatMessage requires plain text — the server strips everything else.
        local plain = content
        plain = plain:gsub("|T[^|]*Ability_Warrior_DefensiveStance[^|]*|t%s*", "[Tank] ")
        plain = plain:gsub("|T[^|]*Spell_Holy_Renew[^|]*|t%s*",               "[Heal] ")
        plain = plain:gsub("|T[^|]*Ability_DualWield[^|]*|t%s*",               "[DPS] ")
        plain = plain:gsub("|T[^|]*Ability_Kick[^|]*|t%s*",                    "[INT] ")
        plain = plain:gsub("|T.-|t", "")
        plain = plain:gsub("|c%x%x%x%x%x%x%x%x", "")
        plain = plain:gsub("|r", "")

        -- Collect non-empty lines and skip only the first (dungeon name); keep boss/entity name.
        local lines = {}
        for line in plain:gmatch("[^\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" then
                lines[#lines + 1] = line
            end
        end
        local channel = KwikTipDB.printChannel or "NONE"
        if channel == "NONE" then return end
        if InCombatLockdown() then
            -- SendChatMessage is protected during combat; defer until PLAYER_REGEN_ENABLED.
            -- Reuse a single module-level frame to avoid permanent per-click allocations.
            -- Multiple clicks during combat overwrite the pending data — last content wins.
            _pendingSendLines   = lines
            _pendingSendChannel = channel
            if not _combatSendFrame then
                _combatSendFrame = CreateFrame("Frame")
                _combatSendFrame:SetScript("OnEvent", function(self)
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    if _pendingSendLines and _pendingSendChannel then
                        for i = 2, #_pendingSendLines do
                            SendChatMessage(_pendingSendLines[i], _pendingSendChannel)
                        end
                        _pendingSendLines   = nil
                        _pendingSendChannel = nil
                    end
                end)
            end
            _combatSendFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        else
            for i = 2, #lines do
                SendChatMessage(lines[i], channel)
            end
        end
    end)

    printBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Print tip to instance chat", 1, 1, 1)
        GameTooltip:Show()
    end)

    printBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

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
    if contentText then
        local LSM  = LibStub and LibStub("LibSharedMedia-3.0", true)
        local path = (LSM and db.fontName and LSM:Fetch("font", db.fontName))
                  or db.fontPath or "Fonts\\FRIZQT__.TTF"
        contentText:SetFont(path, db.fontSize or 11, "")
    end
end

-- Show or hide the print button based on the showPrintBtn setting and HUD visibility.
function KwikTip:_UpdatePrintBtn()
    if not printBtn then return end
    if KwikTipDB.printChannel and KwikTipDB.printChannel ~= "NONE" and hud and hud:IsShown() then
        printBtn:Show()
    else
        printBtn:Hide()
    end
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

    if self.moveMode or self.previewActive or self.bossActive or self.bossTargetActive or self.trashActive or self.areaActive or self.dungeonActive then
        self:InitHUD()
        hud:Show()
    else
        if hud then hud:Hide() end
    end
    self:_UpdatePrintBtn()
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
