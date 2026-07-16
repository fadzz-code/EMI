# Speaking AI Integration

Batch 1 provides AI-assisted initial scoring. Teacher review remains available and authoritative; current Indonesian STT model is not a final Mekongga phonetic assessment.

## Actual End-to-End Flow

```text
Browser/mobile/ESP32 capture
→ client uploads multipart audio to authenticated Laravel student API
→ Laravel validates exercise, ownership, capture source, format, size, and supplied duration
→ Laravel stores attempt metadata and private audio media
→ AnalyzeSpeakingAttemptJob reads private audio server-side
→ Laravel sends target text + audio to internal FastAPI with bearer token
→ FastAPI validates, normalizes audio with FFmpeg, transcribes, and scores
→ Laravel stores result and completed/failed status
→ student reads status/result through Laravel
→ teacher plays authorized private audio and submits manual score/feedback through Laravel
```

Browser, mobile, and ESP32 integrations call Laravel only. They never call FastAPI directly and never contain FastAPI URL, service token, or fixed credential. ESP32 is a capture source transported through web serial or mobile Bluetooth, not a direct FastAPI client.

## Laravel API

Student:

```text
GET /api/v1/student/speaking/exercises
GET /api/v1/student/speaking/exercises/{exercise}
GET /api/v1/student/speaking/attempts
GET /api/v1/student/speaking/attempts/{attempt}
POST /api/v1/student/speaking/exercises/{exercise}/attempts
```

Attempt submission uses multipart field `file`; optional `audio_duration_seconds` accepts integer `1`–`SPEAKING_MAX_DURATION_SECONDS` (default `30`). Optional `capture_source` accepts:

- `web_microphone` (default)
- `web_esp32_serial`
- `mobile_microphone`
- `mobile_esp32_bluetooth`

Teacher:

```text
GET /api/v1/teacher/speaking/templates
GET /api/v1/teacher/speaking/exercises
POST /api/v1/teacher/speaking/exercises
GET /api/v1/teacher/speaking/exercises/{exercise}
PUT/PATCH /api/v1/teacher/speaking/exercises/{exercise}
PATCH /api/v1/teacher/speaking/exercises/{exercise}/archive
GET /api/v1/teacher/speaking/attempts
GET /api/v1/teacher/speaking/attempts/{attempt}
PATCH /api/v1/teacher/speaking/attempts/{attempt}/feedback
```

Teacher-created exercises are class-scoped and require an active class assignment. `created_by_id` is server-set; archive changes status instead of deleting. A teacher may copy a published global admin template and its public reference audio, then override editable text fields. Teachers cannot directly set or upload reference audio.

Admin global templates may reference public `media_files` with purpose `speaking_reference_audio`. Student and teacher responses include stable public reference-audio metadata when present.

Teacher feedback payload:

```json
{
  "teacher_score": 85,
  "teacher_feedback": "Pengucapan sudah cukup jelas, ulangi bagian akhir."
}
```

## Accepted Audio and Storage

Laravel accepts MIME types `audio/webm`, `video/webm`, `audio/wav`, `audio/x-wav`, `audio/mpeg`, `audio/mp4`, `audio/m4a`, and `audio/ogg`. `application/octet-stream` is accepted only with safe extension `webm`, `wav`, `mp3`, `m4a`, `mp4`, `mpeg`, `mpga`, `ogg`, or `oga`.

Laravel upload size defaults to `5 MB` through `SPEAKING_MAX_AUDIO_MB`. Supplied duration metadata is optional and, when present, defaults to maximum `30` seconds. FastAPI independently limits uploaded bytes to `5 MB` by default and validates normalized audio duration from `0.1` through `60` seconds by default.

Attempt audio uses existing media storage with purpose `speaking_recording` and private visibility. Binary audio is not stored in DB. Attempt records keep media ID, disk/path, MIME, size, duration metadata, capture source, and review/AI fields. API responses expose authorized `/api/v1/media/{id}` references, not raw storage paths.

