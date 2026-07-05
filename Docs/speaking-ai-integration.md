# Speaking AI Integration

This is AI-assisted initial scoring. Teacher review remains available. The current AI engine is not a final authoritative Mekongga phonetic assessment.

## Architecture

```text
Web/Mobile
→ Laravel API
→ Laravel stores speaking attempt + private audio media
→ Laravel queue job calls Python AI service
→ Python returns transcription/score/alignment
→ Laravel stores AI result
→ Student sees result/status
→ Teacher reviews original audio and gives manual feedback/score
```

Web/mobile must call Laravel only. The Python service is an internal analysis engine.

## Laravel Endpoints

Student:

```text
GET /api/v1/student/speaking/exercises
GET /api/v1/student/speaking/exercises/{exercise}
GET /api/v1/student/speaking/attempts
GET /api/v1/student/speaking/attempts/{attempt}
POST /api/v1/student/speaking/exercises/{exercise}/attempts
```

Teacher:

```text
GET /api/v1/teacher/speaking/attempts
GET /api/v1/teacher/speaking/attempts/{attempt}
PATCH /api/v1/teacher/speaking/attempts/{attempt}/feedback
```

Teacher feedback payload:

```json
{
  "teacher_score": 85,
  "teacher_feedback": "Pengucapan sudah cukup jelas, ulangi bagian akhir."
}
```

## Python Service Endpoints

```text
GET /health
POST /predict
```

`POST /predict` uses multipart form fields:

- `target_text`
- `file`

Stable success includes `engine`, `model`, `target`, `transcription`, `score`, `alignment`, and `warnings`.

Safe browser uploads include `audio/webm`, `video/webm`, WebM/Opus content type parameters, WAV, MP3, MP4/M4A, OGG, and `application/octet-stream` only with a safe audio extension.

Stable error:

```json
{
  "error": "message",
  "code": "SPEAKING_AI_ERROR"
}
```

## Queue Behavior

`AnalyzeSpeakingAttemptJob` receives a speaking attempt ID.

- If `SPEAKING_AI_ENABLED=false`, the attempt remains `pending` for teacher/manual review.
- If enabled, the job sets status `processing`, calls Python `/predict`, then stores AI result and sets status `completed`.
- If the AI call fails, status becomes `failed` and `ai_error` is stored.

Local test/dev may use sync queue, so a submitted attempt can complete immediately when a fake/enabled client is used.

## Storage Behavior

Audio is stored through the existing media system as purpose `speaking_recording` with private visibility. Raw audio binary is not stored in the database.

Speaking attempts store:

- `audio_media_id`
- `audio_path`
- `audio_disk`
- MIME/type/size metadata
- AI and teacher review fields

API responses expose `audio_media_id` and `/api/v1/media/{id}` style media reference, not raw storage paths.

## Privacy / Security Notes

- Python service has no authentication in this batch and must remain private/internal.
- Mobile/web clients must never call Python directly.
- Speaking recordings are private media.
- Teachers can only access attempts for classes they actively teach.
- Students can only access their own attempts.

## Local Setup

Laravel `.env.example` keys:

```env
SPEAKING_AI_ENABLED=false
SPEAKING_AI_BASE_URL=http://127.0.0.1:8001
SPEAKING_AI_TIMEOUT_SECONDS=60
SPEAKING_MAX_AUDIO_MB=5
SPEAKING_MAX_DURATION_SECONDS=30
```

Python service:

```cmd
cd Emi-Speaking-AI
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
winget install -e --id Gyan.FFmpeg
ffmpeg -version
python -m uvicorn main:app --host 127.0.0.1 --port 8001
```

The Hugging Face model may download on first run. Browser WebM/Opus conversion requires `ffmpeg` available on PATH or `SPEAKING_AI_FFMPEG_PATH` pointing to `ffmpeg.exe`. Conversion produces a temporary mono 16 kHz WAV and fails clearly if `ffmpeg` is unavailable or outputs an empty file.

If Python cannot find FFmpeg after install, find it in PowerShell:

```powershell
Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
```

Then set the path in the same terminal before running Uvicorn. Replace this example path with your own path:

```cmd
set SPEAKING_AI_FFMPEG_PATH=C:\Users\Tulo\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe
python -m uvicorn main:app --host 127.0.0.1 --port 8001
```

Recent manual QA evidence: student browser recording submission completed AI analysis locally after `SPEAKING_AI_FFMPEG_PATH` pointed to the WinGet FFmpeg executable. Teacher review and student feedback display still need full manual QA.

## Troubleshooting

- `ffmpeg tidak ditemukan untuk konversi audio browser`: set `SPEAKING_AI_FFMPEG_PATH` in the same terminal before running Uvicorn.
- `Jenis audio tidak didukung`: confirm the upload is WAV, WebM/Opus, MP3, MP4, M4A, OGG, or safe octet-stream with an audio extension.
- First inference can be slow because the Wav2Vec2 model may load or download on first use.
- If attempts stay pending, confirm Laravel queue worker is running when `QUEUE_CONNECTION=database`.

## Production Notes

- Run Python behind private networking, not public internet.
- Add process supervision and resource limits for model inference.
- Consider a separate queue for speech analysis if inference is slow.
- Monitor failed attempts and `ai_error` values.
- Do not embed Python service URLs/secrets in mobile apps.

## Current Limitations

- The AI model is Indonesian STT, not a true Mekongga phonetic scorer.
- Duration validation uses client-provided metadata for now; deeper server-side duration probing can be added later.
- Teacher review is the authoritative correction path.

## Next Frontend Batch TODO

- Connect student speaking page to the new exercise/attempt endpoints.
- Add polling for `pending`, `processing`, `completed`, and `failed` statuses.
- Connect teacher speaking results page to teacher endpoints.
- Add audio playback through existing private media URL flow.
