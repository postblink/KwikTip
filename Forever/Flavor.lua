-- Forever-specific detection guards and manual boss preview; shared Retail engine is unchanged.
local ADDON_NAME, KwikTip = ...

KwikTip.IS_FOREVER = true

local function inDungeon(dungeon)
    local inInstance, instanceType = IsInInstance()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    if not inInstance or instanceType ~= "party" or instanceID ~= dungeon.instanceID then return false end
    -- Forever's sourced coverage is normal-only; absence of an allowlist is unknown.
    if difficultyID ~= 1 or not dungeon.difficultyIDs then return false end
    for _, id in ipairs(dungeon.difficultyIDs) do
        if id == difficultyID then return true end
    end
    return false
end

local function clearBoss(self)
    self._pairedEncounters = nil
    self._activeBossEntry = nil
    self._activeEncounterID = nil
    self._activeEncounterName = nil
    self._activeDifficultyID = nil
    self.bossActive = false
end

local function isInCombat(self)
    return (InCombatLockdown and InCombatLockdown()) or self._inCombat == true
end

local function setButtonEnabled(btn, enabled)
    if not btn then return end
    if btn.SetEnabled then
        btn:SetEnabled(enabled)
    elseif enabled and btn.Enable then
        btn:Enable()
    elseif not enabled and btn.Disable then
        btn:Disable()
    else
        btn:SetAlpha(enabled and 1 or 0.5)
    end
end

local function clearManualPreview(self)
    if not self._manualBossPreview then return false end
    self._manualBossPreview = nil
    if self.RefreshForeverBossPreviewUI then
        self:RefreshForeverBossPreviewUI()
    end
    return true
end

local function getSupportedDungeon(self)
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "party" then
        return nil, "Unavailable: enter a supported dungeon (Normal) to preview bosses."
    end
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local dungeon = instanceID and self.DUNGEON_BY_INSTANCEID and self.DUNGEON_BY_INSTANCEID[instanceID]
    if not dungeon then
        return nil, "Unavailable: this instance is not supported in KwikTip Forever."
    end
    if not inDungeon(dungeon) then
        return nil, "Unavailable: current difficulty is not supported (Normal only)."
    end
    if not dungeon.bosses or #dungeon.bosses == 0 then
        return nil, "Unavailable: no boss tips in this instance."
    end
    return dungeon, nil
end

function KwikTip:GetBossPreviewDungeon()
    return getSupportedDungeon(self)
end

function KwikTip:PreviewBoss(bossOrIndex)
    if isInCombat(self) then
        return false, "Boss preview is unavailable during combat."
    end
    local dungeon, reason = getSupportedDungeon(self)
    if not dungeon then
        return false, reason
    end
    if self.bossActive then
        return false, "Boss preview is unavailable during an active encounter."
    end

    local boss
    if type(bossOrIndex) == "number" then
        boss = dungeon.bosses[bossOrIndex]
    elseif type(bossOrIndex) == "table" then
        for _, candidate in ipairs(dungeon.bosses) do
            if candidate == bossOrIndex then
                boss = candidate
                break
            end
        end
    end
    if not boss then
        return false, "Boss not found in this dungeon."
    end

    if self.previewActive then
        self.previewActive = false
    end
    -- Unknown or rejected encounters can leave a name behind in the shared engine.
    -- Never label a manual selection with an unrelated live encounter name.
    self._activeEncounterName = nil
    self._manualBossPreview = { dungeon = dungeon, boss = boss }
    self:InitHUD()
    self:UpdateContent()
    self:UpdateVisibility()
    if self.RefreshForeverBossPreviewUI then
        self:RefreshForeverBossPreviewUI()
    end
    return true, boss
end

function KwikTip:ClearBossPreview()
    local cleared = clearManualPreview(self)
    if cleared then
        self:SetContent("")
        self:UpdateContent()
        self:UpdateVisibility()
    end
    return cleared
end

local function matchBossQuery(dungeon, query)
    local idx = tonumber(query)
    if idx and idx % 1 == 0 and dungeon.bosses[idx] then
        return dungeon.bosses[idx], nil
    end
    local needle = query:lower()
    local exactMatches, partialMatches = {}, {}
    for i, boss in ipairs(dungeon.bosses) do
        local nameLower = (boss.name or ""):lower()
        if nameLower == needle then
            table.insert(exactMatches, { index = i, boss = boss })
        elseif nameLower:find(needle, 1, true) then
            table.insert(partialMatches, { index = i, boss = boss })
        end
    end
    local matches = #exactMatches > 0 and exactMatches or partialMatches
    if #matches == 1 then
        return matches[1].boss, nil
    end
    return nil, matches
