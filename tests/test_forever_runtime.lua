-- Offline integration check: load the actual generated addon in TOC order.
-- Usage: lua5.1 tests/test_forever_runtime.lua <KwikTip_Forever directory> [locale]
-- WoW APIs/frame geometry are stubs; this does not establish client compatibility.
-- Synthetic routing fixtures below never enter a distributed package.

local packageDir = assert(arg[1], "expected generated KwikTip_Forever directory")
local locale = arg[2] or "enUS"
local ADDON_NAME = "KwikTip_Forever"
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function contains(value, expected)
    return type(value) == "string" and value:find(expected, 1, true) ~= nil
end

local state = {
    inInstance = false, instanceType = "none", instanceID = 0,
    mapID = nil, subzone = "", instanceName = "Outside", difficultyID = 1,
}
local frames, textures = {}, {}
local Methods = {}
local newObject
local function noop() end
-- Unknown methods remain nil, so missing WoW dependencies fail explicitly.
for name in ([[SetFrameStrata SetClampedToScreen SetMovable SetResizable
    SetResizeBounds SetBackdrop SetBackdropColor SetBackdropBorderColor
    SetClipsChildren SetJustifyH SetJustifyV SetWordWrap SetAllPoints
    SetColorTexture SetPassThroughButtons EnableMouseWheel RegisterForDrag
    RegisterForClicks SetFontObject SetAutoFocus SetMaxLetters SetMultiLine
    StartMoving StopMovingOrSizing StartSizing SetTextColor SetShadowOffset
    SetShadowColor SetBlendMode SetOrientation SetObeyStepOnDrag SetThumbTexture
    LockHighlight UnlockHighlight ClearFocus HighlightText SetFocus
    SetCursorPosition SetOwner ClearLines AddLine]]):gmatch("%S+") do
    Methods[name] = noop
end
function Methods:SetScript(event, callback) self.scripts[event] = callback end
function Methods:HookScript(event, callback)
    local previous = self.scripts[event]
    self.scripts[event] = function(...)
        if previous then previous(...) end
        callback(...)
    end
end
function Methods:GetScript(event) return self.scripts[event] end
function Methods:RegisterEvent(event) self.events[event] = true end
function Methods:UnregisterEvent(event) self.events[event] = nil end
function Methods:SetPoint(...) self.point = { ... } end
function Methods:ClearAllPoints() self.point = nil end
function Methods:GetPoint()
    local unpackArgs = unpack or table.unpack
    return unpackArgs(self.point or { "CENTER", UIParent, "CENTER", 0, 0 })
end
function Methods:GetParent() return self.parent end
function Methods:SetSize(width, height) self.width, self.height = width, height end
function Methods:SetWidth(value) self.width = value end
function Methods:SetHeight(value) self.height = value end
function Methods:GetWidth() return self.width end
function Methods:GetHeight() return self.height end
function Methods:GetLeft() return 0 end
function Methods:GetBottom() return 0 end
function Methods:GetCenter() return self.width / 2, self.height / 2 end
function Methods:GetEffectiveScale() return 1 end
function Methods:SetFrameLevel(value) self.level = value end
function Methods:GetFrameLevel() return self.level end
function Methods:EnableMouse(value) self.mouseEnabled = value end
function Methods:IsMouseEnabled() return self.mouseEnabled end
function Methods:Show()
    local changed = not self.shown
    self.shown = true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Methods:Hide()
    local changed = self.shown
    self.shown = false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Methods:SetShown(value) if value then self:Show() else self:Hide() end end
function Methods:IsShown() return self.shown end
function Methods:SetAlpha(value) self.alpha = value end
function Methods:GetAlpha() return self.alpha end
function Methods:SetText(value) self.text = tostring(value or "") end
function Methods:GetText() return self.text end
function Methods:GetNumLetters() return #self.text end
function Methods:GetStringHeight()
    local _, count = self.text:gsub("\n", "\n")
    return (count + 1) * 12
end
function Methods:GetStringWidth() return #self.text * 6 end
function Methods:SetFont(...) self.font = { ... } end
function Methods:GetFont()
    local unpackArgs = unpack or table.unpack
    return unpackArgs(self.font or { "Fonts\\FRIZQT__.TTF", 11, "" })
end
function Methods:SetChecked(value) self.checked = value end
function Methods:GetChecked() return self.checked end
function Methods:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
function Methods:SetValueStep(value) self.step = value end
function Methods:GetValueStep() return self.step end
function Methods:SetValue(value)
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function Methods:GetValue() return self.value end
function Methods:SetScrollChild(value) self.scrollChild = value end
function Methods:GetVerticalScrollRange()
    return self.scrollChild and math.max(0, self.scrollChild:GetHeight() - self.height) or 0
end
function Methods:SetVerticalScroll(value) self.scroll = value end
function Methods:GetVerticalScroll() return self.scroll end
function Methods:CreateFontString(name)
    local child = newObject("FontString", name, self)
    return child
end
function Methods:CreateTexture(name)
    return newObject("Texture", name, self)
