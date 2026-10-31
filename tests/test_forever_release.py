from __future__ import annotations

from contextlib import contextmanager
import fnmatch
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import yaml

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import forever_release


@contextmanager
def alpha_source():
    current_version, _ = forever_release.metadata()
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory) / "source"
        shutil.copytree(ROOT / "Forever", root / "Forever")
        for path in root.joinpath("Forever").rglob("*"):
            if path.is_file():
                text = path.read_text()
                path.write_text(text.replace(current_version, "0.1.0-alpha.1"))
        for relative in forever_release.package_forever.SHARED_FILES + ("LICENSE",):
            destination = root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        shutil.copytree(ROOT / "assets", root / "assets")
        shutil.copytree(ROOT / "docs", root / "docs")
        with patch.object(forever_release, "ROOT", root), patch.object(forever_release.package_forever, "ROOT", root):
            yield root


class ForeverReleaseTests(unittest.TestCase):
    def test_tag_validation_is_disjoint_alpha_only_and_matches_toc(self):
        forever_release.validate_tag("forever-v0.1.0-alpha.1", "0.1.0-alpha.1")
        for tag in ["v3.5.0", "forever-v0.1.0", "forever-v0.1.0-beta.1",
                    "forever-v0.1.0-test.2", "main", "forever-v0.1.0-alpha.1\nextra",
                    "forever-v0.1.0-alpha.2", "forever-v$(echo unsafe)"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                forever_release.validate_tag(tag, "0.1.0-alpha.1")

    def test_invalid_publication_tag_writes_nothing(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "dist"
            with self.assertRaises(ValueError):
                forever_release.prepare(output, "v3.5.0")
            self.assertFalse(output.exists())

    def test_alpha_build_has_standalone_zip_and_official_flavor_metadata(self):
        with alpha_source() as root:
            output = root.parent / "dist"
            result = forever_release.prepare(output, "forever-v0.1.0-alpha.1")
            self.assertEqual(result["archive_name"], "KwikTip_Forever-0.1.0-alpha.1.zip")
            release = json.loads((output / "release.json").read_text())["releases"][0]
            self.assertEqual(release["filename"], result["archive_name"])
            self.assertEqual(release["version"], result["version"])
            self.assertIs(release["nolib"], False)
            self.assertEqual(release["metadata"], [{"flavor": "forever", "interface": 16001}])
            with zipfile.ZipFile(output / release["filename"]) as archive:
                names = archive.namelist()
                self.assertEqual(archive.testzip(), None)
                self.assertTrue(all(name.startswith("KwikTip_Forever/") and ".." not in Path(name).parts for name in names))
                self.assertIn("KwikTip_Forever/KwikTip_Forever.toc", names)
                self.assertFalse(any("Timewalking" in name or ".pkgmeta" in name or ".github" in name for name in names))
                self.assertNotIn("Murder Row", archive.read("KwikTip_Forever/DungeonData.lua").decode())
            for line in (output / "SHA256SUMS").read_text().splitlines():
                expected, name = line.split("  ", 1)
                self.assertEqual(hashlib.sha256((output / name).read_bytes()).hexdigest(), expected)
            notes = (output / "release-notes.md").read_text()
            self.assertIn("0.1.0-alpha.1", notes)
            self.assertIn("Client validation: pending", notes)
            coverage = json.loads((output / "coverage.json").read_text())
            self.assertEqual(coverage["version"], result["version"])
            self.assertFalse(coverage["client_tested"])
            self.assertEqual(coverage["complete_dungeons"], 0)
            self.assertEqual({d["instanceID"] for d in coverage["included_dungeons"]}, {3065, 389, 34})
            evidence = json.loads((output / "source-evidence.json").read_text())
            self.assertEqual({d["instanceID"] for d in evidence["dungeons"]}, {3065, 389, 34})
            stockade = next(d for d in coverage["included_dungeons"] if d["instanceID"] == 34)
            self.assertEqual(stockade["encounterIDs"], [2756, 2757, 2758, 2759, 2760])
            self.assertIn("Bruegal Ironknuckle", str(stockade["excluded_encounters"]))
            with self.assertRaises(FileExistsError):
                forever_release.prepare(output)

    def test_version_disagreement_is_not_packaged(self):
        with alpha_source() as root:
            (root / "Forever/README.txt").write_text("Wrong version\n")
            with self.assertRaises(ValueError):
                forever_release.prepare(root.parent / "dist")

    def test_coverage_version_and_evidence_paths_fail_closed(self):
        with alpha_source() as root:
            path = root / "Forever/Coverage.json"
            coverage = json.loads(path.read_text())
            coverage["version"] = "0.1.0-alpha.999"
            path.write_text(json.dumps(coverage))
            with self.assertRaises(ValueError):
                forever_release.prepare(root.parent / "version-mismatch")
            coverage["version"] = "0.1.0-alpha.1"
            coverage["included_dungeons"][0]["evidence"] = "../outside.json"
            path.write_text(json.dumps(coverage))
            with self.assertRaises(ValueError):
                forever_release.prepare(root.parent / "invalid-evidence")

    def test_workflow_publishes_only_forever_tag_builds_with_scoped_token(self):
        workflow = yaml.load((ROOT / ".github/workflows/forever-release.yml").read_text(), Loader=yaml.BaseLoader)
        retail = yaml.load((ROOT / ".github/workflows/release.yml").read_text(), Loader=yaml.BaseLoader)
        self.assertEqual(retail["on"]["push"]["tags"], ["v*"])
        self.assertEqual(workflow["on"]["push"]["tags"], ["forever-v*"])
        self.assertIn("pull_request", workflow["on"])
        self.assertIn("workflow_dispatch", workflow["on"])
        self.assertEqual(workflow["permissions"], {"contents": "read"})
        publish = workflow["jobs"]["publish"]
        self.assertEqual(publish["needs"], "build")
        self.assertEqual(publish["if"], "github.event_name == 'push' && startsWith(github.ref, 'refs/tags/forever-v')")
        self.assertEqual(publish["permissions"], {"contents": "write"})
        steps = publish["steps"]
        token_steps = [step for step in steps if "GH_TOKEN" in step.get("env", {})]
        self.assertEqual(len(token_steps), 1)
        command = token_steps[0]["run"]
        for option in ["--verify-tag", "--prerelease", "--latest=false", "--notes-file"]:
            self.assertIn(option, command)
        for asset in ["dist/release.json", "dist/SHA256SUMS", "dist/source-evidence.json", "dist/coverage.json", "dist/release-notes.md"]:
            self.assertIn(asset, command.split("--repo", 1)[0])
        self.assertNotIn("--clobber", command)
        source = (ROOT / ".github/workflows/forever-release.yml").read_text()
        self.assertNotIn("CF_API_KEY", str(workflow["jobs"]["build"]))
        self.assertNotIn("WAGO_API_TOKEN", str(workflow["jobs"]["build"]))
        marketplace_steps = [step for step in steps if "CF_API_KEY" in step.get("env", {})]
        self.assertEqual(len(marketplace_steps), 1)
        self.assertIn("WAGO_API_TOKEN", marketplace_steps[0]["env"])
        self.assertIn("--publish", marketplace_steps[0]["run"])
        self.assertNotIn("WOWI_API_TOKEN", source)

    def test_retail_pkgmeta_excludes_all_forever_specific_files(self):
        meta = yaml.load((ROOT / ".pkgmeta").read_text(), Loader=yaml.BaseLoader)
        self.assertEqual(meta["curse-id"], "1478824")
        self.assertEqual(meta["wago-id"], "QN53W7KB")
        self.assertEqual(meta["wowi-id"], "27074")
        candidates = ["Forever/DungeonData.lua", "Forever/Flavor.lua", "Forever/RuntimeIndexes.lua",
                      "docs/FOREVER_READINESS.md", "docs/FOREVER_HALL_OF_THANES_IDS_70707.json",
                      "tools/package_forever.py", "tools/forever_release.py", "tools/forever_marketplaces.py",
                      "tests/test_forever_package.py", "tests/test_forever_runtime.lua", "tests/test_forever_release.py"]
        for relative in candidates:
            with self.subTest(path=relative):
                self.assertTrue(any(fnmatch.fnmatch(relative, pattern) or relative.startswith(pattern + "/") for pattern in meta["ignore"]))


if __name__ == "__main__":
    unittest.main()
