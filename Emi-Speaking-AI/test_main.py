import io
import os
import subprocess
import tempfile
import unittest
import wave
from pathlib import Path
from unittest.mock import patch

os.environ["SPEAKING_AI_SERVICE_TOKEN"] = "test-token"

from fastapi.testclient import TestClient

import main


class HardeningTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(main.app, raise_server_exceptions=False)
        self.headers = {"Authorization": "Bearer test-token"}
        self.temp_dir = tempfile.TemporaryDirectory()
        self.temp_patch = patch.object(main.tempfile, "tempdir", self.temp_dir.name)
        self.temp_patch.start()

    def tearDown(self):
        self.temp_patch.stop()
        self.temp_dir.cleanup()

    def wav(self, seconds=0.2):
        output = io.BytesIO()
        with wave.open(output, "wb") as audio:
            audio.setnchannels(1)
            audio.setsampwidth(2)
            audio.setframerate(16000)
            audio.writeframes(b"\0\0" * int(16000 * seconds))
        return output.getvalue()

    def ffmpeg(self, command, **_):
        Path(command[-1]).write_bytes(self.wav())
        return subprocess.CompletedProcess(command, 0, "", "")

    def predict(self, data=None, content=None, filename="sample.wav", content_type="audio/wav", headers=None):
        return self.client.post(
            "/predict",
            data={"target_text": "halo dunia"} if data is None else data,
            files={"file": (filename, self.wav() if content is None else content, content_type)},
            headers=self.headers if headers is None else headers,
        )

    def assert_clean(self):
        self.assertEqual(list(Path(self.temp_dir.name).iterdir()), [])

    def test_predict_missing_token_401(self):
        response = self.predict(headers={})
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json(), {"error": "Unauthorized", "code": "SPEAKING_AI_UNAUTHORIZED"})

    def test_predict_wrong_token_401(self):
        response = self.predict(headers={"Authorization": "Bearer wrong"})
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["code"], "SPEAKING_AI_UNAUTHORIZED")

    def test_right_token_processed_without_model_download(self):
        with patch.object(main, "prepare_audio_for_transcription", side_effect=lambda path: path), patch.object(main, "transcribe", return_value="halo dunia") as transcribe, patch.object(main, "load_model") as load_model:
            response = self.predict()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["score"], 100.0)
        transcribe.assert_called_once()
        load_model.assert_not_called()
        self.assert_clean()

    def test_empty_target_rejected(self):
        response = self.predict(data={"target_text": " "})
        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "SPEAKING_AI_VALIDATION_ERROR")
        self.assert_clean()

    def test_empty_file_rejected(self):
        response = self.predict(content=b"")
        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "SPEAKING_AI_VALIDATION_ERROR")
        self.assert_clean()

    def test_valid_wav_normalized(self):
        with patch.object(main, "resolve_ffmpeg_path", return_value="ffmpeg"), patch.object(main.subprocess, "run", side_effect=self.ffmpeg) as run, patch.object(main, "transcribe", return_value="halo dunia"):
            response = self.predict()
        self.assertEqual(response.status_code, 200)
        self.assertIn("-c:a", run.call_args.args[0])
        self.assertFalse(run.call_args.kwargs["shell"])
        self.assert_clean()

    def test_valid_webm_normalized(self):
        with patch.object(main, "resolve_ffmpeg_path", return_value="ffmpeg"), patch.object(main.subprocess, "run", side_effect=self.ffmpeg) as run, patch.object(main, "transcribe", return_value="halo dunia"):
            response = self.predict(content=b"webm", filename="sample.webm", content_type="audio/webm")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(run.called)
        self.assert_clean()

    def test_corrupt_audio_rejected(self):
        failed = subprocess.CompletedProcess([], 1, "", "private /tmp/input ffmpeg detail")
        with patch.object(main, "resolve_ffmpeg_path", return_value="ffmpeg"), patch.object(main.subprocess, "run", return_value=failed):
            response = self.predict(content=b"corrupt")
        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json(), {"error": "Invalid request", "code": "SPEAKING_AI_VALIDATION_ERROR"})
        self.assertNotIn("ffmpeg", response.text)
        self.assertNotIn("/tmp", response.text)
        self.assert_clean()

    def test_over_size_rejected(self):
        with patch.object(main, "MAX_FILE_SIZE_BYTES", 3):
            response = self.predict(content=b"1234")
        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "SPEAKING_AI_VALIDATION_ERROR")
        self.assert_clean()

    def test_ffmpeg_timeout_stable_and_clean(self):
        timeout = subprocess.TimeoutExpired(["ffmpeg", "private-path"], 1, stderr="internal")
        with patch.object(main, "resolve_ffmpeg_path", return_value="ffmpeg"), patch.object(main.subprocess, "run", side_effect=timeout):
            response = self.predict()
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json(), {"error": "Processing timed out", "code": "SPEAKING_AI_TIMEOUT"})
        self.assertNotIn("private-path", response.text)
        self.assert_clean()

    def test_unavailable_stable_and_clean(self):
        with patch.object(main, "resolve_ffmpeg_path", return_value=None):
            response = self.predict()
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["code"], "SPEAKING_AI_UNAVAILABLE")
        self.assert_clean()

    def test_unexpected_internal_detail_not_leaked_and_clean(self):
        with patch.object(main, "prepare_audio_for_transcription", side_effect=ValueError("C:\\secret\\model ffmpeg")):
            response = self.predict()
        self.assertEqual(response.status_code, 500)
        self.assertEqual(response.json(), {"error": "Service unavailable", "code": "SPEAKING_AI_ERROR"})
        self.assertNotIn("secret", response.text)
        self.assert_clean()

    def test_cleanup_oserror_does_not_mask_response(self):
        real_remove = os.remove

        def remove(path):
            real_remove(path)
            raise OSError("cleanup failed")

        with patch.object(main, "prepare_audio_for_transcription", side_effect=lambda path: path), patch.object(main, "transcribe", return_value="halo dunia"), patch.object(main.os, "remove", side_effect=remove):
            response = self.predict()
        self.assertEqual(response.status_code, 200)
        self.assert_clean()

    def test_health_routes_work_without_auth(self):
        for route in ("/health", "/health/live"):
            response = self.client.get(route)
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()["status"], "ok")

    def test_word_levenshtein(self):
        score, alignment = main.levenshtein_score("Halo, dunia baru", "halo bumi baru sekali")
        self.assertEqual(score, 33.33)
        self.assertEqual(alignment["distance"], 2)
        self.assertEqual([item["type"] for item in alignment["operations"]], ["match", "substitution", "match", "insertion"])
        self.assertEqual(alignment["0_halo"], 100)


if __name__ == "__main__":
    unittest.main()
