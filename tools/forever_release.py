#!/usr/bin/env python3
"""Prepare isolated Forever release assets locally; never publish or install."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import zipfile

import package_forever

ROOT = Path(__file__).resolve().parents[1]
VERSION_PATTERN = r"[0-9]+\.[0-9]+\.[0-9]+-(?:test(?:\.[0-9]+)?|alpha\.[0-9]+)"
ALPHA_TAG_PATTERN = r"forever-v([0-9]+\.[0-9]+\.[0-9]+-alpha\.[0-9]+)"


def metadata() -> tuple[str, int]:
    toc = (ROOT / "Forever/KwikTip_Forever.toc").read_text(encoding="utf-8")
    versions = re.findall(r"(?m)^## Version: (.+)$", toc)
    interfaces = re.findall(r"(?m)^## Interface: ([0-9]+)$", toc)
    if len(versions) != 1 or re.fullmatch(VERSION_PATTERN, versions[0]) is None:
        raise ValueError("Forever TOC needs one safe test/alpha version")
    if interfaces != ["16001"]:
        raise ValueError("Forever interface changed; review its flavor mapping before release")
    first_line = (ROOT / "Forever/README.txt").read_text(encoding="utf-8").splitlines()[0]
    if not first_line.startswith(f"KwikTip Forever {versions[0]} --"):
        raise ValueError("Packaged README must identify the same Forever version as the TOC")
    return versions[0], int(interfaces[0])


def validate_tag(tag: str, version: str) -> None:
    match = re.fullmatch(ALPHA_TAG_PATTERN, tag)
    if match is None or match.group(1) != version:
        raise ValueError("Release tag must be forever-v<TOC version>, with an alpha.N version")


def prepare(output: Path, tag: str | None = None) -> dict[str, str]:
    version, interface = metadata()
    if tag is not None:
        validate_tag(tag, version)
    output = output.expanduser().resolve()
    if output.exists():
        raise FileExistsError(f"Refusing to overwrite release output: {output}")
    package = package_forever.build(output / "package")
    expected = (set(package_forever.SHARED_FILES) | set(package_forever.FOREVER_FILES.values())
                | {f"assets/{name}" for name in package_forever.ASSETS} | {"LICENSE"})
    files = sorted(p for p in package.rglob("*") if p.is_file())
    actual = {p.relative_to(package).as_posix() for p in files}
    if actual != expected or any(p.is_symlink() for p in package.rglob("*")):
        raise ValueError("Forever package must contain only its explicit standalone file list")
    archive_name = f"KwikTip_Forever-{version}.zip"
    with zipfile.ZipFile(output / archive_name, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, "KwikTip_Forever/" + path.relative_to(package).as_posix())
    # Match the official BigWigs GitHub release-asset metadata contract.
    release = {"releases": [{
        "name": "KwikTip: Forever", "version": version, "filename": archive_name,
        "nolib": False, "metadata": [{"flavor": "forever", "interface": interface}],
    }]}
    (output / "release.json").write_text(json.dumps(release, indent=2) + "\n", encoding="utf-8")
    notes = (ROOT / "Forever/RELEASE_NOTES.txt").read_text(encoding="utf-8")
    (output / "release-notes.md").write_text(notes.replace("@VERSION@", version), encoding="utf-8")
    shutil.copy2(ROOT / "docs/FOREVER_HALL_OF_THANES_IDS_70707.json", output / "source-evidence.json")
    assets = [archive_name, "release.json", "release-notes.md", "source-evidence.json"]
    checksums = [f"{hashlib.sha256((output / name).read_bytes()).hexdigest()}  {name}\n" for name in assets]
    (output / "SHA256SUMS").write_text("".join(checksums), encoding="utf-8")
    return {"version": version, "archive_name": archive_name}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--tag", help="validate a publishing alpha tag; omitted for local/PR builds")
    parser.add_argument("--github-output", type=Path)
    args = parser.parse_args()
    result = prepare(args.output, args.tag)
    if args.github_output:
        with args.github_output.open("a", encoding="utf-8") as stream:
            for key, value in result.items():
                stream.write(f"{key}={value}\n")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
