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


if __name__ == "__main__":
    unittest.main()
