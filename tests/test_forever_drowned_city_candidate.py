"""Verify the evidence-backed Drowned City slice without claiming full coverage."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CANDIDATE = ROOT / "docs/FOREVER_DROWNED_CITY_CANDIDATE_20261111.json"
SPEC = importlib.util.spec_from_file_location("package_forever", ROOT / "tools/package_forever.py")
assert SPEC and SPEC.loader
PACKAGE_BUILDER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGE_BUILDER)


class DrownedCityCandidateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.candidate = json.loads(CANDIDATE.read_text())

    def test_normal_only_runtime_identity_retains_client_acceptance_gate(self) -> None:
        self.assertEqual(self.candidate["schema_version"], 1)
        self.assertIs(self.candidate["runtime_enabled"], True)
        self.assertIs(self.candidate["raw_identity_verified"], True)
        self.assertIs(self.candidate["client_tested"], False)
        self.assertEqual(self.candidate["instanceID"], 2970)
        self.assertEqual(self.candidate["difficultyIDs"], [1])
        self.assertEqual([b["encounterID"] for b in self.candidate["bosses"]], [3474, 3475, 3476, 3511, 3479])
        self.assertGreater(len(self.candidate["promotion_requirements"]), 0)

    def test_target_rows_are_verified_without_complete_table_claim(self) -> None:
        evidence = json.loads((ROOT / self.candidate["raw_identity_evidence"]).read_text())
        self.assertEqual(evidence["data_build"], "1.60.1.70888")
        self.assertTrue(evidence["target_rows_verified"])
        self.assertFalse(evidence["complete_tables"])
        self.assertFalse(evidence["client_tested"])
        self.assertTrue(evidence["extraction"]["build_unchanged"])
        self.assertFalse(evidence["extraction"]["network_fallback"])
        for name, table in evidence["verified_tables"].items():
            self.assertGreater(table["missing_sections"], 0)
            self.assertEqual(len(table["schema_sha256"]), 64)
            readable = {s["section"] for s in table["sections"] if s["readable"]}
            for row in table["drowned_city_rows"]:
                self.assertIn(row["source_section"], readable)
                self.assertEqual(row["fields"]["ID"], row["record_id"])
        tables = evidence["verified_tables"]
        map_row = tables["Map"]["drowned_city_rows"][0]["fields"]
        self.assertEqual((map_row["ID"], map_row["InstanceType"]), (2970, 1))
        modes = [row["fields"] for row in tables["MapDifficulty"]["drowned_city_rows"]]
        normal = next(row for row in modes if row["DifficultyID"] == 1)
        self.assertEqual((normal["MapID"], normal["MaxPlayers"]), (2970, 5))
        events = {row["record_id"]: row["fields"] for row in tables["DungeonEncounter"]["drowned_city_rows"]}
        for boss in self.candidate["bosses"]:
            raw = events[boss["encounterID"]]
            self.assertEqual(raw["Name_lang"], boss["name"])
            self.assertEqual(raw["MapID"], 2970)
        self.assertEqual(events[3478]["Name_lang"], "Deathless Guardians")
        overlays = evidence["local_hotfix_check"]["tables"]
        minloth = next(row for row in overlays["DungeonEncounter"] if row["record_id"] == 3479)
        self.assertEqual(minloth["fields"], events[3479])
        self.assertFalse(any(row["record_id"] == 2970 for row in overlays["Map"]))
        self.assertEqual(overlays["MapDifficulty"], [])

    def test_five_short_sourced_tips_include_new_primeval_advice(self) -> None:
        sources = {source["id"]: source for source in self.candidate["sources"]}
        self.assertEqual(sources["wowhead-guide"]["page_updated"], "2026-11-10")
        bosses = self.candidate["bosses"]
        names = [boss["name"] for boss in bosses]
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(set(names), {
            "Zul'Alai", "Var'Taka", "Captain Dreadrise",
            "Primeval Elemental", "Min'loth the Serpent",
        })
        for boss in bosses:
            self.assertIn(boss["source"], sources)
            self.assertTrue(boss["tip"].strip())
            self.assertLessEqual(len(boss["tip"]), 220)
        self.assertIn(self.candidate["overview_source"], sources)
        self.assertIn(self.candidate["reported_identity"]["source"], sources)
        self.assertIn(self.candidate["hotfix_review"]["source"], sources)
        for source in sources.values():
            self.assertTrue(source["url"].startswith("https://"))

    def test_unresolved_alias_and_rares_have_no_candidate_tip(self) -> None:
        excluded_names = {name for item in self.candidate["excluded"] for name in item["names"]}
        self.assertTrue({"Deathless Marrow", "Deathless Guardians", "Umbra", "Gill", "Zin'aka"} <= excluded_names)
        self.assertFalse(excluded_names & {boss["name"] for boss in self.candidate["bosses"]})
        self.assertTrue(all(item["reason"].strip() for item in self.candidate["excluded"]))

    def test_release_coverage_includes_only_the_admitted_subset(self) -> None:
        coverage = json.loads((ROOT / "Forever/Coverage.json").read_text())
        entry = next(item for item in coverage["included_dungeons"] if item["instanceID"] == 2970)
        self.assertEqual(entry["encounterIDs"], [3474, 3475, 3476, 3511, 3479])
        self.assertEqual(entry["difficultyIDs"], [1])
        self.assertEqual(entry["data_build"], "1.60.1.70888")
        self.assertEqual(entry["evidence"], self.candidate["raw_identity_evidence"])
        self.assertIn(3478, {item.get("encounterID") for item in entry["excluded_encounters"]})
        self.assertFalse(coverage["client_tested"])
        self.assertFalse(coverage["current_build_ids_reverified"])
        self.assertEqual(coverage["complete_dungeons"], 0)

    def test_package_contains_advice_but_not_research_or_decoder(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            package = PACKAGE_BUILDER.build(Path(temp_dir) / "out")
            self.assertFalse((package / CANDIDATE.name).exists())
            self.assertFalse((package / "docs").exists())
            self.assertFalse((package / "offline-reader").exists())
            data = (package / "DungeonData.lua").read_text()
            for boss in self.candidate["bosses"]:
                self.assertIn(boss["tip"], data)
            self.assertIn(self.candidate["overview_candidate"], data)


if __name__ == "__main__":
    unittest.main()
