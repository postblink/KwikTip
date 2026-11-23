"""Keep the normal-mode coverage ledger in sync with the packaged Lua dataset."""
import json
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ForeverCoverageTests(unittest.TestCase):
    def test_all_enabled_encounters_have_current_build_identity_and_tips(self):
        lua = shutil.which('lua5.1') or shutil.which('luajit')
        assert lua is not None, "Lua 5.1 or LuaJIT is required"
        report = json.loads((ROOT / 'Forever/Coverage.json').read_text())
        evidence = json.loads((ROOT / report['current_build_evidence']).read_text())
        self.assertTrue(report['current_build_ids_reverified'])
        self.assertEqual(evidence['build'], report['current_client_build_observed'])
        self.assertFalse(evidence['complete_tables'])
        self.assertEqual(evidence['local_hotfixes']['row_changes'], 0)
        verified = {row['instanceID']: row for row in evidence['maps']}
        units = evidence['units']
        self.assertEqual(len(units), len({row['name'] for row in units}))
        self.assertEqual({row['instanceID'] for row in units}, set(verified))
        source = '''
local ns = {}
assert(loadfile('Forever/DungeonData.lua'))('KwikTip_Forever', ns)
for _, d in ipairs(ns.DUNGEONS) do
    assert(d.overview and #d.overview > 20, 'Missing preparation: '..d.name)
    assert(#d.difficultyIDs == 1 and d.difficultyIDs[1] == 1, 'Normal only: '..d.name)
    for _, boss in ipairs(d.bosses) do
        assert(boss.tip and #boss.tip > 15, 'Missing tip: '..boss.name)
        print(d.instanceID .. '\\t' .. boss.encounterID .. '\\t' .. boss.name)
    end
end
'''
        actual = {}
        for line in subprocess.check_output([lua, '-e', source], cwd=ROOT, text=True).splitlines():
            map_id, encounter_id, name = line.split('\t', 2)
            actual.setdefault(int(map_id), []).append((int(encounter_id), name))
        self.assertEqual(set(actual), set(verified))
        declared = {row['instanceID']: row for row in report['included_dungeons']}
        self.assertEqual(set(declared), set(verified))
        self.assertEqual(len(declared), len(report['included_dungeons']))
        known_global = set()
        for map_id, encounters in actual.items():
            with self.subTest(instance=map_id):
                self.assertEqual(verified[map_id]['type'], 1)
                self.assertEqual(verified[map_id]['difficultyID'], 1)
                static = {row['encounterID']: row for row in verified[map_id]['encounters']}
                ids = [encounter_id for encounter_id, _ in encounters]
                self.assertEqual(ids, declared[map_id]['encounterIDs'])
                self.assertEqual(len(ids), len(set(ids)))
                self.assertFalse(set(ids) & known_global)
                known_global.update(ids)
                exclusions = {x.get('encounterID') for x in declared[map_id].get('excluded_encounters', [])}
                self.assertFalse(set(ids) & exclusions)
                self.assertLessEqual(set(static) - set(ids), exclusions,
                                     'Every omitted readable Normal-compatible event needs an explicit disposition')
                for encounter_id, name in encounters:
                    self.assertEqual(name, static[encounter_id]['name'])
                    self.assertIn(static[encounter_id]['tableDifficultyID'], (0, 1))


if __name__ == '__main__':
    unittest.main()
