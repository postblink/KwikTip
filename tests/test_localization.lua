-- Run from any working directory with: lua5.1 tests/test_localization.lua
-- This suite loads the shipped locale files and Core.lua. Runtime assertions
-- enter through KwikTip's production methods; fallback and subzone logic are
-- intentionally not reimplemented here.

local PASS, FAIL = 0, 0

local function ok(condition, message)
    if condition then
        PASS = PASS + 1
        io.write("  PASS  ", message, "\n")
    else
        FAIL = FAIL + 1
        io.write("  FAIL  ", message, "\n")
    end
end

local function contains(value, expected)
    return value and value:find(expected, 1, true) ~= nil
end

local source = debug.getinfo(1, "S").source
local testFile = source:sub(1, 1) == "@" and source:sub(2) or source
local testDir = testFile:match("^(.*[/\\])") or "./"
local repoDir = testDir .. ".."

local function repoPath(relative)
    return repoDir .. "/" .. relative
end

local function loadAddonFile(relative, addon)
    local chunk, err = loadfile(repoPath(relative))
    assert(chunk, err)
    return chunk("KwikTip", addon)
end

local function newRuntime(locale)
    local state = {
        locale = locale,
        role = "HEALER",
        instanceName = "Localized Dungeon",
        instanceType = "party",
        difficultyID = 10,
        instanceID = 9001,
        mapID = 7001,
        subzone = "",
        inInstance = true,
    }
    local printed = {}

    UIParent = {}
    SlashCmdList = {}
    C_Timer = { After = function(_, callback) callback() end }
    C_Map = {
        GetBestMapForUnit = function() return state.mapID end,
        GetPlayerMapPosition = function() return nil end,
    }
    C_ChallengeMode = nil
    GetLocale = function() return state.locale end
    UnitGroupRolesAssigned = function() return state.role end
    IsInInstance = function() return state.inInstance, state.instanceType end
    GetSubZoneText = function() return state.subzone end
    GetInstanceInfo = function()
        return state.instanceName, state.instanceType, state.difficultyID,
            "Difficulty", 5, 0, false, state.instanceID
    end
    UnitCanAttack = function() return false end
    UnitIsPlayer = function() return false end
    date = function() return "test-time" end
    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        table.insert(printed, table.concat(parts, "\t"))
    end
    CreateFrame = function()
        return {
            RegisterEvent = function() end,
            UnregisterEvent = function() end,
            SetScript = function() end,
        }
    end

    local addon = {
        DEFAULTS = {},
        DUNGEON_BY_INSTANCEID = {},
        DUNGEON_BY_UIMAPID = {},
        BOSS_BY_ENCOUNTERID = {},
    }
    loadAddonFile("Locale/enUS.lua", addon)
    loadAddonFile("Locale/Locales.lua", addon)
    loadAddonFile("Locale/deDE.lua", addon)
    loadAddonFile("Locale/tips_enUS.lua", addon)
    loadAddonFile("Locale/tips_deDE.lua", addon)

    function addon:SetContent(content) self.captured = content end
    function addon:UpdateVisibility() end
    function addon:InitHUD() end

    KwikTipDB = {
        showInDungeon = true,
        delves = true,
        debugLog = false,
        notes = {},
        mapIDLog = {},
        encounterLog = {},
        keystoneLog = {},
        spellLog = {},
        debugSnapshots = {},
    }
    loadAddonFile("Core.lua", addon)
    return addon, state, printed
end

local function resetBossState(addon)
    addon._activeBossEntry = nil
    addon._activeEncounterID = nil
    addon._activeEncounterName = nil
    addon._activeDifficultyID = nil
    addon.bossActive = false
    addon.previewActive = false
    addon.captured = nil
end

local function renderBoss(addon, state, dungeon, boss, difficultyID, encounterName)
    resetBossState(addon)
    addon.BOSS_BY_ENCOUNTERID = {
        [boss.encounterID] = { dungeon = dungeon, boss = boss },
    }
    state.difficultyID = difficultyID
    addon:OnEncounterStart(boss.encounterID, encounterName or boss.name, difficultyID, 5)
    return addon.captured
end

local GOLD, WHITE, GRAY, RESET = "|cffffcc00", "|cffffffff", "|cffbbbbbb", "|r"
local HEAL_ICON = "|TInterface\\Icons\\Spell_Holy_Renew:13:13|t"