end

function KwikTip:HandleBossCommand(arg)
    local query = (arg or ""):match("^%s*(.-)%s*$")
    local lower = query:lower()
    if lower == "clear" or lower == "off" or lower == "hide" then
        self:ClearBossPreview()
        print("|cff00ff00KwikTip|r Boss preview cleared.")
        return
    end
    if isInCombat(self) then
        print("|cff00ff00KwikTip|r Boss preview is unavailable during combat.")
        return
    end
    local dungeon, reason = getSupportedDungeon(self)
    if not dungeon then
        print("|cff00ff00KwikTip|r " .. reason)
        return
    end
    if query == "" then
        local instanceName = GetInstanceInfo()
        local displayName = (instanceName and instanceName ~= "") and instanceName or dungeon.name
        print("|cff00ff00KwikTip|r " .. displayName .. " — known bosses (list, not pull order):")
        for i, boss in ipairs(dungeon.bosses) do
            print(string.format("  [%d] %s", i, boss.name))
        end
        print("  Use /kwik boss <number or name> to preview, or /kwik boss clear to dismiss.")
        return
    end

    local boss, matches = matchBossQuery(dungeon, query)
    if not boss then
        if matches and #matches > 1 then
            print("|cff00ff00KwikTip|r Multiple bosses match '" .. query .. "':")
            for _, m in ipairs(matches) do
                print(string.format("  [%d] %s", m.index, m.boss.name))
            end
        else
            print("|cff00ff00KwikTip|r No boss matching '" .. query .. "'. Type /kwik boss to list.")
        end
        return
    end

    local ok, result = self:PreviewBoss(boss)
    if not ok then
        print("|cff00ff00KwikTip|r " .. tostring(result))
        return
    end
    print("|cff00ff00KwikTip|r Previewing boss tip: " .. boss.name .. " (type /kwik boss clear to dismiss).")
    if KwikTipDB and KwikTipDB.persistentHide then
        print("|cff00ff00KwikTip|r Note: Disable Tips is enabled, so the HUD is currently hidden.")
    end
end

