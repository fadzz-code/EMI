# EMI Speaking AI Service

FastAPI speech analysis engine for EMI speaking practice. Laravel is the main backend; web/mobile clients must call Laravel, not this service directly.

## Install

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

## FFmpeg for browser audio

Every upload, including WAV, is normalized by FFmpeg to temporary mono 16 kHz PCM WAV before analysis.

Install on Windows:

```cmd
winget install -e --id Gyan.FFmpeg
```

Verify:

```cmd
ffmpeg -version
```

If the Python service still cannot find FFmpeg, locate it in PowerShell:

```powershell
Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
```

Then set the path in the same terminal before running Uvicorn. Replace this example path with the path found on your machine:

```cmd
set SPEAKING_AI_FFMPEG_PATH=C:\Users\Tulo\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe
```

## Run locally

Copy `.env.example`, set a long random `SPEAKING_AI_SERVICE_TOKEN`, then export its values before startup.

```cmd
set SPEAKING_AI_SERVICE_TOKEN=replace-with-a-long-random-token
python -m uvicorn main:app --host 127.0.0.1 --port 8001
```

The Wav2Vec2 model may download on first run.

## Endpoints

```text
GET /health/live
GET /health
POST /predict (Bearer token required)
```

Sample request:

```bash
curl -X POST http://127.0.0.1:8001/predict \
  -H "Authorization: Bearer $SPEAKING_AI_SERVICE_TOKEN" \
  -F "target_text=Ari nggiro" \
  -F "file=@sample.wav;type=audio/wav"
```

## Limits

`SPEAKING_AI_MAX_FILE_SIZE_MB` defaults to `5`. Duration defaults to `0.1`–`60` seconds through `SPEAKING_AI_MIN_DURATION_SECONDS` and `SPEAKING_AI_MAX_DURATION_SECONDS`. `SPEAKING_AI_FFMPEG_TIMEOUT_SECONDS` defaults to `30`.

Supported uploads include WAV, WebM/Opus (`audio/webm` or `video/webm`), MP3, MP4, M4A, and OGG. `application/octet-stream` is accepted only with a safe audio extension.

## Contract

Success returns `engine`, `model`, `target`, `transcription`, `score`, backward-compatible per-target word scores plus edit `operations` in `alignment`, `warnings`, and `scoring_version`. Score uses normalized word-level Levenshtein distance.

Errors return:

```json
{
  "error": "message",
  "code": "SPEAKING_AI_ERROR"
}
```

## Tests

```cmd
python -m unittest -v test_main.py
```

## Troubleshooting

- `ffmpeg tidak ditemukan untuk konversi audio browser`: set `SPEAKING_AI_FFMPEG_PATH` in the same terminal before running Uvicorn.
- `Jenis audio tidak didukung`: confirm the upload is WAV, WebM/Opus, MP3, MP4, M4A, OGG, or safe octet-stream with an audio extension.
- First inference can be slow because the Wav2Vec2 model may load or download on first use.
- If attempts stay pending, confirm Laravel queue worker is running when `QUEUE_CONNECTION=database`.

## Limitations

This is AI-assisted initial scoring. Teacher review remains available. The current AI engine uses Indonesian STT and is not a final authoritative Mekongga phonetic assessment.

Run this service as an internal/private service reachable by Laravel only.