io.write("\n--- enUS production runtime ---\n")
local addon, state = newRuntime("enUS")
ok(addon.L.SETTINGS_TITLE == "KwikTip Settings", "deDE guard preserves enUS locale")

state.instanceName = "English Dungeon"
local dungeon = { name = "English Dungeon", mythicPlus = false }
local notesBoss = {
    encounterID = 101,
    name = "English Boss",
    tip = "English flat fallback",
    notes = {
        { role = "general", text = "English general one" },
        { role = "general", text = "English general two" },
        { role = "healer", text = "English healer" },
        { role = "tank", text = "English tank" },
    },
}
dungeon.bosses = { notesBoss }
addon.TIP_OVERRIDE_BY_ENCOUNTERID = {}
local output = renderBoss(addon, state, dungeon, notesBoss, 10)
local expectedNotes = GOLD .. "English Dungeon" .. RESET .. "\n"
    .. WHITE .. "English Boss" .. RESET .. "\n"
    .. GRAY .. "English general one" .. RESET .. "\n"
    .. GRAY .. "English general two" .. RESET .. "\n"
    .. HEAL_ICON .. " |cff33cc33English healer" .. RESET
ok(output == expectedNotes, "enUS notes match pre-localization rendering exactly")

local flatBoss = { encounterID = 102, name = "Flat Boss", tip = "Flat English tip" }
dungeon.bosses = { flatBoss }
local expectedFlat = GOLD .. "English Dungeon" .. RESET .. "\n"
    .. WHITE .. "Flat Boss" .. RESET .. "\n" .. GRAY .. "Flat English tip" .. RESET
ok(renderBoss(addon, state, dungeon, flatBoss, 10) == expectedFlat,
    "enUS flat tip matches pre-localization rendering exactly")

io.write("\n--- production fallback semantics ---\n")
addon.TIP_OVERRIDE_BY_ENCOUNTERID = {
    [101] = { notes = { { role = "general", text = "German general" } } },
}
dungeon.bosses = { notesBoss }
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "German general"), "translated general note is rendered")
ok(contains(output, "English healer"), "missing translated healer falls back to English healer")
ok(not contains(output, "English general one"), "translated general owns the general role")

notesBoss.difficulties = {
    [10] = { notes = { { role = "general", text = "English difficulty general" } } },
}
addon.TIP_OVERRIDE_BY_ENCOUNTERID = {
    [101] = { difficulties = { [10] = { tip = "German difficulty tip" } } },
}
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "German difficulty tip"),
    "translated difficulty flat tip wins over lower-priority English notes")
ok(not contains(output, "English difficulty general"),
    "English difficulty notes do not suppress translated difficulty flat tip")

notesBoss.difficulties = {
    [10] = { notes = {
        { role = "general", text = "English difficulty general" },
        { role = "healer", text = "English difficulty healer" },
    } },
}
addon.TIP_OVERRIDE_BY_ENCOUNTERID = {
    [101] = { difficulties = { [10] = {
        notes = { { role = "general", text = "German difficulty general" } },
    } } },
}
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "German difficulty general"), "translated difficulty general is rendered")
ok(contains(output, "English difficulty healer"),
    "missing translated difficulty healer uses English difficulty healer")
ok(not contains(output, "English difficulty general"),
    "translated difficulty general replaces English difficulty general")

addon.TIP_OVERRIDE_BY_ENCOUNTERID = {
    [101] = { difficulties = { [10] = {
        tip = "German difficulty role fallback tip",
        notes = { { role = "tank", text = "German tank only" } },
    } } },
}
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "German difficulty role fallback tip"),
    "translated flat tip is used when its structured notes do not apply to the player")
ok(not contains(output, "English difficulty healer"),
    "lower-priority English role note does not suppress translated flat tip")

notesBoss.difficulties = nil
addon.TIP_OVERRIDE_BY_ENCOUNTERID = { [101] = { tip = "German base tip" } }
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "German base tip"), "missing translated difficulty falls back to translated base")

addon.TIP_OVERRIDE_BY_ENCOUNTERID = {}
notesBoss.difficulties = {
    [10] = { notes = { { role = "general", text = "English difficulty only" } } },
}
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "English difficulty only"), "missing translations use English difficulty content")
ok(not contains(output, "English general one"), "English difficulty content retains legacy override semantics")

notesBoss.difficulties = { [10] = {} }
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "English general one"), "empty English difficulty falls back to English base")