end
function Methods:SetTexture(path)
    self.texture = path
    if type(path) == "string" then textures[#textures + 1] = path end
end
newObject = function(kind, name, parent)
    local object = setmetatable({
        kind = kind, name = name, parent = parent, scripts = {}, events = {},
        width = 220, height = 80, shown = true, alpha = 1, level = 1,
        text = "", scroll = 0, value = 0, step = 1,
    }, { __index = Methods })
    frames[#frames + 1] = object
    if name then _G[name] = object end
    return object
end

UIParent = newObject("Frame", "UIParent")
UIParent:SetSize(1920, 1080)
Minimap = newObject("Frame", "Minimap", UIParent)
Minimap:SetSize(140, 140)
GameTooltip = newObject("Tooltip", "GameTooltip", UIParent)
GameFontNormal = {}
SlashCmdList = {}
StaticPopupDialogs = {}
CLOSE = "Close"
StaticPopup_Show = noop
CreateFrame = function(kind, name, parent, template)
    local object = newObject(kind, name, parent)
    if template == "BasicFrameTemplate" or template == "BasicFrameTemplateWithInset" then
        object.TitleText = object:CreateFontString(nil)
    end
    return object
end
GetLocale = function() return locale end
GetBuildInfo = function() return "1.60.1", "70707", "test-date", 16001 end
IsInInstance = function() return state.inInstance, state.instanceType end
GetInstanceInfo = function()
    return state.instanceName, state.instanceType, state.difficultyID,
        "Normal", 5, 0, false, state.instanceID
end
GetSubZoneText = function() return state.subzone end
UnitGroupRolesAssigned = function() return "HEALER" end
UnitCanAttack = function() return false end
UnitIsPlayer = function() return false end
InCombatLockdown = function() return false end
GetCursorPosition = function() return 0, 0 end
IsShiftKeyDown = function() return false end
date = function() return "test-time" end
C_Map = {
    GetBestMapForUnit = function() return state.mapID end,
    GetPlayerMapPosition = function() return nil end,
}
C_Timer = {
    After = function(_, callback) callback() end,
    NewTimer = function() return { Cancel = noop } end,
}
UIFrameFadeIn = function(object, _, _, alpha) object:SetAlpha(alpha) end
UIFrameFadeOut = UIFrameFadeIn
LibStub = nil
C_ChallengeMode = nil
C_ScenarioInfo = nil
KwikTip = nil
KwikTipDB = nil

local addon = {}
local toc = assert(io.open(packageDir .. "/" .. ADDON_NAME .. ".toc", "r"))
local manifestFiles = {}
for line in toc:lines() do
    local relative = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
    if relative:match("%.lua$") then manifestFiles[#manifestFiles + 1] = relative:gsub("\\", "/") end
end
toc:close()
check(#manifestFiles > 0, "TOC contains Lua files")
for _, relative in ipairs(manifestFiles) do
    local chunk, loadError = loadfile(packageDir .. "/" .. relative)
    assert(chunk, loadError)
    local success, result = pcall(chunk, ADDON_NAME, addon)
    assert(success, relative .. ": " .. tostring(result))
end
check(_G.KwikTip == nil, "addon namespace must remain private")
for _, name in ipairs({ "DUNGEON_BY_INSTANCEID", "DUNGEON_BY_UIMAPID", "BOSS_BY_ENCOUNTERID" }) do
    check(type(addon[name]) == "table", "package initializes " .. name)
end
check(type(addon.DUNGEONS) == "table", "Forever data table exists")
check(#addon.DUNGEONS == 3, "alpha manifest contains exactly three dungeon records")
local hall = addon.DUNGEON_BY_INSTANCEID[3065]
local ragefire = addon.DUNGEON_BY_INSTANCEID[389]
local stockade = addon.DUNGEON_BY_INSTANCEID[34]
check(hall ~= nil and ragefire ~= nil and stockade ~= nil,
    "alpha manifest indexes Hall, Ragefire, and Stockade by verified instance identity")
local expectedIDs = { 3493, 3495, 3494, 3496 } -- Wago build 70707 OrderIndex
check(#hall.bosses == #expectedIDs, "all four Hall encounter records are present")
for i, encounterID in ipairs(expectedIDs) do
    check(hall.bosses[i].encounterID == encounterID, "Hall encounter order matches raw DB2")
end
local expectedRagefireIDs = { 2732, 2733, 2734, 2735 }
local expectedRagefireNames = { "Oggleflint", "Taragaman the Hungerer", "Jergosh the Invoker", "Bazzalan" }
check(#ragefire.bosses == #expectedRagefireIDs, "all four Ragefire encounter records are present")
for i, encounterID in ipairs(expectedRagefireIDs) do
    check(ragefire.bosses[i].encounterID == encounterID, "Ragefire encounter identity matches raw DB2")
    check(ragefire.bosses[i].name == expectedRagefireNames[i], "Ragefire encounter name matches verified source record")
end
local expectedStockadeIDs = { 2756, 2757, 2758, 2759, 2760 }
local expectedStockadeNames = { "Targorr the Dread", "Kam Deepfury", "Hamhock", "Dextren Ward", "Bazil Thredd" }
check(#stockade.bosses == #expectedStockadeIDs, "Stockade ships only the five source-backed baseline encounters")
for i, encounterID in ipairs(expectedStockadeIDs) do
    check(stockade.bosses[i].encounterID == encounterID, "Stockade encounter identity matches raw DB2")
    check(stockade.bosses[i].name == expectedStockadeNames[i], "Stockade encounter name matches verified source record")
end
local encounterCount = 0
for _ in pairs(addon.BOSS_BY_ENCOUNTERID) do encounterCount = encounterCount + 1 end
check(encounterCount == 13, "alpha manifest indexes exactly thirteen encounter records")
for _, dungeon in ipairs({ hall, ragefire, stockade }) do
    check(type(dungeon.difficultyIDs) == "table" and #dungeon.difficultyIDs == 1
        and dungeon.difficultyIDs[1] == 1,
        "shipped dungeon explicitly restricts sourced advice to Normal difficulty")
end
check(hall.uiMapID == nil and hall.areas == nil and next(addon.DUNGEON_BY_UIMAPID) == nil,
    "no guessed Hall city-map or subzone fallback is shipped")
check(ragefire.uiMapID == nil and ragefire.areas == nil,
    "no guessed Ragefire city-map or subzone fallback is shipped")
check(stockade.uiMapID == nil and stockade.areas == nil,
    "no guessed Stockade city-map or subzone fallback is shipped")
check(contains(hall.bosses[2].tip, "Provisional"), "unverified guide-name association stays visible")
check(next(addon.SUBZONE_LOCALE_BY_AREA_ID or {}) == nil,
    "scaffold does not import Retail subzone aliases")

local function emit(event, ...)
    -- Snapshot because production event handlers may allocate frames.
    local count = #frames
    for i = 1, count do
        local frame = frames[i]
        if frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, event, ...)
        end
    end
end
emit("ADDON_LOADED", "OtherAddon")
check(KwikTipDB == nil, "unrelated addon event does not initialize SavedVariables")
emit("ADDON_LOADED", ADDON_NAME)
check(type(KwikTipDB) == "table" and type(KwikTipDB.encounterLog) == "table",
    "actual ADDON_LOADED initializes settings and logs")
KwikTipDB.width, KwikTipDB.alpha, KwikTipDB.fontSize = 337, 0.66, nil
emit("ADDON_LOADED", ADDON_NAME)
check(KwikTipDB.width == 337 and KwikTipDB.alpha == 0.66 and KwikTipDB.fontSize == 11,
    "production settings initialization preserves preferences and seeds missing defaults")
emit("PLAYER_LOGIN")
check(addon.HUD ~= nil, "actual PLAYER_LOGIN initializes HUD")
check(not addon.HUD:IsShown(), "HUD hidden outside an instance after login")
check(not addon.HUD:IsMouseEnabled(), "normal HUD leaves mouse input to the game")
check(addon.MinimapBtn ~= nil, "actual PLAYER_LOGIN creates minimap button")
addon:ToggleConfig()
check(addon.Config and addon.Config:IsShown(), "actual lazy settings window opens")
addon:ToggleConfig()
check(not addon.Config:IsShown(), "settings window closes")

local assetTextures = 0
for _, path in ipairs(textures) do
    if path:find("Interface\\AddOns\\", 1, true) then
        check(path:find("Interface\\AddOns\\KwikTip_Forever\\", 1, true) == 1,
            "addon texture points into Forever package: " .. path)
        local relative = path:sub(#("Interface\\AddOns\\KwikTip_Forever\\") + 1):gsub("\\", "/")
        local asset = io.open(packageDir .. "/" .. relative, "rb")
        check(asset ~= nil, "referenced texture is packaged: " .. relative)
        if asset then asset:close() end
        assetTextures = assetTextures + 1
    end
end
check(assetTextures >= 3, "minimap/settings create all three packaged asset references")

-- Exercise every shipped encounter through the actual event path. This verifies
-- data-to-runtime wiring with simulated client events, never an in-game pass.
for _, shippedDungeon in ipairs(addon.DUNGEONS) do
    check(addon.DUNGEON_BY_INSTANCEID[shippedDungeon.instanceID] == shippedDungeon,
        "shipped dungeon has a working instance index")
    state.inInstance, state.instanceType = true, "party"
    state.instanceID, state.mapID = shippedDungeon.instanceID, shippedDungeon.uiMapID
    state.instanceName, state.subzone = "Localized shipped dungeon", ""
    emit("PLAYER_ENTERING_WORLD")
    for _, shippedBoss in ipairs(shippedDungeon.bosses or {}) do
        emit("ENCOUNTER_START", shippedBoss.encounterID, "Localized shipped boss", 1, 5)
        check(addon.bossActive and addon._activeBossEntry.boss == shippedBoss,
            "shipped encounter resolves through its production index")
        check(contains(addon._lastContent, shippedBoss.tip),
            "shipped encounter renders its authored tip")
        emit("ENCOUNTER_END", shippedBoss.encounterID, "Localized shipped boss", 1, 5, 0)
    end

    for _, shippedBoss in ipairs(shippedDungeon.bosses or {}) do
        state.instanceID, state.mapID = 990001, nil
        state.instanceName = "Unrelated synthetic party instance"
        emit("PLAYER_ENTERING_WORLD")
        emit("ENCOUNTER_START", shippedBoss.encounterID, "Wrong-instance shipped boss", 1, 5)
        check(not addon.bossActive and addon._activeBossEntry == nil
            and addon._lastContent == "" and not addon.HUD:IsShown(),
            "each shipped encounter fails closed in an unrelated instance")

        for _, otherDungeon in ipairs(addon.DUNGEONS) do
            if otherDungeon ~= shippedDungeon then
                state.instanceID, state.mapID = otherDungeon.instanceID, otherDungeon.uiMapID
                state.instanceName = "Localized other shipped dungeon"
                emit("PLAYER_ENTERING_WORLD")
                emit("ENCOUNTER_START", shippedBoss.encounterID, "Cross-dungeon shipped boss", 1, 5)
                check(not addon.bossActive and addon._activeBossEntry == nil
                    and addon._lastContent == "" and not addon.HUD:IsShown(),
                    "each shipped encounter is rejected in every other shipped dungeon")
            end
        end
    end

    state.instanceID, state.mapID = shippedDungeon.instanceID, shippedDungeon.uiMapID
    state.instanceName = "Localized current shipped dungeon"
    emit("PLAYER_ENTERING_WORLD")
    local ownBoss = shippedDungeon.bosses[1]
    for _, foreignDungeon in ipairs(addon.DUNGEONS) do
        if foreignDungeon ~= shippedDungeon then
            emit("ENCOUNTER_START", ownBoss.encounterID, "Legitimate current encounter", 1, 5)
            emit("ENCOUNTER_START", foreignDungeon.bosses[1].encounterID, "Rejected foreign encounter", 1, 5)
            check(addon.bossActive and addon._activeBossEntry.boss == ownBoss
                and contains(addon._lastContent, "Legitimate current encounter")
                and not contains(addon._lastContent, "Rejected foreign encounter"),
                "a foreign dungeon event cannot replace the current dungeon's active boss tip")
            emit("ENCOUNTER_END", ownBoss.encounterID, "Legitimate current encounter", 1, 5, 0)
        end
    end

    -- Normal-only guide text stays hidden in alternate/unknown modes rather
    -- than silently promising identical mechanics outside its sourced mode.
    KwikTipDB.showInDungeon = true
    for _, unsupportedDifficulty in ipairs({ 201, 214 }) do
        state.instanceID, state.mapID, state.difficultyID = shippedDungeon.instanceID, nil, unsupportedDifficulty
        emit("PLAYER_ENTERING_WORLD")
        check(addon._lastContent == "" and not addon.HUD:IsShown(),
            "alternate difficulty " .. unsupportedDifficulty .. " cannot activate shipped dungeon content")
        for _, shippedBoss in ipairs(shippedDungeon.bosses) do
            emit("ENCOUNTER_START", shippedBoss.encounterID, "Unsupported alternate-mode boss", unsupportedDifficulty, 5)
            check(not addon.bossActive and addon._activeBossEntry == nil
                and addon._lastContent == "" and not addon.HUD:IsShown(),
                "each shipped boss fails closed in unsupported alternate difficulty " .. unsupportedDifficulty)
        end
    end
    for _, unknownDifficulty in ipairs({ "nil", "zero" }) do
        state.difficultyID = unknownDifficulty == "zero" and 0 or nil
        emit("PLAYER_ENTERING_WORLD")
        check(addon._lastContent == "" and not addon.HUD:IsShown(),
            "unknown or zero difficulty cannot activate shipped dungeon content")
        emit("ENCOUNTER_START", ownBoss.encounterID, "Unknown-difficulty boss", state.difficultyID, 5)
        check(not addon.bossActive and addon._activeBossEntry == nil
            and addon._lastContent == "" and not addon.HUD:IsShown(),
            "known encounter with unknown or zero difficulty fails closed")
    end
    KwikTipDB.showInDungeon = false
    state.difficultyID = 1
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", ownBoss.encounterID, "Normal-mode recovery boss", 1, 5)
    check(addon.bossActive and contains(addon._lastContent, ownBoss.tip),
        "returning to Normal difficulty restores the sourced encounter tip")
    emit("ENCOUNTER_END", ownBoss.encounterID, "Normal-mode recovery boss", 1, 5, 0)

    -- The event mode is a separate client signal. A Normal instance cannot
    -- make an alternate/unknown encounter mode safe by implication, and a
    -- rejected event must not retain the previous fight's lock or text.
    for _, eventModeCase in ipairs({ "alternate", "alternate214", "nil", "zero" }) do
        local eventMode = eventModeCase == "alternate" and 201
            or eventModeCase == "alternate214" and 214
            or eventModeCase == "zero" and 0 or nil
        for _, showOverview in ipairs({ false, true }) do
            KwikTipDB.showInDungeon = showOverview
            state.difficultyID = 1
            emit("PLAYER_ENTERING_WORLD")
            emit("ENCOUNTER_START", ownBoss.encounterID, "Valid Normal fight before contradictory event", 1, 5)
            check(addon.bossActive and addon._activeBossEntry.boss == ownBoss,
                "Normal instance and matching Normal event establish a valid fight")
            emit("ENCOUNTER_START", ownBoss.encounterID, "Contradictory event mode", eventMode, 5)
            check(not addon.bossActive and addon._activeBossEntry == nil
                and addon._activeEncounterID == nil,
                "alternate or unknown event mode clears the old Normal fight lock")
            if showOverview then
                check(contains(addon._lastContent, shippedDungeon.overview)
                    and not contains(addon._lastContent, "Valid Normal fight before contradictory event"),
                    "rejected event mode restores the opted-in overview instead of stale fight text")
            else
                check(addon._lastContent == "" and not addon.HUD:IsShown(),
                    "rejected event mode clears fight text and hides HUD when overview is off")
            end
            emit("ENCOUNTER_START", ownBoss.encounterID, "Recovered matching Normal event", 1, 5)
            check(addon.bossActive and addon._activeBossEntry.boss == ownBoss
                and contains(addon._lastContent, "Recovered matching Normal event"),
                "a matching Normal event recovers after the rejected event mode")
            emit("ENCOUNTER_END", ownBoss.encounterID, "Recovered matching Normal event", 1, 5, 0)
        end
    end
    KwikTipDB.showInDungeon = false
end

-- The Hall overview is an explicit instance-wide option, not inferred area or
-- target coverage. These are simulated client routes, not observed game IDs.
check(type(hall.overview) == "string" and hall.overview ~= "",
    "Hall ships a nonempty optional instance overview")
state.inInstance, state.instanceType = true, "party"
state.instanceID, state.mapID = 3065, nil
state.instanceName, state.subzone = "Localized Hall overview test", ""
check(KwikTipDB.showInDungeon == false, "instance-wide overview remains off by default")
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "Hall entry is quiet with the default overview setting")
KwikTipDB.showInDungeon = true
emit("ZONE_CHANGED")
check(contains(addon._lastContent, hall.overview) and addon.HUD:IsShown(),
    "opted-in overview renders for Hall instance even without a UI map")
check(contains(addon._lastContent, state.instanceName),
    "overview header uses localized client instance name")
KwikTipDB.notes["3065"] = "HALL_OVERVIEW_PERSONAL_NOTE"
emit("ZONE_CHANGED")
check(contains(addon._lastContent, hall.overview)
    and contains(addon._lastContent, "HALL_OVERVIEW_PERSONAL_NOTE"),
    "overview includes the player's saved instance note")
emit("ZONE_CHANGED")
local _, personalNoteCount = addon._lastContent:gsub("HALL_OVERVIEW_PERSONAL_NOTE", "")
check(personalNoteCount == 1 and KwikTipDB.notes["3065"] == "HALL_OVERVIEW_PERSONAL_NOTE",
    "overview refresh preserves the saved note and displays it once")
KwikTipDB.persistentHide = true
addon:UpdateVisibility()
check(not addon.HUD:IsShown(), "Disable Tips hides the opted-in Hall overview")
KwikTipDB.persistentHide = false
addon:UpdateVisibility()
check(addon.HUD:IsShown(), "reenabling tips restores an eligible Hall overview")

addon:ShowPreview()
check(addon.previewActive and contains(addon._lastContent, addon.L.DEMO_DUNGEON)
    and not contains(addon._lastContent, hall.overview),
    "settings preview takes priority over the Hall overview")
emit("ZONE_CHANGED")
check(contains(addon._lastContent, addon.L.DEMO_DUNGEON),
    "overview updates do not overwrite an active settings preview")
addon:ClearPreview()
check(not addon.previewActive and contains(addon._lastContent, hall.overview),
    "clearing the settings preview restores the opted-in overview")

local hallFirstBoss, hallSecondBoss = hall.bosses[1], hall.bosses[2]
emit("ENCOUNTER_START", hallFirstBoss.encounterID, "Known Hall boss priority test", 1, 5)
check(addon.bossActive and contains(addon._lastContent, hallFirstBoss.tip)
    and not contains(addon._lastContent, hall.overview),
    "actual known Hall boss tip takes priority over the overview")
emit("ZONE_CHANGED")
check(contains(addon._lastContent, hallFirstBoss.tip)
    and not contains(addon._lastContent, hall.overview),
    "overview updates preserve the active Hall fight tip")
emit("ENCOUNTER_END", hallFirstBoss.encounterID, "Known Hall boss priority test", 1, 5, 1)
check(not addon.bossActive and contains(addon._lastContent, hallSecondBoss.tip)
    and not contains(addon._lastContent, hall.overview),
    "successful Hall boss completion shows the next-boss preview before the overview")

emit("ENCOUNTER_START", hallFirstBoss.encounterID, "Hall before mode transition", 1, 5)
state.difficultyID = 201
emit("ENCOUNTER_END", hallFirstBoss.encounterID, "Hall before mode transition", 1, 5, 1)
check(not addon.bossActive and addon._lastContent == "" and not addon.HUD:IsShown(),
    "encounter end after an unsupported mode transition cannot leak a next-boss preview")
state.difficultyID = 1
emit("PLAYER_ENTERING_WORLD")

emit("ENCOUNTER_START", hallFirstBoss.encounterID, "Known Hall boss before unrelated event", 1, 5)
emit("ENCOUNTER_START", 993001, "Unrelated synthetic encounter", 1, 5)
check(not addon.bossActive and addon._activeBossEntry == nil,
    "an unrelated encounter arriving during a known Hall fight clears the stale boss lock")
check(not contains(addon._lastContent, "Known Hall boss before unrelated event")
    and contains(addon._lastContent, hall.overview),
    "an unrelated encounter replaces the stale Hall boss content with the opted-in overview")
KwikTipDB.showInDungeon = false
emit("ENCOUNTER_START", hallFirstBoss.encounterID, "Known Hall boss before unknown event", 1, 5)
check(addon.bossActive and contains(addon._lastContent, hallFirstBoss.tip),
    "disabling the overview preserves normal known encounter tips")
emit("ENCOUNTER_START", 993002, "Another unrelated synthetic encounter", 1, 5)
check(not addon.bossActive and addon._activeBossEntry == nil
    and addon._lastContent == "" and not addon.HUD:IsShown(),
    "unknown encounter clears stale boss content and hides HUD when overview is off")
KwikTipDB.showInDungeon = true
emit("PLAYER_ENTERING_WORLD")

-- A city/map/subzone/target name cannot replace the verified instance identity.
-- Target API traps make accidental name/GUID-based fallback fail loudly.
local previousUnitName, previousUnitGUID = UnitName, UnitGUID
UnitName = function() error("Hall overview must not inspect a target name") end
UnitGUID = function() error("Hall overview must not inspect a target GUID") end
state.inInstance, state.instanceType, state.instanceID = false, "none", 0
state.instanceName, state.subzone, state.mapID = "The Hall of Thanes", "The Hall of Thanes", 3065
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "Hall-like city map and names do not activate the overview outside an instance")
state.inInstance, state.instanceType, state.instanceID = true, "party", 993003
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "Hall-like map/subzone names do not activate overview in an unrelated party instance")
state.instanceID, state.mapID = nil, 3065
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "missing instance identity fails closed even when map/name resembles Hall")
emit("ENCOUNTER_START", hallFirstBoss.encounterID, "Hall boss without instance identity", 1, 5)
check(not addon.bossActive and not addon.HUD:IsShown(),
    "known Hall encounter without its verified instance identity fails closed")
state.instanceID, state.mapID, state.instanceType = 3065, nil, "raid"
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "raid mode cannot activate the Hall overview")
emit("ENCOUNTER_START", hallFirstBoss.encounterID, "Hall boss in unsupported raid", 1, 5)
check(not addon.bossActive and not addon.HUD:IsShown(),
    "known Hall encounter in unsupported raid mode fails closed")
state.instanceType = "party"
emit("PLAYER_ENTERING_WORLD")
check(contains(addon._lastContent, hall.overview),
    "verified Hall party instance restores overview without a UI map or target fallback")
UnitName, UnitGUID = previousUnitName, previousUnitGUID
KwikTipDB.notes["3065"] = nil
KwikTipDB.showInDungeon = false
state.inInstance, state.instanceType, state.instanceID, state.mapID = false, "none", 0, nil
emit("PLAYER_ENTERING_WORLD")

local function checkUnorderedClassicDungeon(dungeon, label, noteText)
    local noteKey = tostring(dungeon.instanceID)
    -- A Classic encounter roster is not an asserted player route. After a kill, the
    -- alpha returns to the user's overview choice instead of predicting a boss.
    check(dungeon.previewNextBoss == false, label .. " explicitly disables route-order boss previews")
    check(type(dungeon.overview) == "string" and dungeon.overview ~= "",
        label .. " ships a nonempty optional instance overview")
    state.inInstance, state.instanceType = true, "party"
    state.instanceID, state.mapID = dungeon.instanceID, nil
    state.instanceName, state.subzone = "Localized " .. label .. " alpha test", ""
    check(KwikTipDB.showInDungeon == false, label .. " overview is quiet by default")
    emit("PLAYER_ENTERING_WORLD")
    check(addon._lastContent == "" and not addon.HUD:IsShown(),
        label .. " entry remains hidden without an opted-in overview")
    for _, boss in ipairs(dungeon.bosses) do
        emit("ENCOUNTER_START", boss.encounterID, "Localized " .. label .. " boss", 1, 5)
        check(addon.bossActive and contains(addon._lastContent, boss.tip),
            label .. " encounter tips still activate with overview disabled")
        emit("ENCOUNTER_END", boss.encounterID, "Localized " .. label .. " boss", 1, 5, 1)
        check(not addon.bossActive and addon._activeBossEntry == nil
            and addon._lastContent == "" and not addon.HUD:IsShown(),
            "each " .. label .. " kill clears the fight without guessing a next boss")
    end
    KwikTipDB.showInDungeon = true
    emit("ZONE_CHANGED")
    check(contains(addon._lastContent, dungeon.overview) and addon.HUD:IsShown(),
        label .. " overview renders only after the existing setting is enabled")
    check(contains(addon._lastContent, state.instanceName),
        label .. " overview uses the localized instance header")
    KwikTipDB.notes[noteKey] = noteText
    emit("ZONE_CHANGED")
    check(contains(addon._lastContent, noteText)
        and KwikTipDB.notes[noteKey] == noteText,
        label .. " overview preserves and displays the player's own note")
    emit("ENCOUNTER_START", dungeon.bosses[1].encounterID, label .. " fight overrides overview", 1, 5)
    check(addon.bossActive and contains(addon._lastContent, dungeon.bosses[1].tip)
        and not contains(addon._lastContent, dungeon.overview),
        label .. " boss tip takes priority over the opted-in overview")
    emit("ENCOUNTER_END", dungeon.bosses[1].encounterID, label .. " fight overrides overview", 1, 5, 1)
    check(not addon.bossActive and addon._activeBossEntry == nil
        and contains(addon._lastContent, dungeon.overview)
        and contains(addon._lastContent, noteText),
        label .. " kill returns to overview and personal note instead of a route prediction")
    state.instanceType = "raid"
    emit("PLAYER_ENTERING_WORLD")
    check(addon._lastContent == "" and not addon.HUD:IsShown(),
        label .. " overview fails closed in unsupported raid mode")
    state.instanceType, state.instanceID, state.mapID = "party", nil, dungeon.instanceID
    state.instanceName, state.subzone = dungeon.name, dungeon.name
    emit("PLAYER_ENTERING_WORLD")
    check(addon._lastContent == "" and not addon.HUD:IsShown(),
        label .. " map and names cannot substitute for its verified instance identity")
    KwikTipDB.notes[noteKey] = nil
    KwikTipDB.showInDungeon = false
    state.inInstance, state.instanceType, state.instanceID, state.mapID = false, "none", 0, nil
    emit("PLAYER_ENTERING_WORLD")
end
checkUnorderedClassicDungeon(ragefire, "Ragefire", "RAGEFIRE_ALPHA_PERSONAL_NOTE")
checkUnorderedClassicDungeon(stockade, "Stockade", "STOCKADE_ALPHA_PERSONAL_NOTE")

-- This high encounter ID is a synthetic negative fixture, not a guessed rare
-- ID. A familiar rare name cannot create automatic coverage absent raw IDs.
state.inInstance, state.instanceType, state.instanceID = true, "party", 34
state.difficultyID, state.mapID, state.subzone = 1, nil, ""
state.instanceName = "Localized Stockade rare exclusion test"
for _, showOverview in ipairs({ false, true }) do
    KwikTipDB.showInDungeon = showOverview
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", 994001, "Bruegal Ironknuckle", 1, 5)
    check(not addon.bossActive and addon._activeBossEntry == nil,
        "unregistered synthetic encounter named Bruegal does not activate a Stockade boss tip")
    if showOverview then
        check(contains(addon._lastContent, stockade.overview),
            "an unregistered rare name preserves only the opted-in Stockade overview")
    else
        check(addon._lastContent == "" and not addon.HUD:IsShown(),
            "an unregistered rare name leaves the default Stockade HUD hidden")
    end
end
KwikTipDB.showInDungeon = false
state.inInstance, state.instanceType, state.instanceID, state.mapID = false, "none", 0, nil
emit("PLAYER_ENTERING_WORLD")

-- Empty/unsupported routes must work before tests add any fixture data.
state.inInstance, state.instanceType, state.instanceID = true, "party", 990001
state.instanceName, state.subzone, state.mapID = "Unknown fixture instance", "Unknown area", 990002
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "unsupported instance has no content and remains hidden")
emit("ENCOUNTER_START", 990003, "Unknown fixture boss", 1, 5)
check(not addon.bossActive and not addon.HUD:IsShown(), "unknown encounter does not activate HUD")
emit("ENCOUNTER_END", 990003, "Unknown fixture boss", 1, 5, 0)

-- Fixtures are intentionally synthetic high IDs, unrelated to Hall of Thanes.
local boss1 = { encounterID = 991003, name = "Synthetic first boss", tip = "SYNTHETIC_FIRST_TIP" }
local boss2 = { encounterID = 991004, name = "Synthetic second boss", tip = "SYNTHETIC_SECOND_TIP" }
local dungeon = {
    instanceID = 991001, uiMapID = 991002, name = "Synthetic dungeon", mythicPlus = false,
    bosses = { boss1, boss2 },
    areas = {
        { id = "991001:1", subzone = "Synthetic corridor", tip = "SYNTHETIC_CORRIDOR_TIP" },
        { id = "991001:2", subzone = "Synthetic boss room", bossIndex = 1 },
    },
}
-- Production indexes must already exist. Build new fixture indexes through the
-- shipped initializer rather than implementing or preseeding its tables here.
check(type(addon.BuildRuntimeIndexes) == "function", "package exposes runtime index initialization")
addon.DUNGEONS = { dungeon }
addon:BuildRuntimeIndexes()
check(addon.DUNGEON_BY_INSTANCEID[dungeon.instanceID] == dungeon,
    "production initializer indexes synthetic instance")
check(addon.DUNGEON_BY_UIMAPID[dungeon.uiMapID] == dungeon,
    "production initializer indexes synthetic UI map")
check(addon.BOSS_BY_ENCOUNTERID[boss1.encounterID].boss == boss1,
    "production initializer indexes synthetic encounter")
local savedID = dungeon.instanceID
dungeon.instanceID = 0
check(not pcall(addon.BuildRuntimeIndexes, addon), "initializer rejects placeholder zero IDs")
dungeon.instanceID = savedID
addon.DUNGEONS = { dungeon, { instanceID = savedID, bosses = {} } }
check(not pcall(addon.BuildRuntimeIndexes, addon), "initializer rejects duplicate instance identities")
addon.DUNGEONS = { dungeon }
addon:BuildRuntimeIndexes()
state.instanceID, state.mapID = dungeon.instanceID, dungeon.uiMapID
state.instanceName, state.subzone = "Localized synthetic dungeon", "Synthetic corridor"
emit("ZONE_CHANGED_NEW_AREA")
check(contains(addon._lastContent, "SYNTHETIC_CORRIDOR_TIP"), "production detection routes by instance ID")
check(contains(addon._lastContent, state.instanceName), "area header uses localized client instance name")
check(addon.HUD:IsShown(), "matched area shows actual HUD")
state.instanceID = 992001
emit("ZONE_CHANGED_NEW_AREA")
check(contains(addon._lastContent, "SYNTHETIC_CORRIDOR_TIP"), "production detection routes by UI map fallback")
state.mapID = 992002
emit("ZONE_CHANGED_NEW_AREA")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "same subzone text in another instance/map does not leak a tip")
emit("ENCOUNTER_START", boss1.encounterID, "Wrong-instance synthetic boss", 1, 5)
check(not addon.bossActive and not addon.HUD:IsShown(),
    "known encounter from another instance does not activate HUD")
emit("ENCOUNTER_END", boss1.encounterID, "Wrong-instance synthetic boss", 1, 5, 0)
state.instanceID, state.mapID = dungeon.instanceID, dungeon.uiMapID
state.subzone = "Synthetic boss room"
emit("ZONE_CHANGED")
check(contains(addon._lastContent, "SYNTHETIC_FIRST_TIP"), "production subzone event previews the associated boss")
state.subzone = "Synthetic corridor"
emit("ENCOUNTER_START", boss1.encounterID, "Localized synthetic boss", 1, 5)
check(addon.bossActive and contains(addon._lastContent, "SYNTHETIC_FIRST_TIP"),
    "production encounter event locks the first boss tip")
check(contains(addon._lastContent, "Localized synthetic boss"), "boss header uses localized encounter event name")
check(KwikTipDB.encounterLog[#KwikTipDB.encounterLog].encounterID == boss1.encounterID,
    "production encounter logger records the event")
emit("ZONE_CHANGED")
check(contains(addon._lastContent, "SYNTHETIC_FIRST_TIP"), "area changes do not replace an active boss tip")
emit("ENCOUNTER_END", boss1.encounterID, "Localized synthetic boss", 1, 5, 1)
check(not addon.bossActive and contains(addon._lastContent, "SYNTHETIC_SECOND_TIP"),
    "successful encounter advances to the next authored boss")
emit("ENCOUNTER_START", boss1.encounterID, "Localized synthetic boss", 1, 5)
emit("ENCOUNTER_END", boss1.encounterID, "Localized synthetic boss", 1, 5, 0)
check(contains(addon._lastContent, "SYNTHETIC_CORRIDOR_TIP"), "wipe restores production area routing")
emit("ENCOUNTER_START", boss1.encounterID, "Localized synthetic boss", 1, 5)
state.inInstance, state.instanceType, state.instanceID, state.mapID = false, "none", 0, nil
emit("PLAYER_ENTERING_WORLD")
check(not addon.bossActive and addon._lastContent == "" and not addon.HUD:IsShown(),
    "teleport out without encounter end clears stale boss state and HUD")
state.inInstance, state.instanceType = true, "party"
state.instanceID, state.mapID = dungeon.instanceID, dungeon.uiMapID
emit("PLAYER_ENTERING_WORLD")
check(contains(addon._lastContent, "SYNTHETIC_CORRIDOR_TIP"),
    "reentering after an interrupted fight restores normal routing")
KwikTipDB.persistentHide = true
addon:UpdateVisibility()
check(not addon.HUD:IsShown(), "Disable Tips hides the HUD")
KwikTipDB.persistentHide = false
state.inInstance, state.instanceType = false, "none"
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(), "leaving the instance clears content and HUD")
check(_G.KwikTip == nil, "runtime never publishes a global addon namespace")

io.write(string.format("Forever offline runtime (%s): %d assertions passed\n", locale, checks))
