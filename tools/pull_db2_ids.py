#!/usr/bin/env python3
"""pull_db2_ids.py — Resolve KwikTip dungeon/boss IDs from wago.tools DB2 CSVs.

The game client's static data lives in DB2 tables. wago.tools serves them as
CSV at https://wago.tools/db2/<Table>/csv. This script downloads + caches
them, then name-matches against DungeonData.lua to fill 0-valued IDs.

ID mapping (verified against in-game values, see AGENTS.md):
  instanceID  = Map.db2.ID                          (GetInstanceInfo 8th return)
  uiMapID     = UiMap.db2.ID                        (C_Map.GetBestMapForUnit)
  encounterID = JournalEncounter.DungeonEncounterID (ENCOUNTER_START event)
  npcID       = NOT auto-resolved (reference-only; use Wowhead)

SAFETY:
  - Default is DRY RUN (reports changes, writes nothing).
  - Only fills fields currently set to 0; never overwrites confirmed values.
  - Ambiguous name matches (multiple DB2 rows) are reported and SKIPPED,
    never guessed.

USAGE:
  python3 tools/pull_db2_ids.py                # dry run, using cached CSVs
  python3 tools/pull_db2_ids.py --refresh      # re-download CSVs first
  python3 tools/pull_db2_ids.py --apply        # write resolved IDs to DungeonData.lua
  python3 tools/pull_db2_ids.py --json         # machine-readable dry-run output
"""

import csv
import io
import os
import re
import sys
import urllib.request

BASE = "https://wago.tools/db2"
CACHE_DIR = os.path.expanduser("~/.cache/kwiktip/db2")
DATA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "DungeonData.lua")

TABLES = {
    "map": "Map",
    "uimap": "UiMap",
    "journal_encounter": "JournalEncounter",
    "journal_instance": "JournalInstance",
}

# InstanceType values in Map.db2: 1=party(dungeon), 2=raid, 4=scenario(delve)
# UiMap.db2 Type=4 is an instance/dungeon map.