function KwikTip:InitForeverBossPreviewUI(cfg, parent, anchor, makeSectionHeader)
    if self._bossPreviewUI then return end

    local bossHeader = makeSectionHeader("BOSS TIP PREVIEW", parent, anchor, -14)

    local hintText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintText:SetPoint("TOPLEFT", bossHeader, "BOTTOMLEFT", 0, -4)
    hintText:SetWidth(370)
    hintText:SetJustifyH("LEFT")
    hintText:SetTextColor(0.75, 0.75, 0.75)

    local bossDropBtn = CreateFrame("Button", "KwikTipBossPreviewDropBtn", parent, "UIPanelButtonTemplate")
    bossDropBtn:SetSize(220, 22)
    bossDropBtn:SetPoint("TOPLEFT", hintText, "BOTTOMLEFT", 0, -6)

    local bossClearBtn = CreateFrame("Button", "KwikTipBossPreviewClearBtn", parent, "UIPanelButtonTemplate")
    bossClearBtn:SetSize(65, 22)
    bossClearBtn:SetPoint("LEFT", bossDropBtn, "RIGHT", 6, 0)
    bossClearBtn:SetText("Clear")

    local statusText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOPLEFT", bossDropBtn, "BOTTOMLEFT", 0, -6)
    statusText:SetWidth(370)
    statusText:SetJustifyH("LEFT")
    statusText:SetTextColor(0.85, 0.75, 0.45)

    local DROP_W = 240
    local ROW_H = 20
    local MAX_ROWS = 8
    local HEADER_H = 20

    local bossDropList = CreateFrame("Frame", "KwikTipBossPreviewDropList", UIParent, "BackdropTemplate")
    bossDropList:SetSize(DROP_W, HEADER_H + ROW_H + 2)
    bossDropList:SetFrameStrata("TOOLTIP")
    bossDropList:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    bossDropList:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    bossDropList:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    bossDropList:Hide()

    local listHeader = bossDropList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listHeader:SetPoint("TOPLEFT", bossDropList, "TOPLEFT", 6, -4)
    listHeader:SetText("Known bosses (list, not pull order):")
    listHeader:SetTextColor(0.9, 0.75, 0.3)

    local bossScroll = CreateFrame("ScrollFrame", nil, bossDropList)
    bossScroll:SetPoint("TOPLEFT", bossDropList, "TOPLEFT", 1, -HEADER_H)
    bossScroll:SetPoint("BOTTOMRIGHT", bossDropList, "BOTTOMRIGHT", -1, 1)

    local bossScrollChild = CreateFrame("Frame")
    bossScrollChild:SetSize(DROP_W - 2, ROW_H)
    bossScroll:SetScrollChild(bossScrollChild)

    bossDropList:EnableMouseWheel(true)
    bossDropList:SetScript("OnMouseWheel", function(_, delta)
        local cur = bossScroll:GetVerticalScroll()
        local max = bossScroll:GetVerticalScrollRange()
        bossScroll:SetVerticalScroll(math.max(0, math.min(max, cur - delta * ROW_H)))
    end)

    local bossRows = {}
    local function ensureRow(index)
        if bossRows[index] then return bossRows[index] end
        local row = CreateFrame("Button", nil, bossScrollChild)
        row:SetSize(DROP_W - 2, ROW_H)
        row:SetPoint("TOPLEFT", bossScrollChild, "TOPLEFT", 0, -(index - 1) * ROW_H)

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetColorTexture(1, 1, 1, 0.08)
        hl:SetAllPoints(row)

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowLbl:SetPoint("LEFT", row, "LEFT", 6, 0)
        rowLbl:SetText("")
        row._lbl = rowLbl

        row:SetScript("OnClick", function(btn)
            bossDropList:Hide()
            if btn._boss then
                local ok, err = KwikTip:PreviewBoss(btn._boss)
                if not ok and err then
                    statusText:SetText(err)
                end
            end
        end)

        bossRows[index] = row
        return row
    end

    bossDropBtn:SetScript("OnClick", function()
        if isInCombat(KwikTip) or not getSupportedDungeon(KwikTip) then
            bossDropList:Hide()
            KwikTip:RefreshForeverBossPreviewUI()
            return
        end
        if bossDropList:IsShown() then
            bossDropList:Hide()
        else
            KwikTip:RefreshForeverBossPreviewUI()
            bossDropList:ClearAllPoints()
            bossDropList:SetPoint("TOPLEFT", bossDropBtn, "BOTTOMLEFT", 0, -2)
            bossDropList:Show()
        end
    end)

    bossClearBtn:SetScript("OnClick", function()
        bossDropList:Hide()
        KwikTip:ClearBossPreview()
    end)

    parent:HookScript("OnHide", function() bossDropList:Hide() end)
    cfg:HookScript("OnHide", function() bossDropList:Hide() end)

    self._bossPreviewUI = {
        dropBtn    = bossDropBtn,
        clearBtn   = bossClearBtn,
        dropList   = bossDropList,
        listHeader = listHeader,
        hintText   = hintText,
        statusText = statusText,
        rows       = bossRows,
        ensureRow  = ensureRow,
        scroll     = bossScroll,
        scrollChild = bossScrollChild,
        dropW      = DROP_W,
        rowH       = ROW_H,
        maxRows    = MAX_ROWS,
        headerH    = HEADER_H,
    }
end

