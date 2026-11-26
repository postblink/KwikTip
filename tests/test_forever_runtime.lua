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
check(#addon.DUNGEONS == 28, "candidate contains exactly twenty-eight dungeon records")
local hall = addon.DUNGEON_BY_INSTANCEID[3065]
local ragefire = addon.DUNGEON_BY_INSTANCEID[389]
local stockade = addon.DUNGEON_BY_INSTANCEID[34]
local deadmines = addon.DUNGEON_BY_INSTANCEID[36]
local caverns = addon.DUNGEON_BY_INSTANCEID[43]
local dalaran = addon.DUNGEON_BY_INSTANCEID[2959]
local excavation = addon.DUNGEON_BY_INSTANCEID[2998]
local ruins = addon.DUNGEON_BY_INSTANCEID[2999]
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
check(ruins ~= nil, "Ruins is indexed by exact instance ID")
local ruinsIDs = { 3353, 3357, 3411, 3412, 3354, 3355 }
check(#ruins.bosses == #ruinsIDs, "Ruins includes the observed Butcher event")
for i, id in ipairs(ruinsIDs) do
    check(ruins.bosses[i].encounterID == id, "Ruins ID matches preserved DB2")
end
check(addon.BOSS_BY_ENCOUNTERID[3355] ~= nil and addon.BOSS_BY_ENCOUNTERID[3408] == nil,
    "The Butcher is bound, but the rare Captain remains excluded")
check(ruins.uiMapID == nil and ruins.areas == nil, "no guessed Ruins map/area routing")
check(excavation ~= nil and #excavation.bosses == 4, "Excavation has four admitted event records")
for i, id in ipairs({3480, 3481, 3644, 3482}) do
    check(excavation.bosses[i].encounterID == id, "Excavation matches preserved DB2 IDs")
end
check(excavation.uiMapID == nil and excavation.areas == nil, "no guessed Excavation routing")
check(not contains(excavation.bosses[2].tip, "%"), "no disputed enrage threshold shipped")
check(dalaran ~= nil and #dalaran.bosses == 8, "Dalaran includes the observed Mana Elemental")
for i, id in ipairs({3311,3310,3298,3299,3300,3301,3302,3303}) do
    check(dalaran.bosses[i].encounterID == id, "Dalaran exact DB2 identity")
end
check(addon.BOSS_BY_ENCOUNTERID[3301] ~= nil and addon.BOSS_BY_ENCOUNTERID[3312] == nil, "no invented Dalaran aliases")
check(addon.DUNGEON_BY_INSTANCEID[2980] == nil, "non-dungeon Dalaran map excluded")
for _, id in ipairs({2694,2697,2699,2704,2710,2761,2762,2763,2764,2765,2766,2767,2825,2891,2899,2925,2927,2928,2935,2940}) do
    check(addon.BOSS_BY_ENCOUNTERID[id] == nil, "alternate-mode identity never used for Normal")
end
for _, id in ipairs({240,2805,2810,3055,2795,2796,2797}) do
    check(addon.BOSS_BY_ENCOUNTERID[id] == nil, "unresolved aggregate/alias/strategy remains excluded")
end
for _, id in ipairs({449,450}) do
    check(contains(addon.BOSS_BY_ENCOUNTERID[id].boss.tip, id == 449 and "Curse of Blood" or "Mograine"), "Cathedral tips contain encounter-specific counterplay")
end
local encounterCount = 0
for _ in pairs(addon.BOSS_BY_ENCOUNTERID) do encounterCount = encounterCount + 1 end
check(contains(addon.BOSS_BY_ENCOUNTERID[2780].boss.tip, "Web Spray"), "RFD gives specific counterplay for Tuten'kash")
check(encounterCount == 229, "candidate indexes 229 encounter records")
for id, marker in pairs({[2914] = "Net", [3301] = "Manamorph", [3355] = "Knockout", [3478] = "Shield Slam", [230] = "arena", [243] = "mana", [2791] = "vault", [3409] = "dragon", [3323] = "Clawbert"}) do
    local entry = addon.BOSS_BY_ENCOUNTERID[id]
    check(entry and contains(entry.boss.tip, marker), "current-build encounter has situation-specific advice: " .. id)
end
check(contains(addon.DUNGEON_BY_INSTANCEID[36].overview, "Flamestrike"), "Deadmines overview includes Evoker counterplay")
check(contains(addon.DUNGEON_BY_INSTANCEID[43].overview, "Slumber"), "Wailing Caverns overview includes druid counterplay")
check(contains(addon.DUNGEON_BY_INSTANCEID[47].overview, "Groundshakers"), "Kraul overview includes Groundshaker priority")
check(contains(addon.DUNGEON_BY_INSTANCEID[33].overview, "Lupine Horrors"), "Shadowfang overview includes summoner priority")
check(contains(addon.DUNGEON_BY_INSTANCEID[48].overview, "Mana Burn"), "Blackfathom overview includes mana-burn counterplay")
check(contains(addon.DUNGEON_BY_INSTANCEID[90].overview, "Reflection Field"), "Gnomeregan overview includes reflect counterplay")
check(contains(addon.DUNGEON_BY_INSTANCEID[129].overview, "Belnistrasz"), "Razorfen Downs overview explains escort protection")
check(contains(addon.DUNGEON_BY_INSTANCEID[209].overview, "Mallet"), "Zul'Farrak overview mentions Classic summon preparation")
check(contains(addon.DUNGEON_BY_INSTANCEID[70].overview, "Healing Wave"), "Uldaman prepares players for Oracle healing")
check(contains(addon.DUNGEON_BY_INSTANCEID[189].overview, "Library:"), "Scarlet preparation distinguishes named wings without inferring position")
check(addon.BOSS_BY_ENCOUNTERID[598].boss.tip == addon.BOSS_BY_ENCOUNTERID[599].boss.tip
    and contains(addon.BOSS_BY_ENCOUNTERID[598].boss.tip, "fear"), "either Zul'Farrak paired start shows complete counterplay")
check(contains(addon.DUNGEON_BY_INSTANCEID[209].overview, "Shadowhunter"), "Zul'Farrak overview provides specific trash counterplay")
check(contains(addon.DUNGEON_BY_INSTANCEID[3039].overview, "Shaman"), "Krol'dok overview provides specific trash counterplay")
for _, dungeon in ipairs(addon.DUNGEONS) do
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
check(not addon.bossActive and contains(addon._lastContent, hall.overview)
    and not contains(addon._lastContent, hallSecondBoss.tip),
    "successful Hall boss completion restores overview without guessing the next boss")
KwikTipDB.showInDungeon = false
emit("ENCOUNTER_START", hallFirstBoss.encounterID, "Hall quiet success", 1, 5)
emit("ENCOUNTER_END", hallFirstBoss.encounterID, "Hall quiet success", 1, 5, 1)
check(not addon.bossActive and addon._lastContent == "" and not addon.HUD:IsShown(),
    "successful Hall boss completion is quiet with overview disabled")
KwikTipDB.showInDungeon = true

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
    state.difficultyID = 1 -- helper is independent of previous negative-mode fixture
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
checkUnorderedClassicDungeon(ruins, "Ruins", "RUINS_ALPHA_PERSONAL_NOTE")

checkUnorderedClassicDungeon(excavation, "Excavation", "EXCAVATION_ALPHA_PERSONAL_NOTE")
state.inInstance, state.instanceType, state.instanceID = true, "party", 2998
state.difficultyID = 201
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 3480, "Saltspine", 201, 5)
check(not addon.bossActive and not addon.HUD:IsShown(), "Excavation alternate mode is unsupported")

checkUnorderedClassicDungeon(dalaran, "Dalaran", "DALARAN_ALPHA_PERSONAL_NOTE")
state.inInstance, state.instanceType, state.instanceID = true, "party", 2959
state.difficultyID = 1
emit("PLAYER_ENTERING_WORLD")
for _, id in ipairs({3312}) do
    emit("ENCOUNTER_START", id, "Arcanic Enigma", 1, 5)
    check(not addon.bossActive and not addon.HUD:IsShown(), "unmatched Dalaran ID stays quiet")
end
state.difficultyID = 201
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 3298, "Arcane Anomaly", 201, 5)
check(not addon.bossActive and not addon.HUD:IsShown(), "Dalaran alternate mode excluded")
state.instanceID, state.difficultyID = 2980, 1
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 3298, "Arcane Anomaly", 1, 5)
check(not addon.bossActive and not addon.HUD:IsShown(), "city map cannot activate dungeon advice")

checkUnorderedClassicDungeon(deadmines, "Deadmines", "DEADMINES_NOTE")
checkUnorderedClassicDungeon(caverns, "Caverns", "CAVERNS_NOTE")
for _, dungeon in ipairs({deadmines,caverns}) do
    state.inInstance, state.instanceType, state.instanceID = true, "party", dungeon.instanceID
    for _, mode in ipairs({201,213}) do
        state.difficultyID = mode
        emit("PLAYER_ENTERING_WORLD")
        emit("ENCOUNTER_START", dungeon.bosses[1].encounterID, "Known boss", mode, 5)
        check(not addon.bossActive and not addon.HUD:IsShown(), "Classic alternate mode excluded")
    end
end
state.instanceID, state.difficultyID = 43,1
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 999876, "Deviate Faerie Dragon", 1, 5)
check(not addon.bossActive and not addon.HUD:IsShown(), "unmatched rare name cannot activate tip")

