from __future__ import annotations

import importlib.util
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("package_forever", ROOT / "tools/package_forever.py")
assert SPEC and SPEC.loader
PACKAGE_BUILDER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGE_BUILDER)


class ForeverPackageTests(unittest.TestCase):
    def run_runtime(self, package: Path, locale: str = "enUS") -> subprocess.CompletedProcess[str]:
        interpreter = shutil.which("lua5.1") or shutil.which("luajit")
        self.assertIsNotNone(interpreter, "Install Lua 5.1 or LuaJIT to run the WoW-compatible runtime gate")
        return subprocess.run(
            [interpreter, str(ROOT / "tests/test_forever_runtime.lua"), str(package), locale],
            text=True, capture_output=True, timeout=30, check=False,
        )

    def test_builds_interface_16001_package_with_isolated_data(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            package = PACKAGE_BUILDER.build(Path(temp_dir) / "out")
            toc = (package / "KwikTip_Forever.toc").read_text()
            self.assertIn("## Interface: 16001", toc)
            self.assertIn("## Title: KwikTip: Forever", toc)
            self.assertIn("## SavedVariables: KwikTipDB", toc)
            self.assertNotIn("DungeonData_Timewalking.lua", toc)
            self.assertFalse((package / "DungeonData_Timewalking.lua").exists())
            self.assertFalse((package / "Locale/tips_deDE.lua").exists())
            self.assertNotIn("tips_deDE.lua", toc)
            self.assertNotIn("2805:1", (package / "Locale/tips.lua").read_text())
            self.assertFalse((package / ".pkgmeta").exists())
            self.assertFalse((package / ".github").exists())
            self.assertTrue((package / "LICENSE").is_file())
            self.assertTrue((package / "README.txt").is_file())

            loaded_files = [line for line in toc.splitlines() if line.endswith((".lua", ".xml"))]
            self.assertLess(loaded_files.index("Init.lua"), loaded_files.index("DungeonData.lua"))
            self.assertLess(loaded_files.index("DungeonData.lua"), loaded_files.index("Core.lua"))
            self.assertLess(loaded_files.index("RuntimeIndexes.lua"), loaded_files.index("Core.lua"))
            self.assertGreater(loaded_files.index("Flavor.lua"), loaded_files.index("Core.lua"))
            missing = [
                name for name in loaded_files
                if not (package.joinpath(*name.replace("\\", "/").split("/"))).is_file()
            ]
            if missing:
                raise AssertionError(f"Missing manifest files: {missing}")
            for relative in PACKAGE_BUILDER.SHARED_FILES:
                self.assertTrue((package / relative).is_file(), relative)

    def test_assets_resolve_in_standalone_folder_and_retail_source_stays_unchanged(self) -> None:
        original = (ROOT / "UI_Config.lua").read_bytes()
        with tempfile.TemporaryDirectory() as temp_dir:
            package = PACKAGE_BUILDER.build(Path(temp_dir) / "out")
            config = (package / "UI_Config.lua").read_text()
            self.assertNotIn(r"Interface\\AddOns\\KwikTip\\assets\\", config)
            for asset in ("ktmini.tga", "ktlogo.tga"):
                self.assertIn(rf"Interface\\AddOns\\KwikTip_Forever\\assets\\{asset}", config)
                self.assertEqual((package / "assets" / asset).read_bytes(), (ROOT / "assets" / asset).read_bytes())
        self.assertEqual((ROOT / "UI_Config.lua").read_bytes(), original)

    def test_packaged_addon_loads_and_routes_real_core_for_all_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            package = PACKAGE_BUILDER.build(Path(temp_dir) / "out")
            for locale in ("enUS", "deDE", "frFR"):
                with self.subTest(locale=locale):
                    result = self.run_runtime(package, locale)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_runtime_gate_catches_missing_namespace(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            package = PACKAGE_BUILDER.build(Path(temp_dir) / "out")
            data = package / "DungeonData.lua"
            data.write_text(data.read_text().replace("local ADDON_NAME, KwikTip = ...", ""))
            result = self.run_runtime(package)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("KwikTip", result.stderr)

    def test_runtime_gate_catches_missing_indexes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            package = PACKAGE_BUILDER.build(Path(temp_dir) / "out")
            toc = package / "KwikTip_Forever.toc"
            toc.write_text(toc.read_text().replace("RuntimeIndexes.lua\n", ""))
            result = self.run_runtime(package)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("DUNGEON_BY_INSTANCEID", result.stdout + result.stderr)

    def test_refuses_to_overwrite_existing_output(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "existing"
            output.mkdir()
            sentinel = output / "keep.txt"
            sentinel.write_text("keep")
            with self.assertRaises(FileExistsError):
                PACKAGE_BUILDER.build(output)
            self.assertEqual(sentinel.read_text(), "keep")

    def test_retail_toc_has_no_forever_boss_preview_behavior(self) -> None:
        interpreter = shutil.which("lua5.1") or shutil.which("luajit")
        self.assertIsNotNone(interpreter, "Install Lua 5.1 or LuaJIT to run the Retail parity check")
        script = r"""
local root = """ + repr(str(ROOT)) + r"""
local function noop() end
local Methods = {}
for name in ([[SetFrameStrata SetClampedToScreen SetMovable SetResizable
    SetResizeBounds SetBackdrop SetBackdropColor SetBackdropBorderColor
    SetClipsChildren SetJustifyH SetJustifyV SetWordWrap SetAllPoints
    SetColorTexture SetPassThroughButtons EnableMouseWheel RegisterForDrag
    RegisterForClicks SetFontObject SetAutoFocus SetMaxLetters SetMultiLine
    StartMoving StopMovingOrSizing StartSizing SetTextColor SetShadowOffset
    SetShadowColor SetBlendMode SetOrientation SetObeyStepOnDrag SetThumbTexture
    LockHighlight UnlockHighlight ClearFocus HighlightText SetFocus
    SetCursorPosition SetOwner ClearLines AddLine SetFont SetSize SetWidth
    SetHeight ClearAllPoints SetPoint SetText SetChecked SetMinMaxValues
    SetValueStep SetValue SetScrollChild SetVerticalScroll SetFrameLevel
    EnableMouse SetAlpha SetTexture]]):gmatch("%S+") do
    Methods[name] = noop
end
local frames = {}
function Methods:SetScript(ev, cb) self.scripts[ev] = cb end
function Methods:HookScript(ev, cb)
    local prev = self.scripts[ev]
    self.scripts[ev] = function(...) if prev then prev(...) end cb(...) end
end
function Methods:RegisterEvent(ev) self.events[ev] = true end
function Methods:UnregisterEvent(ev) self.events[ev] = nil end
function Methods:Show() self.shown = true end
function Methods:Hide() self.shown = false end
function Methods:SetShown(v) self.shown = v end
function Methods:IsShown() return self.shown end
function Methods:GetWidth() return 220 end
function Methods:GetHeight() return 80 end
function Methods:GetLeft() return 0 end
function Methods:GetBottom() return 0 end
function Methods:GetAlpha() return 1 end
function Methods:GetFrameLevel() return 1 end
function Methods:GetVerticalScrollRange() return 0 end
function Methods:GetVerticalScroll() return 0 end
function Methods:GetStringHeight() return 12 end
function Methods:GetText() return "" end
function Methods:CreateFontString(name) return CreateFrame("FontString", name, self) end
function Methods:CreateTexture(name) return CreateFrame("Texture", name, self) end
CreateFrame = function(kind, name, parent, template)
    local obj = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, events = {}, shown = false }, { __index = Methods })
    if template == "BasicFrameTemplate" then obj.TitleText = obj:CreateFontString(nil) end
    frames[#frames + 1] = obj
    if name then _G[name] = obj end
    return obj
end
UIParent = CreateFrame("Frame", "UIParent")
Minimap = CreateFrame("Frame", "Minimap", UIParent)
GameTooltip = CreateFrame("Tooltip", "GameTooltip", UIParent)
GameFontNormal = {}
SlashCmdList = {}
StaticPopupDialogs = {}
CLOSE = "Close"
StaticPopup_Show = noop
GetLocale = function() return "enUS" end
IsInInstance = function() return false, "none" end
GetInstanceInfo = function() return "Outside", "none", 0, "", 0, 0, false, 0 end
GetSubZoneText = function() return "" end
UnitGroupRolesAssigned = function() return "NONE" end
UnitCanAttack = function() return false end
UnitIsPlayer = function() return false end
InCombatLockdown = function() return false end
GetCursorPosition = function() return 0, 0 end
IsShiftKeyDown = function() return false end
date = function() return "test-time" end
C_Map = { GetBestMapForUnit = function() return nil end, GetPlayerMapPosition = function() return nil end }
C_Timer = { After = function(_, cb) cb() end, NewTimer = function() return { Cancel = noop } end }
UIFrameFadeIn = noop
UIFrameFadeOut = noop
local printed = {}
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    printed[#printed + 1] = table.concat(parts, "\t")
end

local addon = {}
local toc = assert(io.open(root .. "/KwikTip.toc", "r"))
for line in toc:lines() do
    local rel = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
    if rel:match("%.lua$") then
        local chunk, err = loadfile(root .. "/" .. rel:gsub("\\", "/"))
        assert(chunk, err)
        assert(pcall(chunk, "KwikTip", addon))
    end
end
toc:close()

for _, f in ipairs(frames) do
    if f.events.ADDON_LOADED and f.scripts.OnEvent then f.scripts.OnEvent(f, "ADDON_LOADED", "KwikTip") end
end
for _, f in ipairs(frames) do
    if f.events.PLAYER_LOGIN and f.scripts.OnEvent then f.scripts.OnEvent(f, "PLAYER_LOGIN") end
end

assert(addon.IS_FOREVER == nil, "Retail must not set IS_FOREVER")
assert(addon.InitForeverBossPreviewUI == nil, "Retail must not define InitForeverBossPreviewUI")
assert(addon.PreviewBoss == nil, "Retail must not define PreviewBoss")
assert(addon.RefreshForeverBossPreviewUI == nil, "Retail must not define RefreshForeverBossPreviewUI")

addon:ToggleConfig()
assert(addon.Config and addon.Config:IsShown(), "Retail config opens normally")
assert(_G.KwikTipBossPreviewDropBtn == nil, "Retail config must not create boss preview button")
assert(_G.KwikTipBossPreviewDropList == nil, "Retail config must not create boss preview list")
addon:ToggleConfig()

printed = {}
SlashCmdList.KWIKTIP("boss")
local bossOut = table.concat(printed, "\n")
assert(bossOut:find(addon.L.CMD_UNKNOWN, 1, true), "Retail /kwik boss must fall through to CMD_UNKNOWN")

printed = {}
SlashCmdList.KWIKTIP("help")
local helpOut = table.concat(printed, "\n")
assert(not helpOut:find("/kwik boss", 1, true), "Retail /kwik help must not advertise /kwik boss")
"""
        result = subprocess.run(
            [interpreter, "-e", script],
            text=True, capture_output=True, timeout=30, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