function KwikTip:RefreshForeverBossPreviewUI()
    local ui = self._bossPreviewUI
    if not ui then return end

    local combat = isInCombat(self)
    local dungeon, unavailableReason = getSupportedDungeon(self)

    if combat then
        ui.dropList:Hide()
        ui.dropBtn:SetText("In combat")
        setButtonEnabled(ui.dropBtn, false)
        setButtonEnabled(ui.clearBtn, self._manualBossPreview ~= nil)
        ui.hintText:SetText("Known bosses (list, not pull order):")
        ui.statusText:SetText("Boss preview is unavailable during combat.")
        return
    end

    if not dungeon then
        ui.dropList:Hide()
        ui.dropBtn:SetText("Unavailable")
        setButtonEnabled(ui.dropBtn, false)
        setButtonEnabled(ui.clearBtn, false)
        ui.hintText:SetText(unavailableReason)
        ui.statusText:SetText("")
        for _, row in ipairs(ui.rows) do
            row._boss = nil
            row:Hide()
        end
        return
    end

    setButtonEnabled(ui.dropBtn, true)
    local instanceName = GetInstanceInfo()
    local displayName = (instanceName and instanceName ~= "") and instanceName or dungeon.name
    ui.hintText:SetText("Known bosses in " .. displayName .. " (list, not pull order):")

    local activePreview = self._manualBossPreview and self._manualBossPreview.dungeon == dungeon
    setButtonEnabled(ui.clearBtn, activePreview)
    if activePreview then
        ui.dropBtn:SetText(self._manualBossPreview.boss.name)
        if KwikTipDB and KwikTipDB.persistentHide then
            ui.statusText:SetText("Preview selected, but Disable Tips is checked.")
        else
            ui.statusText:SetText("Showing boss tip in HUD (clears on pull/combat/zone exit).")
        end
    else
        ui.dropBtn:SetText("Select a boss...")
        if KwikTipDB and KwikTipDB.persistentHide then
            ui.statusText:SetText("Note: Disable Tips is checked; uncheck to view HUD.")
        else
            ui.statusText:SetText("Or use /kwik boss in chat.")
        end
    end

    for i, boss in ipairs(dungeon.bosses) do
        local row = ui.ensureRow(i)
        row._boss = boss
        row._lbl:SetText(boss.name)
        row:Show()
    end
    for j = #dungeon.bosses + 1, #ui.rows do
        ui.rows[j]._boss = nil
        ui.rows[j]:Hide()
    end

    local count = #dungeon.bosses
    ui.scrollChild:SetSize(ui.dropW - 2, math.max(1, count) * ui.rowH)
    ui.dropList:SetSize(ui.dropW, ui.headerH + math.min(count, ui.maxRows) * ui.rowH + 2)
    ui.scroll:SetVerticalScroll(0)
end

local OnEncounterStart = KwikTip.OnEncounterStart
function KwikTip:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    local hadManualPreview = clearManualPreview(self)
    local entry = self.BOSS_BY_ENCOUNTERID[encounterID]
    local _, _, instanceDifficulty = GetInstanceInfo()
    if entry and (not inDungeon(entry.dungeon) or difficultyID ~= instanceDifficulty) then
        -- A contradictory mode on this dungeon's event invalidates the old
        -- fight lock too. A foreign dungeon's ordinary event does not replace
        -- a valid fight in the current instance.
        if difficultyID ~= instanceDifficulty and self._activeBossEntry
            and self._activeBossEntry.dungeon == entry.dungeon then clearBoss(self) end
        self:UpdateContent()
        self:UpdateVisibility()
        return
    end
    -- Only the observed Zul'Farrak pair shares an overlapping lifecycle.
    -- Other starts replace it, including unknown starts, as before.
    local isPair = entry and entry.dungeon.instanceID == 209
        and (encounterID == 598 or encounterID == 599)
    if not isPair then self._pairedEncounters = nil end
    OnEncounterStart(self, encounterID, encounterName, difficultyID, groupSize)
    if isPair and self.bossActive then
        self._pairedEncounters = self._pairedEncounters or {}
        self._pairedEncounters[encounterID] = {
            entry = entry, name = encounterName, difficulty = difficultyID,
        }
    end
    -- The shared handler logs an unknown encounter and clears its entry, but
    -- can leave bossActive from a previous fight. Fail closed instead of
    -- retaining that previous fight's tip indefinitely.
    if not entry and self.bossActive then
        self.bossActive = false
        self:UpdateContent()
        self:UpdateVisibility()
    elseif hadManualPreview and not self.bossActive then
        self:SetContent("")
        self:UpdateContent()
        self:UpdateVisibility()
    end
end

local OnEncounterEnd = KwikTip.OnEncounterEnd
function KwikTip:OnEncounterEnd(success, encounterID)
    if self._activeBossEntry and not inDungeon(self._activeBossEntry.dungeon) then
        clearBoss(self)
        self:UpdateContent()
        self:UpdateVisibility()
        return
    end
    -- Late or unrelated end events must not terminate the current fight.
    if encounterID and self._activeEncounterID and encounterID ~= self._activeEncounterID
        and not (self._pairedEncounters and self._pairedEncounters[encounterID]) then return end
    if self._pairedEncounters then
        if encounterID then self._pairedEncounters[encounterID] = nil end
        local remainingID, remaining = next(self._pairedEncounters)
        if remaining then
            self._activeEncounterID = remainingID
            self._activeEncounterName = remaining.name
            self._activeDifficultyID = remaining.difficulty
            self._activeBossEntry = remaining.entry
            local content = self._FormatBossContent(remaining.entry.dungeon, remaining.entry.boss, remaining.difficulty)
            self:SetContent(self._AppendUserNote(content))
            self:UpdateVisibility()
            return
        end
        self._pairedEncounters = nil
    end
    local hadManualPreview = clearManualPreview(self)
    local entry = self._activeBossEntry
    OnEncounterEnd(self, success)
    if (success == 1 and entry
        and (entry.dungeon.previewNextBoss == false or not inDungeon(entry.dungeon)))
        or (hadManualPreview and not self.bossActive) then
        -- Preserve normal encounter cleanup, then restore the overview/quiet
        -- state for dungeons whose actual route has not been verified.
        self:SetContent("")
        self:UpdateContent()
        self:UpdateVisibility()
    end