for _, id in ipairs({33,48,90,47,70,230,289,209,349,189,429,329,109,129}) do
    checkUnorderedClassicDungeon(addon.DUNGEON_BY_INSTANCEID[id], "Batch2_" .. id, "BATCH2_NOTE_" .. id)
    state.inInstance, state.instanceType, state.instanceID = true, "party", id
    for _, mode in ipairs({184,198,201,207,215}) do
        state.difficultyID = mode
        emit("PLAYER_ENTERING_WORLD")
        emit("ENCOUNTER_START", addon.DUNGEON_BY_INSTANCEID[id].bosses[1].encounterID, "Known boss", mode, 5)
        check(not addon.bossActive and not addon.HUD:IsShown(), "Batch2 alternate modes excluded")
    end
end
state.instanceID, state.difficultyID = 189,1
emit("PLAYER_ENTERING_WORLD")
for _, name in ipairs({"Scarlet Commander Mograine", "Azshir the Sleepless"}) do
    emit("ENCOUNTER_START", 999876, name, 1, 5)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Scarlet unmatched names cannot activate tips")
end
state.instanceID, state.difficultyID = 109,1
emit("PLAYER_ENTERING_WORLD")
for _, id in ipairs({486,487,488,489,490,491,492,493,2814,2952,2953,2954,2955,2956,2957,2958,2959}) do
    emit("ENCOUNTER_START", id, "Known Temple boss", 1, 5)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Temple alternate and raid identities cannot activate normal tips")
end
state.instanceID, state.difficultyID = 48,1
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 2914, "Gelihast", 1, 5)
check(addon.bossActive and contains(addon._lastContent, "Net"), "Geilhast event displays the sourced Net tip")
emit("ENCOUNTER_END", 2914, "Geilhast", 1, 5, 1)

-- Paired Zul'Farrak events can overlap; either can end first.
state.inInstance, state.instanceType, state.instanceID = true, "party", 209
state.difficultyID, state.mapID, state.subzone = 1, nil, ""
KwikTipDB.showInDungeon = false
for _, ends in ipairs({ {598, 599}, {599, 598} }) do
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", 598, "Pyramid pair A", 1, 5)
    emit("ENCOUNTER_START", 599, "Pyramid pair B", 1, 5)
    emit("ENCOUNTER_END", ends[1], "First pair end", 1, 5, 1)
    check(addon.bossActive and addon.HUD:IsShown(),
        "ending either overlapping paired encounter preserves the other tip")
    emit("ENCOUNTER_END", ends[2], "Second pair end", 1, 5, 1)
    check(not addon.bossActive and not addon.HUD:IsShown(),
        "ending the final paired encounter clears the HUD")
