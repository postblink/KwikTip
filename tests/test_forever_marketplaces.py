from pathlib import Path
from contextlib import contextmanager
import io
import json
import os
import sys
import unittest
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError

from test_forever_release import alpha_source
import forever_release
import forever_marketplaces as markets


VERSIONS = [{"id": 999001, "name": "1.60.1", "gameVersionTypeID": 88568},
            {"id": 999002, "name": "12.1.0", "gameVersionTypeID": 517}]
WAGO = {"patches": {"forever": ["1.60.1"], "retail": ["12.1.0"]}}
TAG = "forever-v0.1.0-alpha.1"


def response(body, status=200):
    result = io.BytesIO(body if isinstance(body, bytes) else json.dumps(body).encode())
    result.status = status
    return result


@contextmanager
def prepared_release():
    with alpha_source() as root:
        directory = root.parent / "dist"
        forever_release.prepare(directory, TAG)
        yield directory


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
                request.return_value = response({"id": "file_123"}, 201)
                receipt = markets.upload("https://addons.wago.io/api/projects/QN53W7KB/version", {}, {"stability": "alpha"}, archive)
                self.assertEqual(receipt, "file_123")
                sent = request.call_args.args[0]
                self.assertEqual(sent.get_method(), "POST")
                self.assertIn(b'name="metadata"', sent.data)
                self.assertIn(b'name="file"; filename="sample.zip"', sent.data)
                self.assertIn(archive.read_bytes(), sent.data)
            self.assertIsNone(markets.NoRedirect().redirect_request(None, None, 302, "redirect", {}, "https://other.example"))

    def test_truthful_user_agent_is_on_actual_get_and_post_requests(self):
        with prepared_release() as directory, \
                patch.dict(os.environ, {"WAGO_API_TOKEN": "test-wago"}, clear=True), \
                patch.object(markets, "build_opener") as build, patch("builtins.print"):
            opener = build.return_value
            opener.open.side_effect = [response(WAGO), response({"id": 123}, 201)]
            markets.publish(directory, TAG, provider="wago")
            requests = [call.args[0] for call in opener.open.call_args_list]
            self.assertEqual([request.get_method() for request in requests], ["GET", "POST"])
            for request in requests:
                headers = {key.lower(): value for key, value in request.header_items()}
                self.assertEqual(headers["user-agent"], markets.USER_AGENT)
                self.assertIn("KwikTip", headers["user-agent"])
                self.assertIn("github.com/postblink/KwikTip", headers["user-agent"])
                self.assertNotIn("Mozilla", headers["user-agent"])
                self.assertNotIn("Python-urllib", headers["user-agent"])
            for call in build.call_args_list:
                self.assertEqual(len(call.args), 1)
                self.assertIsInstance(call.args[0], markets.NoRedirect)
            for call in opener.open.call_args_list:
                self.assertEqual(call.kwargs, {"timeout": 60})

    def test_get_only_preflight_never_posts(self):
        with prepared_release() as directory, \
                patch.dict(os.environ, {"CF_API_KEY": "test-cf", "WAGO_API_TOKEN": "test-wago"}, clear=True), \
                patch.object(markets, "build_opener") as build, patch("builtins.print"):
            opener = build.return_value
            opener.open.side_effect = [response(VERSIONS), response(WAGO)]
            markets.publish(directory, TAG, preflight_only=True)
            requests = [call.args[0] for call in opener.open.call_args_list]
            self.assertEqual([request.get_method() for request in requests], ["GET", "GET"])
            self.assertEqual([request.full_url for request in requests], [
                "https://wow.curseforge.com/api/game/wow/versions",
                "https://addons.wago.io/api/data/game",
            ])

    def test_http_403_preflight_prevents_every_post_even_after_other_metadata_succeeds(self):
        with prepared_release() as directory:
            for failed_provider in ("curseforge", "wago"):
                with self.subTest(provider=failed_provider), \
                        patch.dict(os.environ, {"CF_API_KEY": "test-cf", "WAGO_API_TOKEN": "test-wago"}, clear=True), \
                        patch.object(markets, "build_opener") as build, \
                        patch.object(markets, "upload") as upload, patch("builtins.print"):
                    url = ("https://wow.curseforge.com/api/game/wow/versions" if failed_provider == "curseforge"
                           else "https://addons.wago.io/api/data/game")
                    error = HTTPError(url, 403, "Forbidden", {}, io.BytesIO(b"private provider error body"))
                    self.addCleanup(error.close)
                    build.return_value.open.side_effect = ([error] if failed_provider == "curseforge"
                                                           else [response(VERSIONS), error])
                    with self.assertRaises(HTTPError):
                        markets.publish(directory, TAG)
                    upload.assert_not_called()
                    requests = [call.args[0] for call in build.return_value.open.call_args_list]
                    self.assertTrue(all(request.get_method() == "GET" for request in requests))
                    self.assertEqual(len(requests), 1 if failed_provider == "curseforge" else 2)

    def test_selected_provider_requires_only_its_token_and_never_contacts_other_provider(self):
        cases = [
            ("curseforge", {"CF_API_KEY": "selected-cf"}, VERSIONS,
             "https://wow.curseforge.com/api/game/wow/versions",
             "https://wow.curseforge.com/api/projects/1478824/upload-file"),
            ("wago", {"WAGO_API_TOKEN": "selected-wago"}, WAGO,
             "https://addons.wago.io/api/data/game",
             "https://addons.wago.io/api/projects/QN53W7KB/version"),
        ]
        with prepared_release() as directory:
            for provider, environment, metadata, get_url, post_url in cases:
                with self.subTest(provider=provider), patch.dict(os.environ, environment, clear=True), \
                        patch.object(markets, "build_opener") as build, patch("builtins.print"):
                    build.return_value.open.side_effect = [response(metadata), response({"id": "accepted_1"}, 201)]
                    markets.publish(directory, TAG, provider=provider)
                    requests = [call.args[0] for call in build.return_value.open.call_args_list]
                    self.assertEqual([request.full_url for request in requests], [get_url, post_url])
                    self.assertEqual([request.get_method() for request in requests], ["GET", "POST"])
                    get_headers, post_headers = [
                        {key.lower(): value for key, value in request.header_items()} for request in requests
                    ]
                    if provider == "curseforge":
                        self.assertEqual(get_headers["x-api-token"], "selected-cf")
                        self.assertEqual(post_headers["x-api-token"], "selected-cf")
                        self.assertNotIn("authorization", post_headers)
                    else:
                        self.assertNotIn("authorization", get_headers)
                        self.assertEqual(post_headers["authorization"], "Bearer selected-wago")
                        self.assertNotIn("x-api-token", post_headers)
                    archive = directory / "KwikTip_Forever-0.1.0-alpha.1.zip"
                    self.assertIn(archive.read_bytes(), requests[1].data)

    def test_first_upload_success_then_second_failure_has_receipt_without_retry(self):
        with prepared_release() as directory:
            original_bytes = (directory / "KwikTip_Forever-0.1.0-alpha.1.zip").read_bytes()
            with patch.dict(os.environ, {"CF_API_KEY": "test-cf", "WAGO_API_TOKEN": "test-wago"}, clear=True), \
                    patch.object(markets, "build_opener") as build, patch("builtins.print") as printed:
                error_body = b"private response body with test-wago token"
                error = HTTPError("https://addons.wago.io/api/projects/QN53W7KB/version", 403,
                                  "Forbidden", {}, io.BytesIO(error_body))
                self.addCleanup(error.close)
                build.return_value.open.side_effect = [
                    response(VERSIONS), response(WAGO), response({"id": 7654321}, 201), error,
                ]
                with self.assertRaises(HTTPError):
                    markets.publish(directory, TAG)
                requests = [call.args[0] for call in build.return_value.open.call_args_list]
                self.assertEqual([request.get_method() for request in requests], ["GET", "GET", "POST", "POST"])
                self.assertEqual([request.full_url for request in requests[2:]], [
                    "https://wow.curseforge.com/api/projects/1478824/upload-file",
                    "https://addons.wago.io/api/projects/QN53W7KB/version",
                ])
                self.assertTrue(all(original_bytes in request.data for request in requests[2:]))
                output = "\n".join(str(call.args[0]) for call in printed.call_args_list)
                self.assertIn("CurseForge project 1478824: Forever alpha upload succeeded; file ID 7654321", output)
                self.assertNotIn("Wago project QN53W7KB: Forever alpha upload succeeded", output)
                self.assertNotIn("private response body", output)
                self.assertNotIn("test-wago", output)

            # A separately selected recovery reuses the same frozen assets and
            # must not repeat the accepted CurseForge POST.
            with patch.dict(os.environ, {"WAGO_API_TOKEN": "test-wago"}, clear=True), \
                    patch.object(markets, "build_opener") as build, patch("builtins.print"):
                build.return_value.open.side_effect = [response(WAGO), response({}, 201)]
                markets.publish(directory, TAG, provider="wago")
                self.assertEqual([call.args[0].full_url for call in build.return_value.open.call_args_list], [
                    "https://addons.wago.io/api/data/game", "https://addons.wago.io/api/projects/QN53W7KB/version",
                ])
                self.assertIn(original_bytes, build.return_value.open.call_args.args[0].data)

    def test_successful_post_receipt_is_optional_sanitized_and_never_retried(self):
        cases = [
            ({"id": 123}, "123"), ({"id": "file_ab-9"}, "file_ab-9"),
            ({}, None), ({"id": True}, None), ({"id": "../../private"}, None),
            ({"id": "unsafe\nreceipt"}, None), ({"id": "x" * 129}, None),
            (["provider diagnostic body"], None), (b"not JSON: private provider body", None),
            (b"\xff invalid UTF-8", None),
        ]
        with alpha_source() as root:
            archive = root / "sample.zip"
            archive.write_bytes(b"verified zip bytes")
            for body, expected in cases:
                with self.subTest(body=body), patch.object(markets, "open_request") as request, \
                        patch("builtins.print") as printed:
                    request.return_value = response(body, 201)
                    self.assertEqual(markets.upload("https://addons.wago.io/api/projects/QN53W7KB/version", {}, {}, archive), expected)
                    request.assert_called_once()
                    printed.assert_not_called()

            with patch.object(markets, "open_request") as request, patch("builtins.print") as printed:
                accepted = MagicMock()
                accepted.status = 201
                accepted.read.side_effect = OSError("private receipt read failure")
                request.return_value.__enter__.return_value = accepted
                self.assertIsNone(markets.upload("https://addons.wago.io/api/projects/QN53W7KB/version", {}, {}, archive))
                request.assert_called_once()
                accepted.read.assert_called_once()
                printed.assert_not_called()

    def test_cli_preflight_and_publish_are_exclusive_and_plan_makes_no_requests(self):
        with patch.object(sys, "argv", ["forever_marketplaces.py", "dist", "--tag", TAG, "--preflight", "--publish"]), \
                patch.object(markets, "publish") as publish, patch("sys.stderr", new_callable=io.StringIO):
            with self.assertRaises(SystemExit) as error:
                markets.main()
            self.assertEqual(error.exception.code, 2)
            publish.assert_not_called()
        with prepared_release() as directory, patch.dict(os.environ, {}, clear=True), \
                patch.object(sys, "argv", ["forever_marketplaces.py", str(directory), "--tag", TAG]), \
                patch.object(markets, "open_request") as request, patch("builtins.print") as printed:
            markets.main()
            request.assert_not_called()
            self.assertFalse(json.loads(printed.call_args.args[0])["uploaded"])

    def test_cli_http_error_reports_status_without_provider_body_or_tokens(self):
        with prepared_release() as directory:
            for mode in ("--preflight", "--publish"):
                with self.subTest(mode=mode), patch.dict(os.environ, {"WAGO_API_TOKEN": "private-token"}, clear=True), \
                        patch.object(sys, "argv", ["forever_marketplaces.py", str(directory), "--tag", TAG,
                                                  "--provider", "wago", mode]), \
                        patch.object(markets, "build_opener") as build, patch("builtins.print"):
                    failure = HTTPError(
                        "https://addons.wago.io/api/data/game", 403, "private-token", {},
                        io.BytesIO(b"private provider response body"),
                    )
                    self.addCleanup(failure.close)
                    build.return_value.open.side_effect = failure
                    with self.assertRaises(SystemExit) as error:
                        markets.main()
                    message = str(error.exception)
                    self.assertIn("HTTP 403", message)
                    self.assertNotIn("private", message)
                    self.assertEqual(build.return_value.open.call_count, 1)
                    self.assertEqual(build.return_value.open.call_args.args[0].get_method(), "GET")


if __name__ == "__main__":
    unittest.main()