-- Sparse combinations that previously terminated an ipairs candidate walk.
notesBoss.difficulties = nil
addon.TIP_OVERRIDE_BY_ENCOUNTERID = { [101] = { difficulties = {} } }
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "English general one"), "sparse override table reaches English base")
addon.TIP_OVERRIDE_BY_ENCOUNTERID = nil
output = renderBoss(addon, state, dungeon, notesBoss, 10)
ok(contains(output, "English healer"), "nil override table reaches English base")

state.instanceName = "Lokalisierter Instanzname"
output = renderBoss(addon, state, dungeon, notesBoss, 10, "Localized Encounter")
ok(contains(output, "Lokalisierter Instanzname"),
    "dungeon header uses first GetInstanceInfo return")
ok(not contains(output, "|cffffcc00party"), "instance type is not used as dungeon header")

io.write("\n--- production subzone matching and authored IDs ---\n")
local deAddon, deState, printed = newRuntime("deDE")
deState.instanceName = "Lokalisierter Dungeon"
deState.instanceID = 2805
deState.mapID = 999999
deState.subzone = "Die Promenade"
deAddon.DUNGEON_BY_INSTANCEID = {
    [2805] = {
        instanceID = 2805,
        name = "Windrunner Spire",
        mythicPlus = false,
        bosses = {},
        areas = {
            { id = "2805:1", subzone = "The Promenade", tip = "Area tip" },
        },
    },
}
deAddon:UpdateContent()
ok(contains(deAddon.captured, "Area tip"), "Core SubzoneMatches accepts loaded verified deDE alias")
ok(contains(deAddon.captured, "Lokalisierter Dungeon"), "localized area header uses Blizzard instance name")

io.write("\n--- production localized affix heading (deDE) ---\n")
-- P2-1: the M+ holding screen heading must come from the locale table, not a
-- hard-coded English literal. Driven through UpdateContent, the shipped path.
local savedSubzone, savedInstanceID = deState.subzone, deState.instanceID
deState.subzone    = ""
deState.instanceID = 2813
deAddon.DUNGEON_BY_INSTANCEID[2813] = {
    instanceID = 2813, name = "Murder Row", mythicPlus = true, bosses = {}, areas = {},
}
C_ChallengeMode = {
    GetActiveKeystoneInfo = function() return 12, { 9 } end,
    GetAffixInfo = function() return { name = "Tyrannisch", description = "Bosse sind stärker." } end,
}
resetBossState(deAddon)
deAddon:UpdateContent()
ok(contains(deAddon.captured, "+12 Aktive Affixe"),
    "production affix heading uses the deDE locale value")
ok(not contains(deAddon.captured, "Active Affixes"),
    "production affix heading no longer emits the English literal")
C_ChallengeMode = nil
deAddon.DUNGEON_BY_INSTANCEID[2813] = nil
deState.subzone, deState.instanceID = savedSubzone, savedInstanceID

io.write("\n--- empty translations fall back to English ---\n")
-- P2-2: "" is how translation tooling spells "untranslated". It must never
-- shadow the English prose behind it, at any level of the fallback chain.
deAddon.AREA_OVERRIDE_BY_ID["2805:1"] = { tip = "" }
resetBossState(deAddon)
deAddon:UpdateContent()
ok(contains(deAddon.captured, "Area tip"),
    "empty translated area tip falls back to the English area tip")
deAddon.AREA_OVERRIDE_BY_ID["2805:1"] = nil

local emptyDungeon = { name = "Windrunner Spire", mythicPlus = false }
local emptyNotesBoss = {
    encounterID = 201,
    name = "Empty Note Boss",
    notes = {
        { role = "general", text = "English general" },
        { role = "healer",  text = "English healer" },
    },
}
emptyDungeon.bosses = { emptyNotesBoss }
deAddon.TIP_OVERRIDE_BY_ENCOUNTERID[201] = {
    notes = {
        { role = "general", text = "Deutscher Allgemeinhinweis" },
        { role = "healer",  text = "" },
    },
}
output = renderBoss(deAddon, deState, emptyDungeon, emptyNotesBoss, 10)
ok(contains(output, "English healer"),
    "empty translated role note does not claim its role — English healer survives")
ok(not contains(output, HEAL_ICON .. " |cff33cc33" .. RESET),
    "empty translated role note renders no blank role line")
ok(contains(output, "Deutscher Allgemeinhinweis"),
    "non-empty translated role note is still rendered alongside the fallback")