end

-- Reverse start order, duplicate starts, mismatched ends and wipe cleanup.
for _, starts in ipairs({ {598, 599}, {599, 598} }) do
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", starts[1], "Pair first", 1, 5)
    emit("ENCOUNTER_START", starts[2], "Pair second", 1, 5)
    emit("ENCOUNTER_START", starts[2], "Pair duplicate", 1, 5)
    emit("ENCOUNTER_END", 987654, "Unrelated end", 1, 5, 0)
    check(addon.bossActive and addon.HUD:IsShown(), "unrelated end cannot clear pair")
    emit("ENCOUNTER_END", starts[2], "Pair wipe first", 1, 5, 0)
    check(addon.bossActive and addon._activeEncounterID == starts[1]
        and contains(addon._lastContent, "fear"), "wipe of displayed pair member restores remaining member")
    emit("ENCOUNTER_END", starts[2], "Duplicate end", 1, 5, 0)
    check(addon.bossActive, "duplicate end cannot clear remaining pair member")
    emit("ENCOUNTER_END", starts[1], "Pair wipe last", 1, 5, 0)
    check(not addon.bossActive and not addon.HUD:IsShown(), "final pair wipe clears HUD")
end

emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 598, "Pair before unknown", 1, 5)
emit("ENCOUNTER_START", 599, "Pair before unknown", 1, 5)
emit("ENCOUNTER_START", 987655, "Unknown encounter", 1, 5)
check(not addon.bossActive, "unknown start invalidates pair")
emit("ENCOUNTER_END", 598, "Stale pair end", 1, 5, 1)
check(not addon.bossActive, "stale pair end does not revive pair after unknown")
emit("ENCOUNTER_END", 987655, "Unknown encounter", 1, 5, 0)

emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 598, "Pair before mode change", 1, 5)
emit("ENCOUNTER_START", 599, "Pair before mode change", 1, 5)
state.difficultyID = 201
emit("ENCOUNTER_END", 598, "End after mode changed", 1, 5, 0)
check(not addon.bossActive and not addon.HUD:IsShown(), "end after mode change clears pair immediately")
state.difficultyID = 1
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 598, "Pair before zone exit", 1, 5)
emit("ENCOUNTER_START", 599, "Pair before zone exit", 1, 5)
state.instanceID = 389
emit("ZONE_CHANGED_NEW_AREA")
check(not addon.bossActive, "zone exit clears pair")
state.instanceID = 209
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 598, "New solo pull", 1, 5)
emit("ENCOUNTER_END", 598, "Solo pull end", 1, 5, 1)
check(not addon.bossActive, "zone exit removed old pair members before solo pull")

-- Real excluded Ruins IDs must never borrow a similar guide/name entry.
state.inInstance, state.instanceType, state.instanceID = true, "party", 2999
state.difficultyID, state.mapID, state.subzone = 1, nil, ""
for _, showOverview in ipairs({ false, true }) do
    KwikTipDB.showInDungeon = showOverview
    emit("PLAYER_ENTERING_WORLD")
    for _, excludedID in ipairs({ 3408 }) do
        emit("ENCOUNTER_START", excludedID, "The Baron", 1, 5)
        check(not addon.bossActive and addon._activeBossEntry == nil,
            "excluded Ruins IDs cannot activate guide-name fallback")
        if showOverview then
            check(contains(addon._lastContent, ruins.overview), "excluded Ruins fight leaves overview only")
        else
            check(addon._lastContent == "" and not addon.HUD:IsShown(), "excluded Ruins fight stays quiet")
        end
    end
end
KwikTipDB.showInDungeon = false
state.difficultyID = 201
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 3353, "Witherfang", 201, 5)
check(not addon.bossActive and not addon.HUD:IsShown(), "Ruins alternate mode is unsupported")
state.difficultyID = 1
emit("PLAYER_ENTERING_WORLD")
emit("ENCOUNTER_START", 3353, "Witherfang", 1, 5)
emit("ENCOUNTER_END", 3353, "Witherfang", 1, 5, 0)
check(not addon.bossActive and not addon.HUD:IsShown(), "Ruins wipe clears active tip without route guess")

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

