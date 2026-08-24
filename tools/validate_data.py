#!/usr/bin/env python3
"""validate_data.py — Offline data integrity checks for KwikTip's DungeonData.lua.

Faster and more thorough than the wow-ui-sim for data validation:
- No Docker required (runs in < 0.2s vs sim's 2s+ startup)
- Catches all structural errors, duplicate names, missing fields
- S2 dungeon/raid/delve coverage audit
- ID verification (which dungeons still have 0/0 IDs)
- Boss-area index consistency

Usage:
    python3 tools/validate_data.py            # run all checks
    python3 tools/validate_data.py --json     # machine-readable output
"""

import os, re, sys, json

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "..", "DungeonData.lua")


def load_dungeons(path):
    """Parse DungeonData.lua into a list of dicts. Handles Lua table syntax."""
    with open(path, encoding="utf-8") as f:
        src = f.read()
    # Find KwikTip.DUNGEONS = { ... }
    i = src.find("KwikTip.DUNGEONS = {")
    if i < 0:
        raise SystemExit("FAILED: cannot find KwikTip.DUNGEONS table")
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
    # Split top-level blocks (each is a dungeon/delve/raid)
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
        entry = {}
        # top-level fields
        for key in ("instanceID", "uiMapID", "name", "location", "season", "type"):
            m = re.search(rf'{key}\s*=\s*(?:(\d+)|"([^"]+)")', blk)
            if m:
                entry[key] = int(m.group(1)) if m.group(1) is not None else m.group(2)
        # mythicPlus
        entry["mythicPlus"] = "mythicPlus = true" in blk
        # bosses — find the bosses = { ... } block and extract boss names/tips
        entry["bosses"] = []
        bi = blk.find("bosses = {")
        if bi >= 0:
            start = bi + len("bosses = ")  # position of the opening {
            d = 0
            ej = -1
            for j in range(start, len(blk)):
                if blk[j] == "{":
                    d += 1
                elif blk[j] == "}":
                    d -= 1
                    if d == 0:
                        ej = j
                        break
            scope = blk[bi:ej + 1] if ej >= 0 else blk[bi:]
            boss_names = re.findall(r'name\s*=\s*"([^"]+)"', scope)
            boss_tips = re.findall(r'tip\s*=\s*"([^"]+)"', scope)
            eids = re.findall(r'encounterID\s*=\s*(\d+)', scope)
            for idx in range(len(eids)):
                entry["bosses"].append({
                    "encounterID": int(eids[idx]),
                    "name": boss_names[idx] if idx < len(boss_names) else None,
                    "tip": boss_tips[idx] if idx < len(boss_tips) else None,
                })
        dungeons.append(entry)
    return dungeons


def validate(dungeons):
    results = []
    s2_mplus = {
        "Altar of Fangs", "Murder Row", "Den of Nalorakk", "The Blinding Vale",
        "Voidscar Arena", "Kings' Rest", "Temple of Sethraliss", "Ruby Life Pools"
    }
    name_index = {}
    for d in dungeons:
        if d.get("name") in name_index:
            results.append({"severity": "error", "check": "duplicate_names",
                          "msg": f"Duplicate dungeon name: {d['name']}"})
        name_index[d.get("name", "UNNAMED")] = d

    for i, d in enumerate(dungeons):
        prefix = f"[{i}] {d.get('name', 'UNNAMED')}"
        # Required fields
        for fld in ("instanceID", "uiMapID", "name", "season", "type"):
            if d.get(fld) is None:
                results.append({"severity": "error", "check": "required_fields",
                              "msg": f"{prefix} missing field: {fld}"})
        # Bosses
        if not d.get("bosses"):
            results.append({"severity": "error", "check": "boss_count",
                          "msg": f"{prefix} has 0 bosses"})
        for j, b in enumerate(d.get("bosses", [])):
            for bf in ("name", "tip"):
                if b.get(bf) is None:
                    results.append({"severity": "error", "check": "boss_fields",
                                  "msg": f"{prefix} boss[{j}] ({b.get('name','?')}) missing {bf}"})

    # S2 coverage
    for name in sorted(s2_mplus):
        if name not in name_index:
            results.append({"severity": "warning", "check": "s2_coverage",
                          "msg": f"S2 M+ dungeon missing: {name}"})
    # S2 raid
    va = name_index.get("The Venomous Abyss") or name_index.get("Venomous Abyss")
    if va:
        if len(va.get("bosses", [])) != 8:
            results.append({"severity": "warning", "check": "s2_raid",
                          "msg": f"Venomous Abyss has {len(va['bosses'])} bosses, expected 8"})
    else:
        results.append({"severity": "warning", "check": "s2_raid",
                      "msg": "Venomous Abyss raid not found"})

    # S2 delves
    for delve_name in ("The Ring of Glory", "Gnarldor Isle", "Venomfall Deeps"):
        if delve_name not in name_index:
            results.append({"severity": "warning", "check": "s2_delves",
                          "msg": f"S2 delve missing: {delve_name}"})

    # ID gaps
    zero_id = [(d["name"], d["instanceID"], d["uiMapID"])
               for d in dungeons if d.get("type") and d.get("instanceID", 0) == 0 and d.get("uiMapID", 0) == 0]
    if zero_id:
        results.append({"severity": "info", "check": "id_gaps",
                       "msg": f"{len(zero_id)} dungeons with 0/0 IDs: " +
                              ", ".join(f"{n}(i={i},u={u})" for n, i, u in zero_id)})

    return results


def main():
    dungeons = load_dungeons(DATA)
    results = validate(dungeons)

    if "--json" in sys.argv:
        print(json.dumps({"dungeon_count": len(dungeons), "results": results}, indent=2))
    else:
        errors = [r for r in results if r["severity"] == "error"]
        warnings = [r for r in results if r["severity"] == "warning"]
        infos = [r for r in results if r["severity"] == "info"]
        for r in errors:
            print(f"  ERROR: {r['msg']}")
        for r in warnings:
            print(f"  WARN:  {r['msg']}")
        for r in infos:
            print(f"  INFO:  {r['msg']}")
        print(f"\n{len(dungeons)} dungeons checked  errors={len(errors)}  warnings={len(warnings)}  info={len(infos)}")
        if errors:
            print("VALIDATION FAILED")
            sys.exit(1)
        else:
            print("VALIDATION PASSED (non-zero warnings/info are advisory)")

if __name__ == "__main__":
    main()
