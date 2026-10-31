from pathlib import Path
import json
import os
import unittest
from unittest.mock import patch

from test_forever_release import alpha_source
import forever_release
import forever_marketplaces as markets


VERSIONS = [{"id": 999001, "name": "1.60.1", "gameVersionTypeID": 88568},
            {"id": 999002, "name": "12.1.0", "gameVersionTypeID": 517}]
WAGO = {"patches": {"forever": ["1.60.1"], "retail": ["12.1.0"]}}


class ForeverMarketplaceTests(unittest.TestCase):
    def test_existing_project_ids_and_flavor_specific_payloads(self):
        self.assertEqual(markets.CF_PROJECT, "1478824")
        self.assertEqual(markets.WAGO_PROJECT, "QN53W7KB")
        cf, wago = markets.payloads(VERSIONS, WAGO, "0.1.0-alpha.1", "coverage notes")
        self.assertEqual(cf["gameVersions"], [999001])
        self.assertEqual(cf["releaseType"], "alpha")
        self.assertEqual(wago["supported_forever_patches"], ["1.60.1"])
        self.assertEqual(wago["stability"], "alpha")
        self.assertNotIn("supported_retail_patches", wago)

    def test_no_patch_or_game_flavor_fallback(self):
        for versions, game in [
            (VERSIONS[1:], WAGO), (VERSIONS + VERSIONS[:1], WAGO),
            ([{"id": 1, "name": "1.60.0", "gameVersionTypeID": 88568}], WAGO),
            (VERSIONS, {"patches": {"retail": ["1.60.1"]}}),
            (VERSIONS, {"patches": {"forever": "1.60.1"}}),
        ]:
            with self.subTest(versions=versions, game=game), self.assertRaises(ValueError):
                markets.payloads(versions, game, "0.1.0-alpha.1", "notes")

    def test_publish_validates_everything_before_posting_same_verified_zip(self):
        with alpha_source() as root, patch("builtins.print"):
            directory = root.parent / "dist"
            forever_release.prepare(directory, "forever-v0.1.0-alpha.1")
            with patch.dict(os.environ, {"CF_API_KEY": "test-cf", "WAGO_API_TOKEN": "test-wago"}, clear=True), \
                    patch.object(markets, "fetch_json", side_effect=[VERSIONS, WAGO]), \
                    patch.object(markets, "upload") as upload:
                markets.publish(directory, "forever-v0.1.0-alpha.1")
                self.assertEqual(upload.call_count, 2)
                first, second = upload.call_args_list
                self.assertEqual(first.args[0], "https://wow.curseforge.com/api/projects/1478824/upload-file")
                self.assertEqual(second.args[0], "https://addons.wago.io/api/projects/QN53W7KB/version")
                self.assertEqual(first.args[3], second.args[3])
            with patch.dict(os.environ, {"CF_API_KEY": "test-cf", "WAGO_API_TOKEN": "test-wago"}, clear=True), \
                    patch.object(markets, "fetch_json", side_effect=[VERSIONS, {"patches": {}}]), \
                    patch.object(markets, "upload") as upload:
                with self.assertRaises(ValueError):
                    markets.publish(directory, "forever-v0.1.0-alpha.1")
                upload.assert_not_called()
            with patch.dict(os.environ, {}, clear=True), patch.object(markets, "fetch_json") as fetch:
                with self.assertRaises(ValueError):
                    markets.publish(directory, "forever-v0.1.0-alpha.1")
                fetch.assert_not_called()

    def test_tampered_assets_and_retail_tags_cannot_upload(self):
        with alpha_source() as root:
            directory = root.parent / "dist"
            forever_release.prepare(directory, "forever-v0.1.0-alpha.1")
            with patch.object(markets, "fetch_json") as fetch:
                with self.assertRaises(ValueError):
                    markets.publish(directory, "v3.5.0")
                (directory / "release-notes.md").write_text("changed")
                with self.assertRaises(ValueError):
                    markets.publish(directory, "forever-v0.1.0-alpha.1")
                fetch.assert_not_called()

    def test_multipart_contract_and_redirects(self):
        with alpha_source() as root:
            archive = root / "sample.zip"
            archive.write_bytes(b"verified zip bytes")
            with patch.object(markets, "open_request") as request:
                request.return_value.__enter__.return_value.status = 201
                markets.upload("https://addons.wago.io/api/projects/QN53W7KB/version", {}, {"stability": "alpha"}, archive)
                sent = request.call_args.args[0]
                self.assertEqual(sent.get_method(), "POST")
                self.assertIn(b'name="metadata"', sent.data)
                self.assertIn(b'name="file"; filename="sample.zip"', sent.data)
                self.assertIn(archive.read_bytes(), sent.data)
            self.assertIsNone(markets.NoRedirect().redirect_request(None, None, 302, "redirect", {}, "https://other.example"))


if __name__ == "__main__":
    unittest.main()