-- Lower Blackrock Spire shares map 229 with Upper; never infer a current wing.
local lower = addon.DUNGEON_BY_INSTANCEID[229]
check(lower ~= nil and #lower.bosses == 14, "Blackrock Spire includes fourteen positive event identities")
for i, id in ipairs({267,268,269,270,271,272,274,273,275}) do
    check(lower.bosses[i].encounterID == id, "Lower encounter matches positive 70888 row")
    check(#lower.bosses[i].tip > 20, "Lower Spire provides an actionable tip")
end
check(lower.bosses[7].name == "Halycon", "preserve exact client spelling rather than guessing an alias")
check(lower.uiMapID == nil and lower.areas == nil, "Lower has no guessed wing or NPC routing")
checkUnorderedClassicDungeon(lower, "Lower Blackrock Spire", "LOWER_SPIRE_NOTE")
state.inInstance, state.instanceType, state.instanceID = true, "party", 229
state.difficultyID, state.mapID, state.subzone = 1, nil, ""
for _, showOverview in ipairs({ false, true }) do
    KwikTipDB.showInDungeon = showOverview
    emit("PLAYER_ENTERING_WORLD")
    for _, excluded in ipairs({994201}) do
        check(addon.BOSS_BY_ENCOUNTERID[excluded] == nil, "Synthetic rare ID is not admitted")
        emit("ENCOUNTER_START", 267, "Omokk before unsupported fight", 1, 10)
        emit("ENCOUNTER_START", excluded, "Highlord Omokk", 1, 10)
        check(not addon.bossActive and addon._activeBossEntry == nil, "Upper/rare event clears stale Lower tip despite familiar name")
        check(showOverview and contains(addon._lastContent, lower.overview)
            or not showOverview and addon._lastContent == "" and not addon.HUD:IsShown(),
            "unsupported shared-map event preserves only the shared overview")
    end
end
KwikTipDB.showInDungeon = false
for _, boss in ipairs(lower.bosses) do
    for _, mode in ipairs({201,207}) do
        state.instanceID, state.difficultyID = 229, mode
        emit("PLAYER_ENTERING_WORLD")
        emit("ENCOUNTER_START", boss.encounterID, boss.name, mode, 10)
        check(not addon.bossActive and not addon.HUD:IsShown(), "Lower alternate modes stay disabled")
    end
    state.instanceID, state.difficultyID = 230, 1
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", boss.encounterID, boss.name, 1, 10)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Lower events cannot leak into Blackrock Depths")
    state.instanceID = 229
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", boss.encounterID, "Localized Lower encounter", 1, 10)
    check(addon.bossActive and contains(addon._lastContent, boss.tip), "normal ten-player event keeps provisional tip")
    check(contains(addon._lastContent, "Localized Lower encounter"), "Lower header uses localized event name")
    emit("ENCOUNTER_END", boss.encounterID, boss.name, 1, 10, 0)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Lower wipe clears tip without predicting route")
end
state.inInstance, state.instanceType, state.instanceID = false, "none", 0
emit("PLAYER_ENTERING_WORLD")

-- Synthetic packaged-path events do not establish target-client event semantics.
for _, slice in ipairs({
    {229, {3062,3063,3068,3069,3070}, {{994210,"Solakar Flamewreath"},{994211,"Goraluk Anvilcrack"},{994212,"Jed Runewatcher"}}},
    {2994, {3410,3403,3418,3409,3415}, {}},
    {2974, {3315,3322,3316,3323,3336,3327,3334}, {{994213,"Moontouched Wanderer"}}},
    {3001, {3503,3498,3597,3507,3500,3501,3505,3502}, {{3499,"Tor'Rel and Izha'Rel"},{3504,"King Op"},{3600,"Vitrix"}}},
}) do
    local map, ids, excluded = slice[1], slice[2], slice[3]
    local dungeon = addon.DUNGEON_BY_INSTANCEID[map]
    check(dungeon ~= nil and dungeon.previewNextBoss == false, "candidate map suppresses guessed boss order")
    for _, showOverview in ipairs({false, true}) do
        KwikTipDB.showInDungeon = showOverview
        state.inInstance, state.instanceType, state.instanceID, state.difficultyID = true, "party", map, 1
        emit("PLAYER_ENTERING_WORLD")
        check(showOverview and contains(addon._lastContent, dungeon.overview)
            or not showOverview and addon._lastContent == "" and not addon.HUD:IsShown(),
            "candidate entry shows only opt-in overview")
        for _, id in ipairs(ids) do
            local boss = addon.BOSS_BY_ENCOUNTERID[id].boss
            for _, size in ipairs({5,10}) do
                emit("ENCOUNTER_START", id, "Localized event", 1, size)
                check(addon.bossActive and contains(addon._lastContent, boss.tip), "admitted event shows its tip")
                emit("ENCOUNTER_END", id, boss.name, 1, size, 0)
                check(not addon.bossActive, "wipe clears event")
            end
            emit("ENCOUNTER_START", id, boss.name, 1, 5)
            emit("ENCOUNTER_END", id, boss.name, 1, 5, 1)
            check(not addon.bossActive, "success clears event without guessed next boss")
            check(showOverview and contains(addon._lastContent, dungeon.overview)
                or not showOverview and addon._lastContent == "" and not addon.HUD:IsShown(),
                "success returns to overview or quiet state")
        end
        for _, unknown in ipairs(excluded) do
            emit("ENCOUNTER_START", ids[1], "prior fight", 1, 5)
            emit("ENCOUNTER_START", unknown[1], unknown[2], 1, 5)
            check(not addon.bossActive and addon._activeBossEntry == nil, "excluded name cannot inherit prior tip")
            check(showOverview and contains(addon._lastContent, dungeon.overview)
                or not showOverview and addon._lastContent == "" and not addon.HUD:IsShown(),
                "excluded event returns to overview or quiet state")
        end
        emit("ENCOUNTER_START", ids[1], "prior fight", 1, 5)
        emit("ENCOUNTER_START", 999999, "Unknown encounter", 1, 5)
        check(not addon.bossActive and addon._activeBossEntry == nil, "unknown event clears prior fight")
        for _, mode in ipairs({201,207}) do
            state.difficultyID = mode
            emit("PLAYER_ENTERING_WORLD")
            emit("ENCOUNTER_START", ids[1], "unsupported mode", mode, 5)
            check(not addon.bossActive and not addon.HUD:IsShown(), "unsupported difficulty stays quiet")
        end
        state.difficultyID, state.instanceID = 1, 230
        emit("PLAYER_ENTERING_WORLD")
        emit("ENCOUNTER_START", ids[1], "foreign event", 1, 5)
        check(not addon.bossActive, "foreign instance cannot display tip")
        state.instanceID = map
        emit("PLAYER_ENTERING_WORLD")
        emit("ENCOUNTER_START", ids[1], "prior fight", 1, 5)
        state.inInstance, state.instanceType, state.instanceID = false, "none", 0
        emit("PLAYER_ENTERING_WORLD")
        check(not addon.bossActive and not addon.HUD:IsShown(), "zone exit clears event")
    end
end
KwikTipDB.showInDungeon = false

-- Krol'dok incorporates live-observed event identities and reconciled guide names.
local kroldok = addon.DUNGEON_BY_INSTANCEID[3039]
check(kroldok ~= nil, "Krol'dok candidate is indexed by its 70959 instance ID")
if kroldok then
    check(#kroldok.bosses == 5, "Krol'dok includes five observed encounter identities")
    local ids = { 3450, 3452, 3453, 3449, 3451 }
    for i, id in ipairs(ids) do
        check(kroldok.bosses[i].encounterID == id, "Krol'dok uses a positively identified encounter")
    end
    check(kroldok.uiMapID == nil and kroldok.areas == nil, "Krol'dok does not guess area routing")
    checkUnorderedClassicDungeon(kroldok, "Krol'dok", "KROLDOK_NOTE")
    state.inInstance, state.instanceType, state.instanceID = true, "party", 3039
    state.difficultyID, state.mapID, state.subzone = 1, nil, ""
    for _, showOverview in ipairs({ false, true }) do
        KwikTipDB.showInDungeon = showOverview
        emit("PLAYER_ENTERING_WORLD")
        for _, excluded in ipairs({{994301, "Bossman Toof"}}) do
            emit("ENCOUNTER_START", 3450, "Grox", 1, 5)
            emit("ENCOUNTER_START", excluded[1], excluded[2], 1, 5)
            check(not addon.bossActive and addon._activeBossEntry == nil, "unreconciled or unknown Krol'dok boss clears previous tip")
            check(showOverview and contains(addon._lastContent, kroldok.overview)
                or not showOverview and addon._lastContent == "" and not addon.HUD:IsShown(),
                "excluded Krol'dok encounter preserves only the optional overview")
        end
    end
    KwikTipDB.showInDungeon = false
    state.difficultyID = 1
    emit("PLAYER_ENTERING_WORLD")
    for _, boss in ipairs(kroldok.bosses) do
        emit("ENCOUNTER_START", boss.encounterID, "Localized encounter", 1, 5)
        check(addon.bossActive and contains(addon._lastContent, boss.tip), "Krol'dok simulated five-player event displays the tip")
        emit("ENCOUNTER_END", boss.encounterID, "Localized encounter", 1, 5, 0)
        check(not addon.bossActive and not addon.HUD:IsShown(), "Krol'dok five-player wipe returns to quiet")
    end
    state.difficultyID = 201
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", 3450, "Slavecrusher Grox", 201, 5)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Krol'dok alternate difficulty stays unsupported")
    state.inInstance, state.instanceType, state.instanceID = false, "none", 0
    emit("PLAYER_ENTERING_WORLD")
end

-- Drowned City is admitted from exact-build readable DB2 sections only.
local drowned = addon.DUNGEON_BY_INSTANCEID[2970]
check(drowned ~= nil and #drowned.bosses == 6, "Drowned City includes Guardian-only counterplay")
for i, id in ipairs({3474,3475,3476,3511,3478,3479}) do
    check(drowned.bosses[i].encounterID == id, "Drowned City encounter matches verified 70888 row")
end
check(drowned.uiMapID == nil and drowned.areas == nil, "Drowned City has no guessed map or area routing")
check(not contains(addon.BOSS_BY_ENCOUNTERID[3478].boss.tip, "Marrow") and not contains(addon.BOSS_BY_ENCOUNTERID[3478].boss.tip, "Bloodbolt"), "Deathless Guardians does not borrow Marrow advice")
checkUnorderedClassicDungeon(drowned, "Drowned City", "DROWNED_CITY_NOTE")
state.inInstance, state.instanceType, state.instanceID = true, "party", 2970
state.difficultyID, state.mapID, state.subzone = 1, nil, ""
for _, showOverview in ipairs({ false, true }) do
    KwikTipDB.showInDungeon = showOverview
    emit("PLAYER_ENTERING_WORLD")
    for _, excluded in ipairs({{994101,"Umbra"},{994102,"Gill"},{994103,"Zin'aka"}}) do
        emit("ENCOUNTER_START", excluded[1], excluded[2], 1, 5)
        check(not addon.bossActive and addon._activeBossEntry == nil, "Drowned City exclusions cannot create name-based tips")
        check(showOverview and contains(addon._lastContent, drowned.overview)
            or not showOverview and addon._lastContent == "" and not addon.HUD:IsShown(),
            "excluded Drowned City events preserve only the opted-in overview")
    end
end
KwikTipDB.showInDungeon = false
for _, boss in ipairs(drowned.bosses) do
    state.instanceID, state.difficultyID = 2970, 201
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", boss.encounterID, boss.name, 201, 5)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Drowned City alternate difficulty stays disabled")
    state.instanceID, state.difficultyID = 3065, 1
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", boss.encounterID, boss.name, 1, 5)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Drowned City events cannot leak into another dungeon")
    state.instanceID = 2970
    emit("PLAYER_ENTERING_WORLD")
    emit("ENCOUNTER_START", boss.encounterID, boss.name, 1, 5)
    emit("ENCOUNTER_END", boss.encounterID, boss.name, 1, 5, 0)
    check(not addon.bossActive and not addon.HUD:IsShown(), "Drowned City wipe clears the active tip")
