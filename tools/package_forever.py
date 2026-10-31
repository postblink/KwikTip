#!/usr/bin/env python3
"""Build a local, data-isolated KwikTip package for WoW Forever.

This deliberately does not publish or install the package. Output must be a new
path so existing addon installs or build artifacts are never overwritten.
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE_NAME = "KwikTip_Forever"
SHARED_FILES = (
    "Init.lua",
    "Core.lua",
    "Frames.lua",
    "UI_Config.lua",
    "Locale/enUS.lua",
    "Locale/Locales.lua",
    "Locale/deDE.lua",
)
FOREVER_FILES = {
    "KwikTip_Forever.toc": "KwikTip_Forever.toc",
    "DungeonData.lua": "DungeonData.lua",
    "RuntimeIndexes.lua": "RuntimeIndexes.lua",
    "Flavor.lua": "Flavor.lua",
    "Locale/tips.lua": "Locale/tips.lua",
    "README.txt": "README.txt",
}
ASSETS = ("ktmini.tga", "ktlogo.tga")


def build(output: Path) -> Path:
    output = output.expanduser().resolve()
    if output.exists():
        raise FileExistsError(f"Refusing to overwrite existing output: {output}")

    package = output / PACKAGE_NAME
    package.mkdir(parents=True)
    for source, relative in FOREVER_FILES.items():
        destination = package / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / "Forever" / source, destination)

    for relative in SHARED_FILES:
        destination = package / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, destination)

    # Adapt only the packaged copy; Retail source and its asset paths stay intact.
    config = package / "UI_Config.lua"
    source = config.read_text(encoding="utf-8")
    retail_prefix = r"Interface\\AddOns\\KwikTip\\assets\\"
    forever_prefix = rf"Interface\\AddOns\\{PACKAGE_NAME}\\assets\\"
    if source.count(retail_prefix) != 3:
        raise ValueError("Shared UI asset references changed; review Forever adaptation")
    config.write_text(source.replace(retail_prefix, forever_prefix), encoding="utf-8")
    (package / "assets").mkdir()
    for asset in ASSETS:
        shutil.copy2(ROOT / "assets" / asset, package / "assets" / asset)
    shutil.copy2(ROOT / "LICENSE", package / "LICENSE")

    return package


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="new directory to create the package in")
    args = parser.parse_args()
    package = build(args.output)
    print(package)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