deAddon.TIP_OVERRIDE_BY_ENCOUNTERID[201] = nil

local emptyFlatBoss = { encounterID = 202, name = "Empty Flat Boss", tip = "English flat tip" }
emptyDungeon.bosses = { emptyFlatBoss }
deAddon.TIP_OVERRIDE_BY_ENCOUNTERID[202] = { tip = "" }
output = renderBoss(deAddon, deState, emptyDungeon, emptyFlatBoss, 10)
ok(contains(output, "English flat tip"),
    "empty translated flat tip falls back to the English flat tip")
deAddon.TIP_OVERRIDE_BY_ENCOUNTERID[202] = nil

local emptyDiffBoss = {
    encounterID = 203,
    name = "Empty Difficulty Boss",
    tip = "English base tip",
    difficulties = { [10] = { tip = "English difficulty tip" } },
}
emptyDungeon.bosses = { emptyDiffBoss }
deAddon.TIP_OVERRIDE_BY_ENCOUNTERID[203] = { difficulties = { [10] = { tip = "" } } }
output = renderBoss(deAddon, deState, emptyDungeon, emptyDiffBoss, 10)
ok(contains(output, "English difficulty tip"),
    "empty translated difficulty flat tip falls back to the English difficulty tip")
deAddon.TIP_OVERRIDE_BY_ENCOUNTERID[203] = nil
resetBossState(deAddon)

local dataAddon = {}
loadAddonFile("DungeonData.lua", dataAddon)
local ids, total, missing = {}, 0, 0
for _, dataDungeon in ipairs(dataAddon.DUNGEONS) do
    for _, area in ipairs(dataDungeon.areas or {}) do
        total = total + 1
        if not area.id or ids[area.id] then missing = missing + 1 end
        ids[area.id] = true
    end
end
ok(total > 0 and missing == 0, "all authored area IDs are present and unique")

io.write("\n--- preserved German UI/runtime strings ---\n")
local expectedGerman = {
    SETTINGS_TITLE = "KwikTip-Einstellungen",
    LOADED_MSG = "geladen. Tippe /kwik für die Einstellungen.",
    WAITING_ENCOUNTER = "Warte auf passende Begegnung …",
    DEMO_DUNGEON = "Beispiel-Dungeon",
    TAB_APPEARANCE = "Darstellung",
    CHECK_MINIMAP = "Minikarten-Button anzeigen",
    CHECK_PERSISTENT = "Dauerhaftes Tipp-Fenster",
    LABEL_NONE = "Keine",
    CHECK_AUTOEXPAND = "Höhe automatisch anpassen",
    LABEL_OUTLINE = "Kontur:",
    OUTLINE_OUTLINE = "Kontur",
    OUTLINE_THICK = "Dicke Kontur",
    TOOLTIP_MINIMAP_DRAG = "Ziehen: Position ändern",
    BTN_NOTE_CLEAR = "Leeren",
    TOOLTIP_PRINT = "Tipp in Instanzchat ausgeben",
}
for key, value in pairs(expectedGerman) do
    ok(deAddon.L[key] == value, "preserved deDE value: " .. key)
end

deAddon:ShowPreview()
ok(contains(deAddon.captured, "Rote Zonen meiden"), "production preview restores German general text")
ok(contains(deAddon.captured, "Tankwechsel bei 3 Stapeln"), "production preview restores German tank text")

SlashCmdList.KWIKTIP("debug")
local debugText = table.concat(printed, "\n")
ok(contains(debugText, "Typ=party"), "production debug output restores German format")
SlashCmdList.KWIKTIP("debuglog")
ok(contains(table.concat(printed, "\n"), "Debug-Protokollierung aktiviert."),
    "production debug logging message is localized")
SlashCmdList.KWIKTIP("feedback")
ok(contains(table.concat(printed, "\n"), "Tipps passen nicht?"),
    "production feedback message is localized")
SlashCmdList.KWIKTIP("support")
local supportText = table.concat(printed, "\n")
ok(contains(supportText, "KwikTip ist kostenlos"),
    "production support message is localized")
ok(contains(supportText, "https://ko-fi.com/postblink"),
    "support message carries the tip URL in every locale")

io.write(string.format("\n=== RESULTS: %d passed, %d failed (of %d total) ===\n",
    PASS, FAIL, PASS + FAIL))
if FAIL > 0 then os.exit(1) end