No `/audio-list` endpoint exists. No `MediaFile::created` converter was found; Batch 1 rejects unsupported uploads instead of relying on a post-create converter.

## Laravel to FastAPI Contract

FastAPI endpoints:

```text
GET /health
GET /health/live
POST /predict
```

Health endpoints are unauthenticated liveness checks. `POST /predict` requires `Authorization: Bearer <SPEAKING_AI_SERVICE_TOKEN>` and multipart fields `target_text` and `file`. Laravel reads token from server environment `SPEAKING_AI_SERVICE_TOKEN`; blank token configuration does not authorize requests.

Laravel client defaults:

```env
SPEAKING_AI_ENABLED=false
SPEAKING_AI_BASE_URL=http://127.0.0.1:8001
SPEAKING_AI_SERVICE_TOKEN=
SPEAKING_AI_CONNECT_TIMEOUT_SECONDS=5
SPEAKING_AI_TIMEOUT_SECONDS=60
SPEAKING_MAX_AUDIO_MB=5
SPEAKING_MAX_DURATION_SECONDS=30
```

Connect timeout defaults to 5 seconds; whole request timeout defaults to 60 seconds. Laravel retries twice after initial failure, waiting 100 ms each time, only for connection failures or HTTP 5xx responses. It does not retry validation/authentication 4xx responses.

`AnalyzeSpeakingAttemptJob` leaves status `pending` when AI is disabled. When enabled it sets `processing`, stores validated success as `completed`, and stores stable public `Analisis speaking AI gagal.` with status `failed` on failure. Sync queue can complete submission inline in local/test environments.

## FastAPI Processing and Scoring

Run FastAPI on an internal interface, for example loopback:

```cmd
python -m uvicorn main:app --host 127.0.0.1 --port 8001
```

Every accepted format, including WAV, passes through FFmpeg. FFmpeg selects first audio stream and creates temporary mono, 16 kHz, signed 16-bit PCM WAV before transcription. Output structure and normalized duration are validated; temporary input/output files are removed after processing.

FastAPI defaults:

```env
SPEAKING_AI_SERVICE_TOKEN=
SPEAKING_AI_MODEL=indonesian-nlp/wav2vec2-large-xlsr-indonesian
SPEAKING_AI_MAX_FILE_SIZE_MB=5
SPEAKING_AI_MIN_DURATION_SECONDS=0.1
SPEAKING_AI_MAX_DURATION_SECONDS=60
SPEAKING_AI_FFMPEG_TIMEOUT_SECONDS=30
SPEAKING_AI_FFMPEG_PATH=ffmpeg
```

Success includes `engine`, `model`, `target`, `transcription`, `score`, `alignment`, `warnings`, and `scoring_version`. Scoring version `word-levenshtein-v1` normalizes text into lowercase Unicode words, computes word-level Levenshtein insertions/deletions/substitutions, and returns a 0–100 score plus alignment operations. Every result warns: `Model is Indonesian STT; Mekongga pronunciation scoring is approximate.`

Stable FastAPI error envelope:

```json
{
  "error": "message",
  "code": "SPEAKING_AI_ERROR"
}
```

Stable codes are:

- `SPEAKING_AI_UNAUTHORIZED` — missing, blank-configured, or incorrect bearer token (`401`)
- `SPEAKING_AI_VALIDATION_ERROR` — invalid request, format, size, audio, or duration (`422`)
- `SPEAKING_AI_TIMEOUT` — FFmpeg processing timeout (`503`)
- `SPEAKING_AI_UNAVAILABLE` — FFmpeg/model unavailable (`503`)
- `SPEAKING_AI_ERROR` — other internal processing failure (`500`)

## FFmpeg Local Setup

```cmd
cd Emi-Speaking-AI
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
winget install -e --id Gyan.FFmpeg
ffmpeg -version
python -m uvicorn main:app --host 127.0.0.1 --port 8001
```

