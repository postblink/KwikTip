"""Krol'dok research slice: positive 70959 identity and explicit exclusions."""
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class KroldokCandidateTests(unittest.TestCase):
    @patch.dict(sys.modules)
    def test_research_identity_rejects_alpha6_release_and_is_disabled(self):
        import importlib.util
        import tempfile

        spec = importlib.util.spec_from_file_location("package_forever", ROOT / "tools/package_forever.py")
        assert spec and spec.loader
        package = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(package)
        sys.modules["package_forever"] = package
        spec = importlib.util.spec_from_file_location("kroldok_release_test", ROOT / "tools/forever_release.py")
        assert spec and spec.loader
        release = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(release)
        version, _ = release.metadata()
        self.assertEqual(version, "0.1.0-test.20261122")
        with self.assertRaises(ValueError):
            release.validate_tag("forever-v0.1.0-alpha.6", version)
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "release"
            with self.assertRaises(ValueError):
                release.prepare(target, "forever-v0.1.0-alpha.6")
            self.assertFalse(target.exists())
            with self.assertRaises(ValueError):
                release.prepare(target, "forever-v0.1.0-test.20261118")
            self.assertFalse(target.exists())
            with self.assertRaises(ValueError):
                release.prepare(target, "forever-v0.1.0-test.20261122")
            self.assertFalse(target.exists())
            with self.assertRaises(ValueError):
                release.prepare(target, "forever-v0.1.0-test.20261117")
            self.assertFalse(target.exists())
            result = release.prepare(target)
            self.assertEqual(result["archive_name"], "KwikTip_Forever-0.1.0-test.20261122.zip")
            sys.modules["forever_release"] = release
            spec = importlib.util.spec_from_file_location("kroldok_marketplace_test", ROOT / "tools/forever_marketplaces.py")
            assert spec and spec.loader
            markets = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(markets)
            for tag in ("forever-v0.1.0-alpha.6", "forever-v0.1.0-test.20261117", "forever-v0.1.0-test.20261118", "forever-v0.1.0-test.20261122"):
                with self.assertRaises(ValueError):
                    markets.verified_inputs(target, tag)
            toc = (target / "package/KwikTip_Forever/KwikTip_Forever.toc").read_text()
            self.assertIn("## DefaultState: disabled", toc)
            self.assertIn("KwikTip: Forever (Test Build)", toc)

    def test_identity_evidence_and_conservative_scope(self):
        evidence = json.loads((ROOT / "docs/FOREVER_KROLDOK_IDS_70959.json").read_text())
        coverage = json.loads((ROOT / "Forever/Coverage.json").read_text())
        self.assertEqual(evidence["build"], "1.60.1.70959")
        self.assertFalse(evidence["complete_tables"])
        self.assertFalse(evidence["client_tested"])
        self.assertEqual(evidence["extraction"]["build_info_sha256_before"], evidence["extraction"]["build_info_sha256_after"])
        for table in evidence["tables"].values():
            sections = {section["section"]: section for section in table["sections"]}
            self.assertTrue(any(not section["readable"] for section in sections.values()))
            self.assertEqual(table["target_cache_records"], [])
            self.assertEqual(len(table["schema_sha256"]), 64)
            for row in table["target_rows"]:
                self.assertTrue(sections[row["source_section"]]["readable"])
        maprow = evidence["tables"]["Map"]["target_rows"][0]["fields"]
        self.assertEqual((maprow["ID"], maprow["InstanceType"]), (3039, 1))
        modes = {r["fields"]["DifficultyID"]: r["fields"] for r in evidence["tables"]["MapDifficulty"]["target_rows"]}
        self.assertEqual((modes[1]["MapID"], modes[1]["MaxPlayers"]), (3039, 10))
        rows = {r["record_id"]: r["fields"] for r in evidence["tables"]["DungeonEncounter"]["target_rows"]}
        expected = {3450: "Slavecrusher Grox", 3452: "Twilight Commander Zarmok", 3449: "Nar'gurk"}
        for record_id, name in expected.items():
            self.assertEqual((rows[record_id]["Name_lang"], rows[record_id]["MapID"]), (name, 3039))
        self.assertEqual(rows[3451]["Name_lang"], "Overseer Mugg")
        self.assertEqual(rows[3453]["Name_lang"], "Handler Ashka")
        dungeon = next(row for row in coverage["included_dungeons"] if row["instanceID"] == 3039)
        self.assertEqual(dungeon["encounterIDs"], [3450, 3452, 3453, 3449, 3451])
        self.assertEqual(dungeon["difficultyIDs"], [1])
        self.assertEqual({r.get("encounterID") for r in dungeon["excluded_encounters"] if r.get("encounterID")}, set())
        self.assertTrue(any(r["name"] == "Bossman Toof" for r in dungeon["excluded_encounters"]))
        self.assertFalse(coverage["client_tested"])


if __name__ == "__main__":
    unittest.main()