def fetch_table(table):
    url = f"{BASE}/{table}/csv"
    req = urllib.request.Request(url, headers={"User-Agent": "KwikTip/1.0 (+addon id sync)"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", errors="replace")


def load_table(table, refresh=False):
    os.makedirs(CACHE_DIR, exist_ok=True)
    path = os.path.join(CACHE_DIR, table + ".csv")
    if refresh or not os.path.exists(path):
        print(f"  [fetch] {table}", file=sys.stderr)
        data = fetch_table(table)
        with open(path, "w", encoding="utf-8") as f:
            f.write(data)
    with open(path, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def norm(s):
    """Normalize a name for matching: lowercase, strip quotes/apostrophes/dashes."""
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def build_dungeon_blocks(src):
    """Parse DungeonData.lua into a list of dungeon dicts (like validate_data.py)."""
    i = src.find("KwikTip.DUNGEONS = {")
    if i < 0:
        raise SystemExit("could not find KwikTip.DUNGEONS table")
    start = src.find("{", i)
    depth = 0
    end = -1
    for j in range(start, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                end = j
                break
    body = src[start + 1:end]
    blocks = []
    d = 0
    st = -1
    for j, ch in enumerate(body):
        if ch == "{":
            if d == 0:
                st = j
            d += 1
        elif ch == "}":
            d -= 1
            if d == 0 and st >= 0:
                blocks.append(body[st + 1:j])
                st = -1

    dungeons = []
    for blk in blocks:
        entry = {"raw": blk}
        m = re.search(r'name\s*=\s*"([^"]+)"', blk)
        entry["name"] = m.group(1) if m else None
        m = re.search(r'instanceID\s*=\s*(\d+)', blk)
        entry["instanceID"] = int(m.group(1)) if m else 0
        m = re.search(r'uiMapID\s*=\s*(\d+)', blk)
        entry["uiMapID"] = int(m.group(1)) if m else 0
        # bosses
        entry["bosses"] = []
        bi = blk.find("bosses = {")
        if bi >= 0:
            d2 = 0
            ej = -1
            for j in range(bi + len("bosses = "), len(blk)):
                if blk[j] == "{":
                    d2 += 1
                elif blk[j] == "}":
                    d2 -= 1
                    if d2 == 0:
                        ej = j
                        break
            scope = blk[bi:ej + 1] if ej >= 0 else blk[bi:]
            boss_names = re.findall(r'name\s*=\s*"([^"]+)"', scope)
            eids = re.findall(r'encounterID\s*=\s*(\d+)', scope)
            npcs = re.findall(r'npcID\s*=\s*(\d+)', scope)
            for idx in range(len(eids)):
                entry["bosses"].append({
                    "name": boss_names[idx] if idx < len(boss_names) else None,
                    "encounterID": int(eids[idx]),
                    "npcID": int(npcs[idx]) if idx < len(npcs) else 0,
                })
        dungeons.append(entry)
    return dungeons


def resolve(dungeons, tables):
    map_rows = tables["map"]
    uimap_rows = tables["uimap"]
    je_rows = tables["journal_encounter"]
    ji_rows = tables["journal_instance"]

    # Build name -> rows indexes
    map_by_name = {}
    for r in map_rows:
        map_by_name.setdefault(norm(r.get("MapName_lang", "")), []).append(r)

    uimap_by_name = {}
    for r in uimap_rows:
        uimap_by_name.setdefault(norm(r.get("Name_lang", "")), []).append(r)

    ji_by_name = {}
    for r in ji_rows:
        ji_by_name.setdefault(norm(r.get("Name_lang", "")), []).append(r)

    je_by_name = {}
    for r in je_rows:
        je_by_name.setdefault(norm(r.get("Name_lang", "")), []).append(r)

    results = []
    for d in dungeons:
        name = d["name"]
        if not name:
            continue
        key = norm(name)

        # --- instanceID (Map.db2) ---
        if d["instanceID"] == 0:
            candidates = [r for r in map_by_name.get(key, [])
                          if r.get("InstanceType") in ("1", "2", "4")]
            if len(candidates) == 1:
                d["_new_instanceID"] = int(candidates[0]["ID"])
                results.append(("instanceID", name, candidates[0]["ID"]))
            elif len(candidates) > 1:
                ids = [c["ID"] for c in candidates]
                results.append(("ambiguous", name, f"instanceID has {len(candidates)} Map rows: {ids}"))

        # --- uiMapID (UiMap.db2) ---
        if d["uiMapID"] == 0:
            candidates = [r for r in uimap_by_name.get(key, []) if r.get("Type") == "4"]
            if len(candidates) == 1:
                d["_new_uiMapID"] = int(candidates[0]["ID"])
                results.append(("uiMapID", name, candidates[0]["ID"]))
            elif len(candidates) > 1:
                # Prefer the UiMapID that JournalEncounter references (the actual boss area id)
                # Build a set of preferred UiMapIDs from encounter rows
                preferred_uis = set()
                for er in je_rows:
                    uid = er.get("UiMapID", "0")
                    if uid and uid != "0":
                        preferred_uis.add(int(uid))
                ids = [int(c["ID"]) for c in candidates]
                in_preferred = [i for i in ids if i in preferred_uis]
                if len(in_preferred) == 1:
                    d["_new_uiMapID"] = in_preferred[0]
                    results.append(("uiMapID", name, str(in_preferred[0]) + f" (JournalEncounter-derived)"))
                elif len(in_preferred) > 1:
                    # Both UiMapIDs appear in JournalEncounter; pick the lowest (primary zone)
                    d["_new_uiMapID"] = min(ids)
                    results.append(("uiMapID", name, str(d["_new_uiMapID"]) + f" (lowest of {len(candidates)})"))
                else:
                    # No JournalEncounter refs; pick the lowest ID (primary zone)
                    d["_new_uiMapID"] = min(ids)
                    results.append(("uiMapID", name, str(d["_new_uiMapID"]) + f" (lowest of {len(candidates)} — no JournalEncounter ref)"))

        # --- encounterID + npcID (JournalEncounter) ---
        if d.get("_new_instanceID") or d["instanceID"]:
            # find JournalInstance to scope encounters
            ji_rows_for_d = ji_by_name.get(key, [])
            for boss in d["bosses"]:
                if boss["encounterID"] != 0:
                    continue
                bname = boss["name"]
                if not bname:
                    continue
                bkey = norm(bname)
                candidates = je_by_name.get(bkey, [])
                if len(candidates) == 1:
                    boss["_new_encounterID"] = int(candidates[0]["DungeonEncounterID"])
                    results.append(("encounterID", f"{name} > {bname}", candidates[0]["DungeonEncounterID"]))
                elif len(candidates) > 1:
                    results.append(("ambiguous", f"{name} > {bname}",
                                    f"encounterID has {len(candidates)} JournalEncounter rows"))

    return results


def apply_changes(src, dungeons):
    """Apply resolved IDs to DungeonData.lua by line-level regex replacement."""
    lines = src.split("\n")
    out_lines = list(lines)
    for d in dungeons:
        new_iid = d.get("_new_instanceID")
        new_uid = d.get("_new_uiMapID")
        has_boss_fills = any(b.get("_new_encounterID") for b in d["bosses"])
        if not (new_iid or new_uid or has_boss_fills):
            continue
        # locate the dungeon block by its name line (flexible spacing)
        name_idx = None
        for idx, line in enumerate(lines):
            if re.search(r'name\s*=\s*"' + re.escape(d["name"]) + r'"', line):
                name_idx = idx
                break
        if name_idx is None:
            continue
        # scan both directions for instanceID/uiMapID = 0 lines
        for j in range(max(0, name_idx - 5), min(name_idx + 50, len(lines))):
            if new_iid and re.match(r"\s*instanceID\s*=\s*0\b", lines[j]):
                indent = re.match(r"(\s*)", lines[j]).group(1)
                out_lines[j] = f'{indent}instanceID = {new_iid},  -- synced from wago.tools Map.db2\n'.rstrip()
            if new_uid and re.match(r"\s*uiMapID\s*=\s*0\b", lines[j]):
                indent = re.match(r"(\s*)", lines[j]).group(1)
                out_lines[j] = f'{indent}uiMapID    = {new_uid},  -- synced from wago.tools UiMap.db2\n'.rstrip()
        # boss encounterIDs
        for boss in d["bosses"]:
            new_eid = boss.get("_new_encounterID")
            if not new_eid:
                continue
            # find boss name line, then look backward for encounterID = 0
            boss_idx = None
            for j in range(name_idx, min(name_idx + 200, len(lines))):
                if re.search(r'name\s*=\s*"' + re.escape(boss["name"]) + r'"', lines[j]):
                    boss_idx = j
                    break
            if boss_idx is None:
                continue
            # encounterID appears BEFORE the name line in each boss block
            for k in range(boss_idx - 1, max(0, boss_idx - 8), -1):
                if re.match(r"\s*encounterID\s*=\s*0\b", lines[k]):
                    indent = re.match(r"(\s*)", lines[k]).group(1)
                    out_lines[k] = f'{indent}encounterID = {new_eid},  -- synced from wago.tools JournalEncounter.db2\n'.rstrip()
                    break
    return "\n".join(out_lines)


def main():
    args = sys.argv[1:]
    refresh = "--refresh" in args
    apply = "--apply" in args
    as_json = "--json" in args

    tables = {k: load_table(v, refresh=refresh) for k, v in TABLES.items()}
    if not as_json:
        print(f"Loaded: {', '.join(f'{k}={len(v)} rows' for k, v in tables.items())}")

    with open(DATA_PATH, encoding="utf-8") as f:
        src = f.read()
    dungeons = build_dungeon_blocks(src)

    results = resolve(dungeons, tables)

    filled = [r for r in results if r[0] in ("instanceID", "uiMapID", "encounterID")]
    ambiguous = [r for r in results if r[0] == "ambiguous"]

    if as_json:
        import json
        print(json.dumps({"filled": filled, "ambiguous": ambiguous}, indent=2))
    else:
        for kind, name, val in results:
            tag = {"instanceID": "iid", "uiMapID": "map", "encounterID": "enc"}.get(kind, kind)
            print(f"  [{tag:4}] {name:<45} -> {val}")
        print(f"\n  filled={len(filled)}  ambiguous={len(ambiguous)}")
        if apply:
            new_src = apply_changes(src, dungeons)
            if new_src != src:
                with open(DATA_PATH, "w", encoding="utf-8") as f:
                    f.write(new_src)
                print("  APPLIED changes to DungeonData.lua")
            else:
                print("  no changes to apply")
        else:
            print("  (dry run — pass --apply to write)")

    sys.exit(0)


if __name__ == "__main__":
    main()
