"""Research-only 70959 positive-identity slices; not a client acceptance test."""
import json
from pathlib import Path

import unittest

ROOT = Path(__file__).resolve().parents[1]

class FourMapsCandidateTests(unittest.TestCase):
    def test_historical_hotfix_comparison_found_no_row_changes(self):
        comparison = json.loads((ROOT / 'docs/FOREVER_HOTFIX_COMPARISON_70959.json').read_text())
        self.assertEqual(sum(len(records) for records in comparison.values()), 9)
        self.assertTrue(all(r['equal'] for records in comparison.values() for r in records))

    def test_upper_events_are_registered_and_match_positive_rows(self):
        ledger = json.loads((ROOT / 'docs/FOREVER_FOUR_MAPS_IDS_70959.json').read_text())
        coverage = json.loads((ROOT / 'Forever/Coverage.json').read_text())
        expected = {3062: 'Pyroguard Emberseer', 3063: 'Warchief Rend Blackhand',
                    3068: 'The Beast', 3069: 'General Drakkisath', 3070: 'Lord Valthalak'}
        rows = {r['record_id']: r for r in ledger['tables']['DungeonEncounter']['target_rows']}
        for event, name in expected.items():
            self.assertEqual((rows[event]['fields']['MapID'], rows[event]['fields']['Name_lang']), (229, name))
            self.assertEqual(rows[event]['source_section'], 0)
        self.assertEqual(ledger['tables']['DungeonEncounter']['target_cache_records'], [])
        spire = next(d for d in coverage['included_dungeons'] if d['instanceID'] == 229)
        self.assertTrue(set(expected).issubset(spire['encounterIDs']))

    def test_three_new_dungeons_admit_only_sourced_positive_events(self):
        ledger = json.loads((ROOT / 'docs/FOREVER_FOUR_MAPS_IDS_70959.json').read_text())
        coverage = json.loads((ROOT / 'Forever/Coverage.json').read_text())
        expected = {2994: {3403, 3409, 3410, 3415, 3418},
                    2974: {3315, 3316, 3322, 3323, 3327, 3334, 3336},
                    3001: {3498, 3500, 3501, 3502, 3503, 3505, 3507, 3597}}
        rows = {r['record_id']: r for r in ledger['tables']['DungeonEncounter']['target_rows']}
        for map_id, ids in expected.items():
            dungeon = next((d for d in coverage['included_dungeons'] if d['instanceID'] == map_id), None)
            self.assertIsNotNone(dungeon, str(map_id))
            self.assertEqual(set(dungeon['encounterIDs']), ids)
            self.assertEqual(dungeon['difficultyIDs'], [1])
            for event in ids:
                self.assertEqual(rows[event]['fields']['MapID'], map_id)
                self.assertEqual(rows[event]['source_section'], 2)

if __name__ == '__main__':
    unittest.main()