end

local UpdateContent = KwikTip.UpdateContent
function KwikTip:UpdateContent()
    -- A zone change can arrive without ENCOUNTER_END (teleport/disconnect).
    -- Clear a stale fight before the shared engine's bossActive early return.
    if self._activeBossEntry and not inDungeon(self._activeBossEntry.dungeon) then
        clearBoss(self)
    end
    if self._manualBossPreview and not inDungeon(self._manualBossPreview.dungeon) then
        clearManualPreview(self)
    end
    UpdateContent(self)
    if self.previewActive then return end
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local dungeon = self.DUNGEON_BY_INSTANCEID[instanceID]
    if dungeon and not inDungeon(dungeon) then
        clearManualPreview(self)
        self.areaActive, self.dungeonActive = false, false
        self:SetContent("")
        self:UpdateVisibility()
        return
    end
    if not self.bossActive and self._manualBossPreview then
        local preview = self._manualBossPreview
        if inDungeon(preview.dungeon) then
            local _, _, difficultyID = GetInstanceInfo()
            local content = self._FormatBossContent(preview.dungeon, preview.boss, difficultyID)
            self.areaActive = false
            self.dungeonActive = false
            self:SetContent(self._AppendUserNote(content))
            self:UpdateVisibility()
            return
        end
        clearManualPreview(self)
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

local UpdateVisibility = KwikTip.UpdateVisibility
function KwikTip:UpdateVisibility()
    if KwikTipDB and KwikTipDB.persistentHide and not self.moveMode then
        if self.HUD then self.HUD:Hide() end
        if self.RefreshForeverBossPreviewUI and self.Config and self.Config:IsShown() then
            self:RefreshForeverBossPreviewUI()
        end
        return
    end
    if self._manualBossPreview then
        self:InitHUD()
        self.HUD:Show()
        self:_UpdatePrintBtn()
        self:_UpdateNoteBtn()
        if self.RefreshForeverBossPreviewUI and self.Config and self.Config:IsShown() then
            self:RefreshForeverBossPreviewUI()
        end
        return
    end
    UpdateVisibility(self)
    if self.RefreshForeverBossPreviewUI and self.Config and self.Config:IsShown() then
        self:RefreshForeverBossPreviewUI()
    end
end

local ShowPreview = KwikTip.ShowPreview
function KwikTip:ShowPreview()
    clearManualPreview(self)
    ShowPreview(self)
end

local prevSlash = SlashCmdList["KWIKTIP"]
SlashCmdList["KWIKTIP"] = function(msg)
    local trimmed = (msg or ""):match("^%s*(.-)%s*$")
    local lower = trimmed:lower()
    if lower == "boss" or lower:match("^boss%s+") then
        local arg = trimmed:match("^[bB][oO][sS][sS]%s*(.-)%s*$") or ""
        KwikTip:HandleBossCommand(arg)
        return
    end
    prevSlash(msg)
    if lower == "help" then
        print("  /kwik boss      — list or preview a boss tip in the current dungeon (out of combat)")
    end
end

local flavorFrame = CreateFrame("Frame")
flavorFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
flavorFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
flavorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
flavorFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
flavorFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        KwikTip._inCombat = true
        KwikTip:ClearBossPreview()
        if KwikTip.RefreshForeverBossPreviewUI then
            KwikTip:RefreshForeverBossPreviewUI()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        KwikTip._inCombat = false
        KwikTip:ClearBossPreview()
        if KwikTip.RefreshForeverBossPreviewUI then
            KwikTip:RefreshForeverBossPreviewUI()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not KwikTip:ClearBossPreview() and KwikTip.RefreshForeverBossPreviewUI then
            KwikTip:RefreshForeverBossPreviewUI()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if KwikTip._manualBossPreview and not inDungeon(KwikTip._manualBossPreview.dungeon) then
            KwikTip:ClearBossPreview()
        elseif KwikTip.RefreshForeverBossPreviewUI then
            KwikTip:RefreshForeverBossPreviewUI()
        end
    end
end)
