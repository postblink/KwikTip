"""Lower-only candidate contract: positive IDs, conservative scope and visible caveats."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CANDIDATE = ROOT / "docs/FOREVER_LBRS_CANDIDATE_20261112.json"
SPEC = importlib.util.spec_from_file_location("package_forever", ROOT / "tools/package_forever.py")
assert SPEC and SPEC.loader
BUILDER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILDER)
EXPECTED = [267, 268, 269, 270, 271, 272, 274, 273, 275]
UPPER = {3062, 3063, 3068, 3069, 3070}


class LowerBlackrockSpireCandidateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.candidate = json.loads(CANDIDATE.read_text())
        self.evidence = json.loads((ROOT / self.candidate["raw_identity_evidence"]).read_text())
        self.coverage = json.loads((ROOT / "Forever/Coverage.json").read_text())

    def test_exact_identity_matches_readable_plaintext_sections(self) -> None:
        evidence = self.evidence
        self.assertEqual(evidence["data_build"], "1.60.1.70888")
        self.assertTrue(evidence["target_rows_verified"])
        self.assertFalse(evidence["complete_tables"])
        self.assertFalse(evidence["client_tested"])
        self.assertFalse(evidence["verification"]["fresh_extraction"])
        self.assertTrue(evidence["verification"]["artifact_redecode"])
        for name, table in evidence["verified_tables"].items():
            self.assertGreater(table["missing_sections"], 0)
            self.assertEqual(len(table["schema_sha256"]), 64)
            self.assertEqual(len(table["readable_rows_sha256"]), 64)
            sections = {row["section"]: row for row in table["sections"]}
            for row in table["blackrock_spire_rows"]:
                self.assertEqual(row["record_id"], row["fields"]["ID"])
                section = sections[row["source_section"]]
                self.assertTrue(section["readable"])
                self.assertEqual(section["public_key_lookup"], "0000000000000000")
                for missing in evidence["extraction"]["tables"][name]["missing_chunks"]:
                    self.assertFalse(missing["Offset"] < section["end"] and
                                     missing["Offset"] + missing["Length"] > section["offset"])
        tables = evidence["verified_tables"]
        raw_map = tables["Map"]["blackrock_spire_rows"][0]["fields"]
        self.assertEqual((raw_map["ID"], raw_map["InstanceType"]), (229, 1))
        modes = [row["fields"] for row in tables["MapDifficulty"]["blackrock_spire_rows"]]
        normal = next(row for row in modes if row["DifficultyID"] == 1)
        self.assertEqual((normal["ID"], normal["MapID"], normal["MaxPlayers"]), (24, 229, 10))
        events = {row["record_id"]: row["fields"] for row in tables["DungeonEncounter"]["blackrock_spire_rows"]}
        for boss in self.candidate["bosses"]:
            raw = events[boss["encounterID"]]
            self.assertEqual(raw["Name_lang"], boss["name"])
            self.assertEqual((raw["MapID"], raw["DifficultyID"]), (229, 0))
        self.assertEqual(events[274]["Name_lang"], "Halycon")
        self.assertTrue(UPPER <= events.keys())

    def test_no_observed_hotfix_override_is_not_server_completeness(self) -> None:
        cache = self.evidence["local_hotfix_check"]
        self.assertEqual(cache["build"], 70888)
        self.assertTrue(cache["build_unchanged"])
        self.assertEqual(len(cache["cache_sha256"]), 64)
        self.assertEqual(cache["build_info_sha256"], self.evidence["extraction"]["build_info_sha256_after"])
        for name, targets in [("Map", {229}), ("MapDifficulty", {24, 5575, 6334}), ("DungeonEncounter", set(EXPECTED))]:
            self.assertFalse(targets.intersection(row["record_id"] for row in cache["tables"][name]))
        self.assertIn("not proof", self.evidence["verification"]["hotfix_scope"])

    def test_nine_sourced_tips_stay_visibly_provisional(self) -> None:
        candidate = self.candidate
        self.assertEqual([boss["encounterID"] for boss in candidate["bosses"]], EXPECTED)
        self.assertTrue(candidate["strategy_provisional"])
        sources = {source["id"] for source in candidate["sources"]}
        for boss in candidate["bosses"]:
            self.assertIn(boss["source"], sources)
            self.assertTrue(boss["tip"].startswith("Provisional Classic advice: "))
            self.assertLessEqual(len(boss["tip"]), 220)
        self.assertIn("Lower Blackrock Spire only", candidate["overview"])
        self.assertEqual(set(candidate["excluded_encounterIDs"]), UPPER)
        self.assertFalse(UPPER.intersection(EXPECTED))
        self.assertFalse(candidate["client_tested"])
        self.assertTrue(candidate["promotion_requirements"])

    def test_coverage_and_packaged_data_agree(self) -> None:
        entry = next(d for d in self.coverage["included_dungeons"] if d["instanceID"] == 229)
        self.assertEqual(entry["encounterIDs"][:9], EXPECTED)
        self.assertEqual(set(entry["encounterIDs"][9:]), UPPER)
        self.assertEqual(entry["difficultyIDs"], [1])
        self.assertEqual(entry["evidence"], self.candidate["raw_identity_evidence"])
        self.assertEqual(entry["data_build"], "1.60.1.70959")
        self.assertEqual(entry["current_evidence"], "docs/FOREVER_FOUR_MAPS_IDS_70959.json")
        self.assertFalse(self.coverage["client_tested"])
        self.assertTrue(self.coverage["current_build_ids_reverified"])
        self.assertEqual(self.coverage["complete_dungeons"], 0)
        self.assertEqual(sum(len(d["encounterIDs"]) for d in self.coverage["included_dungeons"]), 229)
        self.assertEqual(len(self.coverage["included_dungeons"]), 28)
        with tempfile.TemporaryDirectory() as temp:
            package = BUILDER.build(Path(temp) / "out")
            self.assertFalse((package / "docs").exists())
            data = (package / "DungeonData.lua").read_text()
            for encounter_id in EXPECTED:
                self.assertIn(f"encounterID = {encounter_id},", data)
            self.assertIn("Lower: control ogre casters", data)
            self.assertIn("Upper: clear dragonkin", data)
            self.assertIn("Unreleased", (package / "README.txt").read_text())


if __name__ == "__main__":
    unittest.main()