end
state.inInstance, state.instanceType, state.instanceID = false, "none", 0
emit("PLAYER_ENTERING_WORLD")

-- ============================================================
-- Forever-only manual boss tip preview (pre-pull, out of combat)
-- ============================================================
local chatLines = {}
local origPrint = print
local function captureSlash(cmd)
    chatLines = {}
    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        chatLines[#chatLines + 1] = table.concat(parts, "\t")
    end
    local okCall, errCall = pcall(SlashCmdList.KWIKTIP, cmd)
    print = origPrint
    assert(okCall, errCall)
    return table.concat(chatLines, "\n")
end

-- 1. Unsupported instances/modes keep picker unavailable with clear message.
check(addon.IS_FOREVER == true, "Forever runtime sets IS_FOREVER flavor flag")
KwikTipDB.showInDungeon = false
KwikTipDB.persistentHide = false
state.inInstance, state.instanceType, state.instanceID, state.difficultyID = false, "none", 0, 1
emit("PLAYER_ENTERING_WORLD")
local dUnsupported, reasonUnsupported = addon:GetBossPreviewDungeon()
check(dUnsupported == nil and contains(reasonUnsupported, "Unavailable:"),
    "boss preview is unavailable outside an instance with clear reason")
local okOutside = addon:PreviewBoss(1)
check(not okOutside and addon._manualBossPreview == nil and not addon.HUD:IsShown(),
    "PreviewBoss fails closed outside an instance")
check(contains(captureSlash("boss"), "Unavailable:"), "/kwik boss reports unavailable outside instance")
check(contains(captureSlash("boss 1"), "Unavailable:") and not addon.HUD:IsShown(),
    "/kwik boss 1 fails closed outside instance")

addon:ToggleConfig()
check(addon.Config:IsShown() and addon._bossPreviewUI ~= nil, "config initializes Forever boss preview picker")
check(addon._bossPreviewUI.dropBtn:GetText() == "Unavailable"
    and contains(addon._bossPreviewUI.hintText:GetText(), "Unavailable:"),
    "config picker shows unavailable state outside an instance")
addon._bossPreviewUI.dropBtn:GetScript("OnClick")(addon._bossPreviewUI.dropBtn)
check(not addon._bossPreviewUI.dropList:IsShown(), "unavailable picker does not open dropdown")
addon:ToggleConfig()

for _, unsupportedCase in ipairs({
    { inInst = true, instType = "raid", instID = 389, diff = 1, label = "raid mode" },
    { inInst = true, instType = "party", instID = 990001, diff = 1, label = "unknown party instance" },
    { inInst = true, instType = "party", instID = 389, diff = 201, label = "unsupported difficulty 201" },
    { inInst = true, instType = "party", instID = 389, diff = 0, label = "zero difficulty" },
    { inInst = true, instType = "party", instID = 389, diff = nil, label = "nil difficulty" },
}) do
    state.inInstance, state.instanceType = unsupportedCase.inInst, unsupportedCase.instType
    state.instanceID, state.difficultyID = unsupportedCase.instID, unsupportedCase.diff
    emit("PLAYER_ENTERING_WORLD")
    local dCase, rCase = addon:GetBossPreviewDungeon()
    check(dCase == nil and contains(rCase, "Unavailable:"),
        "boss preview unavailable in " .. unsupportedCase.label)
    check(not addon:PreviewBoss(1) and not addon.HUD:IsShown(),
        "PreviewBoss refuses " .. unsupportedCase.label)
end

-- An absent difficulty allowlist must not admit an unverified mode.
state.inInstance, state.instanceType, state.instanceID, state.difficultyID = true, "party", 389, 201
local savedDifficultyIDs = ragefire.difficultyIDs
ragefire.difficultyIDs = nil
check(not addon:PreviewBoss(1), "missing difficulty allowlist fails closed")
ragefire.difficultyIDs = savedDifficultyIDs

-- 2. Supported instance with Persistent Tip Window (showInDungeon) OFF.
state.inInstance, state.instanceType, state.instanceID, state.difficultyID = true, "party", 389, 1
state.instanceName, state.subzone = "Localized Ragefire Chasm", ""
KwikTipDB.showInDungeon = false
KwikTipDB.persistentHide = false
emit("PLAYER_ENTERING_WORLD")
check(addon._lastContent == "" and not addon.HUD:IsShown(),
    "Ragefire starts hidden with Persistent Tip Window OFF")

addon:ToggleConfig()
local ui = addon._bossPreviewUI
check(contains(ui.hintText:GetText(), "list, not pull order"),
    "config picker explicitly labels bosses as a list, not pull order")
check(contains(ui.listHeader:GetText(), "list, not pull order"),
    "dropdown header explicitly labels bosses as a list, not pull order")
ui.dropBtn:GetScript("OnClick")(ui.dropBtn)
check(ui.dropList:IsShown(), "clicking picker opens boss dropdown in supported instance")
for i, boss in ipairs(ragefire.bosses) do
    check(ui.rows[i]:IsShown() and ui.rows[i]._boss == boss and ui.rows[i]._lbl:GetText() == boss.name,
        "picker lists Ragefire boss " .. i .. " in exact data order")
end
-- A prior unknown encounter must not supply the preview's displayed boss name.
emit("ENCOUNTER_START", 994999, "Unrelated Unknown Encounter", 1, 5)
check(not addon.bossActive, "unknown encounter does not start a supported fight")
-- Pick Taragaman the Hungerer (index 2) from the UI list.
ui.rows[2]:GetScript("OnClick")(ui.rows[2])
check(not ui.dropList:IsShown(), "selecting a boss closes the dropdown")
check(addon._manualBossPreview and addon._manualBossPreview.boss == ragefire.bosses[2],
    "selecting a boss sets manual boss preview state")
check(addon.HUD:IsShown() and contains(addon._lastContent, ragefire.bosses[2].name)
    and contains(addon._lastContent, ragefire.bosses[2].tip),
    "manual boss preview displays existing boss tip even with Persistent Tip Window OFF")
-- Closing Config keeps the manual boss preview up so the player can read it before pulling.
addon:ToggleConfig()
check(not addon.Config:IsShown() and addon.HUD:IsShown()
    and contains(addon._lastContent, ragefire.bosses[2].tip),
    "closing config preserves manual boss preview until pull/combat/zone exit/clear")

-- Walking between subzones inside the same dungeon keeps the preview visible.
state.subzone = "The Burning Vaults"
emit("ZONE_CHANGED")
check(addon.HUD:IsShown() and contains(addon._lastContent, ragefire.bosses[2].tip),
    "subzone change inside the same supported dungeon preserves manual boss preview")

-- Clear button dismisses preview and hides HUD when Persistent Tip Window is OFF.
addon:ToggleConfig()
ui.clearBtn:GetScript("OnClick")(ui.clearBtn)
check(addon._manualBossPreview == nil and addon._lastContent == "" and not addon.HUD:IsShown(),
    "Clear button removes manual boss preview and hides HUD when Persistent Tip Window is OFF")
addon:ToggleConfig()

-- 3. /kwik boss slash command (list, index, partial name, ambiguity, clear, help).
local listOutput = captureSlash("boss")
check(contains(listOutput, "list, not pull order") and contains(listOutput, "[1] Oggleflint")
    and contains(listOutput, "[4] Bazzalan"),
    "/kwik boss prints current dungeon bosses as a list, not pull order")
local pickIdxOut = captureSlash("boss 3")
check(contains(pickIdxOut, "Jergosh the Invoker") and addon.HUD:IsShown()
    and contains(addon._lastContent, ragefire.bosses[3].tip),
    "/kwik boss 3 previews third boss tip with Persistent Tip Window OFF")
local pickNameOut = captureSlash("boss bazz")
check(contains(pickNameOut, "Bazzalan") and addon.HUD:IsShown()
    and contains(addon._lastContent, ragefire.bosses[4].tip),
    "/kwik boss <partial name> previews matching boss tip")
local clearOut = captureSlash("boss clear")
check(contains(clearOut, "cleared") and addon._manualBossPreview == nil
    and addon._lastContent == "" and not addon.HUD:IsShown(),
    "/kwik boss clear dismisses preview and hides HUD")
check(contains(captureSlash("help"), "/kwik boss"), "/kwik help documents /kwik boss")

-- Ambiguous match in Lower Blackrock Spire ("lord" matches Highlord Omokk and Overlord Wyrmthalak).
state.instanceID = 229
emit("PLAYER_ENTERING_WORLD")
local ambigOut = captureSlash("boss lord")
check(contains(ambigOut, "Multiple bosses match") and addon._manualBossPreview == nil
    and not addon.HUD:IsShown(),
    "/kwik boss refuses to guess on ambiguous boss names")

-- 4. Persistent Tip Window ON restores overview + personal note when cleared.
state.instanceID, state.subzone = 389, ""
KwikTipDB.showInDungeon = true
KwikTipDB.notes["389"] = "RAGEFIRE_PREVIEW_NOTE"
emit("PLAYER_ENTERING_WORLD")
check(contains(addon._lastContent, ragefire.overview), "overview renders with Persistent Tip Window ON")
captureSlash("boss 1")
check(contains(addon._lastContent, ragefire.bosses[1].tip)
    and not contains(addon._lastContent, ragefire.overview),
    "manual boss preview replaces overview while active")
check(contains(addon._lastContent, "RAGEFIRE_PREVIEW_NOTE"),
    "manual boss preview includes the existing personal note")
do
    local edit, save
    for _, frame in ipairs(frames) do
        if frame.kind == "EditBox" and frame.parent and frame.parent.parent == KwikTipNotePopup then
            edit = frame
        elseif frame.kind == "Button" and frame.parent == KwikTipNotePopup
            and frame:GetText() == addon.L.BTN_NOTE_SAVE then
            save = frame
        end
    end
    check(edit ~= nil and save ~= nil, "note editor and save button exist")
    addon.NoteBtn:GetScript("OnClick")(addon.NoteBtn)
    edit:SetText("EDITED_PREVIEW_NOTE")
    save:GetScript("OnClick")(save)
    check(KwikTipDB.notes["389"] == "EDITED_PREVIEW_NOTE"
        and contains(addon._lastContent, "EDITED_PREVIEW_NOTE")
        and not contains(addon._lastContent, "RAGEFIRE_PREVIEW_NOTE"),
        "saving a note through the UI refreshes the active boss preview")
end
captureSlash("boss clear")
check(contains(addon._lastContent, ragefire.overview)
    and contains(addon._lastContent, "EDITED_PREVIEW_NOTE"),
    "clearing manual preview restores overview and saved personal note")
KwikTipDB.notes["389"] = nil
KwikTipDB.showInDungeon = false
emit("PLAYER_ENTERING_WORLD")

-- 5. Disable Tips (persistentHide) hides HUD even when preview is selected.
KwikTipDB.persistentHide = true
captureSlash("boss 1")
check(addon._manualBossPreview ~= nil and not addon.HUD:IsShown(),
    "Disable Tips keeps HUD hidden while manual preview is selected")
KwikTipDB.persistentHide = false
addon:UpdateVisibility()
check(addon.HUD:IsShown() and contains(addon._lastContent, ragefire.bosses[1].tip),
    "unchecking Disable Tips reveals the active manual boss preview")
addon:ClearBossPreview()

-- 6. Combat lockdown / combat state blocks picking; leaving combat clears preview.
local prevInCombatLockdown = InCombatLockdown
InCombatLockdown = function() return true end
local okCombat, errCombat = addon:PreviewBoss(1)
check(not okCombat and contains(errCombat, "combat") and addon._manualBossPreview == nil
    and not addon.HUD:IsShown(),
    "InCombatLockdown blocks PreviewBoss")
check(contains(captureSlash("boss 1"), "combat") and addon._manualBossPreview == nil,
    "InCombatLockdown blocks /kwik boss pick")
addon:ToggleConfig()
check(ui.dropBtn:GetText() == "In combat" and contains(ui.statusText:GetText(), "combat"),
    "config picker reflects combat lockdown state")
ui.dropBtn:GetScript("OnClick")(ui.dropBtn)
check(not ui.dropList:IsShown(), "dropdown cannot open during combat lockdown")
addon:ToggleConfig()
InCombatLockdown = prevInCombatLockdown

-- Start preview out of combat, open dropdown, then enter and leave combat without encounter.
addon:ToggleConfig()
ui.dropBtn:GetScript("OnClick")(ui.dropBtn)
check(ui.dropList:IsShown(), "dropdown opens out of combat")
emit("PLAYER_REGEN_DISABLED")
check(not ui.dropList:IsShown() and ui.dropBtn:GetText() == "In combat",
    "entering combat closes boss dropdown and disables picking")
addon:ToggleConfig()
check(not addon:PreviewBoss(2), "PLAYER_REGEN_DISABLED blocks picking even if InCombatLockdown stub is false")
emit("PLAYER_REGEN_ENABLED")
check(addon:PreviewBoss(2) and addon.HUD:IsShown(), "out-of-combat picking succeeds after PLAYER_REGEN_ENABLED")
emit("PLAYER_REGEN_DISABLED")
check(addon._manualBossPreview == nil and addon._lastContent == "" and not addon.HUD:IsShown(),
    "entering combat clears manual preview immediately without a stale tip")
emit("PLAYER_REGEN_ENABLED")
check(addon._manualBossPreview == nil and addon._lastContent == "" and not addon.HUD:IsShown(),
    "leaving combat clears manual boss preview and leaves no stale tip")

-- 7. Real ENCOUNTER_START overrides manual preview; ENCOUNTER_END clears without stale tip.
for _, showOverview in ipairs({ false, true }) do
    KwikTipDB.showInDungeon = showOverview
    emit("PLAYER_ENTERING_WORLD")
    addon:PreviewBoss(2) -- Taragaman
    check(contains(addon._lastContent, ragefire.bosses[2].tip), "pre-pull preview active before pull")
    emit("PLAYER_REGEN_DISABLED")
    check(addon._manualBossPreview == nil and not contains(addon._lastContent, ragefire.bosses[2].tip),
        "combat start clears the pre-pull tip before encounter start")
    emit("ENCOUNTER_START", ragefire.bosses[1].encounterID, "Oggleflint Live", 1, 5)
    check(addon._manualBossPreview == nil and addon.bossActive
        and contains(addon._lastContent, ragefire.bosses[1].tip)
        and not contains(addon._lastContent, ragefire.bosses[2].tip),
        "real ENCOUNTER_START overrides and clears manual boss preview")
    emit("ENCOUNTER_END", ragefire.bosses[1].encounterID, "Oggleflint Live", 1, 5, 1)
    emit("PLAYER_REGEN_ENABLED")
    check(addon._manualBossPreview == nil and not addon.bossActive
        and not contains(addon._lastContent, ragefire.bosses[2].tip),
        "ENCOUNTER_END does not fall back to stale manual preview")
    if showOverview then
        check(contains(addon._lastContent, ragefire.overview), "ENCOUNTER_END returns to overview when enabled")
    else
        check(addon._lastContent == "" and not addon.HUD:IsShown(), "ENCOUNTER_END hides HUD when overview is off")
    end
end

-- Also cover ENCOUNTER_START arriving before the combat event.
KwikTipDB.showInDungeon = false
emit("PLAYER_ENTERING_WORLD")
check(addon:PreviewBoss(2), "preview can be selected before direct encounter start")
emit("ENCOUNTER_START", ragefire.bosses[1].encounterID, "Oggleflint Live", 1, 5)
check(addon._manualBossPreview == nil and addon.bossActive
    and contains(addon._lastContent, ragefire.bosses[1].tip)
    and not contains(addon._lastContent, ragefire.bosses[2].tip),
    "direct encounter start overrides a still-active manual preview")
emit("ENCOUNTER_END", ragefire.bosses[1].encounterID, "Oggleflint Live", 1, 5, 1)

-- Unrecognized ENCOUNTER_START also clears an active manual preview instead of leaving stale tip.
KwikTipDB.showInDungeon = false
emit("PLAYER_ENTERING_WORLD")
addon:PreviewBoss(2)
emit("ENCOUNTER_START", 994999, "Unknown Rare", 1, 5)
check(addon._manualBossPreview == nil and not addon.bossActive
    and addon._lastContent == "" and not addon.HUD:IsShown(),
    "unrecognized ENCOUNTER_START clears manual preview instead of leaving stale tip")
emit("ENCOUNTER_END", 994999, "Unknown Rare", 1, 5, 0)
check(addon._manualBossPreview == nil and addon._lastContent == "" and not addon.HUD:IsShown(),
    "ENCOUNTER_END after unrecognized encounter leaves no stale tip")

-- 8. Leaving instance/zone clears manual preview (PLAYER_ENTERING_WORLD, ZONE_CHANGED_NEW_AREA, ZONE_CHANGED).
addon:PreviewBoss(2)
state.inInstance, state.instanceType, state.instanceID = false, "none", 0
emit("PLAYER_ENTERING_WORLD")
check(addon._manualBossPreview == nil and addon._lastContent == "" and not addon.HUD:IsShown(),
    "leaving instance via PLAYER_ENTERING_WORLD clears manual preview")

state.inInstance, state.instanceType, state.instanceID = true, "party", 389
emit("PLAYER_ENTERING_WORLD")
addon:PreviewBoss(2)
state.inInstance, state.instanceType, state.instanceID = false, "none", 0
emit("ZONE_CHANGED_NEW_AREA")
check(addon._manualBossPreview == nil and addon._lastContent == "" and not addon.HUD:IsShown(),
    "leaving instance via ZONE_CHANGED_NEW_AREA clears manual preview")

state.inInstance, state.instanceType, state.instanceID = true, "party", 389
emit("PLAYER_ENTERING_WORLD")
addon:PreviewBoss(2)
state.instanceID = 34 -- changed instance without loading screen
emit("ZONE_CHANGED")
check(addon._manualBossPreview == nil and addon._lastContent == "" and not addon.HUD:IsShown(),
    "instance change via ZONE_CHANGED clears manual preview without stale tip")

KwikTipDB.showInDungeon = false
state.inInstance, state.instanceType, state.instanceID, state.difficultyID = false, "none", 0, 1
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
    difficultyIDs = { 1 },
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
