#!/usr/bin/env python3
"""Upload verified Forever alpha bytes to existing pages only with --publish.

Payload contracts match the pinned BigWigs packager; exact Forever versions are
required instead of falling back to another patch or game flavor. No retries.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import HTTPRedirectHandler, Request, build_opener
import uuid

from forever_release import validate_tag

CF_PROJECT = "1478824"
WAGO_PROJECT = "QN53W7KB"
PATCH = "1.60.1"
CF_FOREVER_TYPE = 88568


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, newurl):
        return None


def open_request(request):
    # Upload credentials stay on the explicitly named provider endpoint.
    return build_opener(NoRedirect()).open(request, timeout=60)


def payloads(cf_versions: list, wago_game: dict, version: str, notes: str) -> tuple[dict, dict]:
    matches = [row["id"] for row in cf_versions
               if row.get("gameVersionTypeID") == CF_FOREVER_TYPE and row.get("name") == PATCH]
    if len(matches) != 1 or not isinstance(matches[0], int) or isinstance(matches[0], bool) or matches[0] <= 0:
        raise ValueError("Need one exact CurseForge Forever patch ID; no fallback is allowed")
    patches = wago_game.get("patches", {}).get("forever", [])
    if not isinstance(patches, list) or PATCH not in patches:
        raise ValueError("Wago must explicitly support the exact Forever patch")
    label = f"KwikTip Forever {version}"
    return (
        {"displayName": label, "gameVersions": matches, "releaseType": "alpha",
         "changelog": notes, "changelogType": "markdown"},
        {"label": label, "supported_forever_patches": [PATCH],
         "stability": "alpha", "changelog": notes},
    )


def verified_inputs(directory: Path, tag: str) -> tuple[str, Path, str]:
    metadata = json.loads((directory / "release.json").read_text())["releases"]
    if len(metadata) != 1:
        raise ValueError("Expected one isolated Forever release")
    item = metadata[0]
    version = item["version"]
    validate_tag(tag, version)
    archive = f"KwikTip_Forever-{version}.zip"
    if item["filename"] != archive or item["metadata"] != [{"flavor": "forever", "interface": 16001}]:
        raise ValueError("Only the declared Forever archive/interface may be uploaded")
    expected = {archive, "release.json", "release-notes.md", "source-evidence.json"}
    seen = set()
    for line in (directory / "SHA256SUMS").read_text().splitlines():
        digest, name = line.split("  ", 1)
        if name not in expected or name in seen:
            raise ValueError("Unexpected or duplicate checksum path")
        if hashlib.sha256((directory / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f"Checksum failed: {name}")
        seen.add(name)
    if seen != expected:
        raise ValueError("Missing verified publication asset")
    return version, directory / archive, (directory / "release-notes.md").read_text()


def fetch_json(url: str, headers: dict) -> dict | list:
    with open_request(Request(url, headers=headers)) as response:
        return json.load(response)


def upload(url: str, headers: dict, metadata: dict, archive: Path) -> None:
    boundary = "kwiktip-" + uuid.uuid4().hex
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"metadata\"\r\n"
        "Content-Type: application/json\r\n\r\n"
    ).encode() + json.dumps(metadata).encode() + (
        f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{archive.name}\"\r\n"
        "Content-Type: application/zip\r\n\r\n"
    ).encode() + archive.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    request = Request(url, data=body, headers={**headers, "Content-Type": f"multipart/form-data; boundary={boundary}"}, method="POST")
    with open_request(request) as response:
        if response.status not in (200, 201):
            raise ValueError(f"Upload returned HTTP {response.status}")


def publish(directory: Path, tag: str) -> None:
    version, archive, notes = verified_inputs(directory, tag)
    cf_token, wago_token = os.environ.get("CF_API_KEY"), os.environ.get("WAGO_API_TOKEN")
    if not cf_token or not wago_token:
        raise ValueError("CF_API_KEY and WAGO_API_TOKEN must both be available; nothing uploaded")
    cf_headers = {"x-api-token": cf_token}
    wago_headers = {"authorization": f"Bearer {wago_token}", "accept": "application/json"}
    cf_versions = fetch_json("https://wow.curseforge.com/api/game/wow/versions", cf_headers)
    wago_game = fetch_json("https://addons.wago.io/api/data/game", {})
    cf_payload, wago_payload = payloads(cf_versions, wago_game, version, notes)
    # Complete all validation before the first POST. A later failure can still
    # leave a partial publication; do not automatically retry either upload.
    upload(f"https://wow.curseforge.com/api/projects/{CF_PROJECT}/upload-file", cf_headers, cf_payload, archive)
    print(f"CurseForge project {CF_PROJECT}: Forever alpha upload succeeded", flush=True)
    upload(f"https://addons.wago.io/api/projects/{WAGO_PROJECT}/version", wago_headers, wago_payload, archive)
    print(f"Wago project {WAGO_PROJECT}: Forever alpha upload succeeded", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--publish", action="store_true", help="perform actual uploads; omit for verified no-network plan")
    args = parser.parse_args()
    try:
        if args.publish:
            publish(args.directory, args.tag)
        else:
            version, _, _ = verified_inputs(args.directory, args.tag)
            print(json.dumps({"version": version, "flavor": "forever", "curseforge": CF_PROJECT,
                              "wago": WAGO_PROJECT, "wowinterface": "disabled", "uploaded": False}))
    except HTTPError as error:
        raise SystemExit(f"Marketplace request failed (HTTP {error.code}); inspect partial outcomes before retrying") from None


if __name__ == "__main__":
    main()
