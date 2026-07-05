# EMI Speaking AI Service

FastAPI speech analysis engine for EMI speaking practice. Laravel is the main backend; web/mobile clients must call Laravel, not this service directly.

## Install

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Run locally

```bash
uvicorn main:app --host 127.0.0.1 --port 8001
```

The Wav2Vec2 model may download on first run. Browser WebM/Opus conversion requires `ffmpeg` available on PATH or `SPEAKING_AI_FFMPEG_PATH` pointing to `ffmpeg.exe`. Conversion produces a temporary mono 16 kHz WAV and fails clearly if `ffmpeg` is unavailable or outputs an empty file.

## Endpoints

```text
GET /health
POST /predict
```

Sample request:

```bash
curl -X POST http://127.0.0.1:8001/predict \
  -F "target_text=Ari nggiro" \
  -F "file=@sample.wav;type=audio/wav"
```

## Limits

`SPEAKING_AI_MAX_FILE_SIZE_MB` defaults to `5`.

Supported uploads include WAV, WebM/Opus (`audio/webm` or `video/webm`), MP3, MP4, M4A, and OGG. `application/octet-stream` is accepted only with a safe audio extension.

## Contract

Success returns `engine`, `model`, `target`, `transcription`, `score`, `alignment`, and `warnings`.

Errors return:

```json
{
  "error": "message",
  "code": "SPEAKING_AI_ERROR"
}
```

## Limitations

This is AI-assisted initial scoring. Teacher review remains available. The current AI engine uses Indonesian STT and is not a final authoritative Mekongga phonetic assessment.

Run this service as an internal/private service reachable by Laravel only.