If PATH lookup fails, locate FFmpeg:

```powershell
Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
```

Then set `SPEAKING_AI_FFMPEG_PATH` to found executable path in same terminal before Uvicorn. First inference can be slow while model loads or downloads.

## ESP32 Web Serial (Batch 2)

Student speaking page keeps browser microphone as default and adds an optional **Perangkat ESP32** source. Web Serial works only in a secure context (HTTPS or localhost) on a supporting desktop browser such as current Chrome or Edge. Port chooser opens only after **Pilih perangkat** is clicked. On page load, reconnect only considers ports previously permitted by the user.

Serial settings and protocol assumptions:

```text
Baud: 921600
Packet: AA 55 | TYPE | LENGTH_BE (2 bytes) | PAYLOAD | EE
TYPE 0x01: raw PCM signed 16-bit little-endian, mono, 16000 Hz
Incoming TYPE 0x02, payload 0x01: PTT pressed, start capture
Incoming TYPE 0x02, payload 0x00: PTT released, finish capture
Outgoing TYPE 0x02, payload 0x02: stop playback and flush DMA
```

Outgoing `0x02/0x02` never means stop recording. Parser accepts only types `0x01` and `0x02`, discards unknown types, accepts fragmented and adjacent packets, skips noise, and resynchronizes after bad framing/footer. Although length uses an unsigned 16-bit field, firmware packet payload is capped at `32768` bytes. At `921600` baud this limits one packet to roughly 0.36 seconds of wire time, keeps browser latency responsive, and still carries over one second of 16 kHz mono s16le audio. Internal parser storage is capped at `32774` bytes, exactly one maximum framed packet; larger declared lengths are rejected immediately and incoming noise cannot cause unbounded allocation.

ESP32 PCM is accepted only when byte count is even, then wrapped as mono 16 kHz signed 16-bit WAV. Effective PCM maximum is `min(5 MiB - 44-byte WAV header, 30 seconds × 32000 bytes/second) = 960000 bytes`. Minimum is `0.1` second (`3200` PCM bytes), matching FastAPI normalized minimum. Upload uses Laravel student endpoint with `capture_source=web_esp32_serial`; microphone uses `capture_source=web_microphone`. Integer duration metadata is included only for captures of at least one second because Laravel accepts integers from `1`.

Troubleshooting:

- **Web Serial tidak didukung**: use current Chrome/Edge desktop over HTTPS or localhost; embedded browsers and many mobile browsers do not expose Web Serial.
- **No device in chooser**: connect ESP32 by data-capable USB cable, close serial monitor, verify driver, then click **Pilih perangkat**.
- **Cannot open port**: close Arduino IDE/other process holding port, disconnect in page, then reconnect.
- **No recording after PTT**: verify baud `921600`, exact framing, control direction/value, PCM type, and footer `EE`.
- **Audio distorted or too fast/slow**: firmware must send raw mono `s16le` at exactly `16000 Hz`, without WAV headers inside type `0x01` payloads.
- **Recording rejected**: capture must be `0.1`–`30` seconds, even-byte PCM, and no more than `960000` PCM bytes.

Automated tests mock browser boundaries and cover framing, fragmentation, multiple packets, noise/footer resync, bounds, WAV headers/validation, secure-context feature detection, and upload metadata. Physical ESP32 port selection, PTT timing, PCM electrical/audio quality, reconnect behavior, and playback DMA flush remain manual hardware checks.

## Security and Current Limits

- FastAPI remains internal/private and bearer-authenticated.
- Service token stays in Laravel and FastAPI server environments; examples intentionally leave it blank.
- Speaking recordings remain private and authorization-scoped to owning student or actively assigned teacher.
- Current score measures target/transcription word edit distance, not phoneme-level Mekongga pronunciation.
- Teacher review remains authoritative.
