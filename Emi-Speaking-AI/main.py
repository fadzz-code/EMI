import hmac
import logging
import os
import re
import shutil
import subprocess
import tempfile
import unicodedata
import wave
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, File, Form, HTTPException, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

load_dotenv()

ENGINE = "wav2vec2-indonesian-levenshtein"
MODEL_NAME = os.getenv("SPEAKING_AI_MODEL", "indonesian-nlp/wav2vec2-large-xlsr-indonesian")
MAX_FILE_SIZE_BYTES = int(os.getenv("SPEAKING_AI_MAX_FILE_SIZE_MB", "5")) * 1024 * 1024
MIN_DURATION_SECONDS = float(os.getenv("SPEAKING_AI_MIN_DURATION_SECONDS", "0.1"))
MAX_DURATION_SECONDS = float(os.getenv("SPEAKING_AI_MAX_DURATION_SECONDS", "60"))
FFMPEG_TIMEOUT_SECONDS = float(os.getenv("SPEAKING_AI_FFMPEG_TIMEOUT_SECONDS", "30"))
MAX_LOG_CHARS = 1000
SAFE_EXTENSIONS = {".wav", ".webm", ".mp3", ".mp4", ".m4a", ".mpeg", ".mpga", ".ogg", ".oga"}
SAFE_CONTENT_TYPES = {"audio/wav", "audio/x-wav", "audio/webm", "video/webm", "audio/mpeg", "audio/mp4", "video/mp4", "application/mp4", "audio/m4a", "audio/ogg"}
WARNING = "Model is Indonesian STT; Mekongga pronunciation scoring is approximate."

app = FastAPI(title="EMI Speaking AI", version="0.2.0")
logger = logging.getLogger("emi-speaking-ai")
security = HTTPBearer(auto_error=False)
_model: dict[str, Any] | None = None


def error_response(message: str, code: str, status_code: int) -> JSONResponse:
    return JSONResponse({"error": message, "code": code}, status_code=status_code)


def authorize(credentials: HTTPAuthorizationCredentials | None = Depends(security)) -> None:
    expected = os.getenv("SPEAKING_AI_SERVICE_TOKEN", "")
    supplied = credentials.credentials if credentials and credentials.scheme.lower() == "bearer" else ""
    if not expected or not hmac.compare_digest(supplied.encode(), expected.encode()):
        raise HTTPException(status_code=401, detail="Unauthorized")


def validate_upload(file: UploadFile) -> None:
    suffix = Path(file.filename or "").suffix.lower()
    content_type = (file.content_type or "").lower().split(";", 1)[0].strip()
    if content_type == "application/octet-stream" and suffix in SAFE_EXTENSIONS:
        return
    if content_type not in SAFE_CONTENT_TYPES:
        raise HTTPException(status_code=422, detail="Invalid audio upload")


def resolve_ffmpeg_path() -> str | None:
    configured = os.getenv("SPEAKING_AI_FFMPEG_PATH")
    if configured and Path(configured).is_file():
        return configured
    return shutil.which("ffmpeg")


def inspect_wav(path: str) -> float:
    try:
        with wave.open(path, "rb") as audio:
            frames = audio.getnframes()
            rate = audio.getframerate()
            valid = audio.getnchannels() == 1 and audio.getsampwidth() == 2 and rate == 16000
    except (wave.Error, EOFError, OSError) as exc:
        raise RuntimeError("INVALID_AUDIO") from exc
    if not valid or frames < 1 or rate < 1:
        raise RuntimeError("INVALID_AUDIO")
    duration = frames / rate
    if duration < MIN_DURATION_SECONDS or duration > MAX_DURATION_SECONDS:
        raise RuntimeError("INVALID_DURATION")
    return duration


def prepare_audio_for_transcription(path: str) -> str:
    ffmpeg_path = resolve_ffmpeg_path()
    if not ffmpeg_path:
        logger.error("ffmpeg unavailable")
        raise RuntimeError("PROCESSING_UNAVAILABLE")
    output = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    wav_path = output.name
    output.close()
    try:
        result = subprocess.run(
            [ffmpeg_path, "-nostdin", "-v", "error", "-y", "-i", path, "-map", "0:a:0", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", "-f", "wav", wav_path],
            capture_output=True,
            check=False,
            text=True,
            timeout=FFMPEG_TIMEOUT_SECONDS,
            shell=False,
        )
        if result.returncode != 0:
            logger.warning("audio normalization failed: %s", (result.stderr or "")[-MAX_LOG_CHARS:])
            raise RuntimeError("INVALID_AUDIO")
        inspect_wav(wav_path)
        return wav_path
    except subprocess.TimeoutExpired as exc:
        logger.warning("audio normalization timed out")
        try:
            os.remove(wav_path)
        except OSError:
            pass
        raise RuntimeError("PROCESSING_TIMEOUT") from exc
    except Exception:
        try:
            os.remove(wav_path)
        except OSError:
            pass
        raise


def normalize_words(text: str) -> list[str]:
    normalized = unicodedata.normalize("NFKC", text).lower()
    return re.findall(r"[^\W_]+", normalized, flags=re.UNICODE)


def character_distance(target: str, actual: str) -> int:
    if target == actual:
        return 0
    if not target:
        return len(actual)
    if not actual:
        return len(target)
    previous = list(range(len(actual) + 1))
    for i in range(1, len(target) + 1):
        current = [i] + [0] * len(actual)
        for j in range(1, len(actual) + 1):
            current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (target[i - 1] != actual[j - 1]))
        previous = current
    return previous[-1]


def phoneme_similarity(target: str, actual: str) -> tuple[float, int]:
    span = max(len(target), len(actual))
    if span == 0:
        return 100.0, 0
    distance = character_distance(target, actual)
    similarity = round(max(0.0, 1 - distance / span) * 100, 2)
    return similarity, distance


def levenshtein_score(target: str, transcription: str) -> tuple[float, dict[str, Any]]:
    expected = normalize_words(target)
    actual = normalize_words(transcription)
    rows = [[0] * (len(actual) + 1) for _ in range(len(expected) + 1)]
    for i in range(len(expected) + 1):
        rows[i][0] = i
    for j in range(len(actual) + 1):
        rows[0][j] = j
    for i in range(1, len(expected) + 1):
        for j in range(1, len(actual) + 1):
            rows[i][j] = min(rows[i - 1][j] + 1, rows[i][j - 1] + 1, rows[i - 1][j - 1] + (expected[i - 1] != actual[j - 1]))
    operations: list[dict[str, Any]] = []
    scores = [0.0] * len(expected)
    insertions = 0
    i, j = len(expected), len(actual)
    while i or j:
        if i and j and rows[i][j] == rows[i - 1][j - 1] + (expected[i - 1] != actual[j - 1]):
            kind = "match" if expected[i - 1] == actual[j - 1] else "substitution"
            similarity, char_distance = phoneme_similarity(expected[i - 1], actual[j - 1])
            scores[i - 1] = similarity
            operations.append({"type": kind, "target": expected[i - 1], "transcription": actual[j - 1], "target_index": i - 1, "transcription_index": j - 1, "score": similarity, "char_distance": char_distance})
            i -= 1
            j -= 1
        elif i and rows[i][j] == rows[i - 1][j] + 1:
            scores[i - 1] = 0.0
            operations.append({"type": "deletion", "target": expected[i - 1], "transcription": None, "target_index": i - 1, "transcription_index": j, "score": 0.0, "char_distance": len(expected[i - 1])})
            i -= 1
        else:
            insertions += 1
            operations.append({"type": "insertion", "target": None, "transcription": actual[j - 1], "target_index": i, "transcription_index": j - 1, "score": 0.0, "char_distance": len(actual[j - 1])})
            j -= 1
    operations.reverse()
    alignment: dict[str, Any] = {f"{index}_{word}": scores[index] for index, word in enumerate(expected)}
    alignment["operations"] = operations
    alignment["distance"] = rows[-1][-1]
    denominator = len(expected) + insertions
    score = 0.0 if denominator == 0 else round(sum(scores) / denominator, 2)
    return score, alignment


def load_model() -> dict[str, Any]:
    global _model
    if _model is not None:
        return _model
    try:
        import librosa
        import torch
        from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
        _model = {"torch": torch, "librosa": librosa, "processor": Wav2Vec2Processor.from_pretrained(MODEL_NAME), "model": Wav2Vec2ForCTC.from_pretrained(MODEL_NAME)}
        return _model
    except Exception as exc:
        logger.exception("model initialization failed")
        raise RuntimeError("PROCESSING_UNAVAILABLE") from exc


def transcribe(path: str) -> str:
    bundle = load_model()
    try:
        speech, _ = bundle["librosa"].load(path, sr=16000, mono=True)
        if len(speech) < 1:
            raise ValueError
        inputs = bundle["processor"](speech, sampling_rate=16000, return_tensors="pt", padding=True)
        with bundle["torch"].no_grad():
            logits = bundle["model"](inputs.input_values).logits
        return str(bundle["processor"].batch_decode(bundle["torch"].argmax(logits, dim=-1))[0]).strip().lower()
    except RuntimeError:
        raise
    except Exception as exc:
        logger.warning("transcription failed: %s", type(exc).__name__)
        raise RuntimeError("INVALID_AUDIO") from exc


@app.exception_handler(HTTPException)
async def http_exception_handler(_, exc: HTTPException) -> JSONResponse:
    if exc.status_code == 401:
        return error_response("Unauthorized", "SPEAKING_AI_UNAUTHORIZED", 401)
    return error_response("Invalid request", "SPEAKING_AI_VALIDATION_ERROR", exc.status_code)


@app.exception_handler(RequestValidationError)
async def request_validation_handler(_, __: RequestValidationError) -> JSONResponse:
    return error_response("Invalid request", "SPEAKING_AI_VALIDATION_ERROR", 422)


@app.get("/health/live")
@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "engine": ENGINE, "model": MODEL_NAME}


@app.post("/predict", dependencies=[Depends(authorize)])
async def predict(target_text: str = Form(...), file: UploadFile = File(...)) -> JSONResponse:
    if not target_text.strip():
        raise HTTPException(status_code=422, detail="Invalid target")
    validate_upload(file)
    suffix = Path(file.filename or "recording.wav").suffix.lower()
    suffix = suffix if suffix in SAFE_EXTENSIONS else ".bin"
    temp_path = None
    normalized_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_path = temp_file.name
            total = 0
            while chunk := await file.read(64 * 1024):
                total += len(chunk)
                if total > MAX_FILE_SIZE_BYTES:
                    raise HTTPException(status_code=422, detail="Upload too large")
                temp_file.write(chunk)
        if not total:
            raise HTTPException(status_code=422, detail="Empty upload")
        normalized_path = prepare_audio_for_transcription(temp_path)
        transcription = transcribe(normalized_path)
        score, alignment = levenshtein_score(target_text, transcription)
        return JSONResponse({"engine": ENGINE, "model": MODEL_NAME, "target": target_text, "transcription": transcription, "score": score, "alignment": alignment, "warnings": [WARNING], "scoring_version": "phoneme-levenshtein-v2"})
    except HTTPException:
        raise
    except RuntimeError as exc:
        errors = {
            "INVALID_AUDIO": ("Invalid request", "SPEAKING_AI_VALIDATION_ERROR", 422),
            "INVALID_DURATION": ("Invalid request", "SPEAKING_AI_VALIDATION_ERROR", 422),
            "PROCESSING_TIMEOUT": ("Processing timed out", "SPEAKING_AI_TIMEOUT", 503),
            "PROCESSING_UNAVAILABLE": ("Service unavailable", "SPEAKING_AI_UNAVAILABLE", 503),
        }
        message, code, status = errors.get(str(exc), ("Service unavailable", "SPEAKING_AI_ERROR", 500))
        return error_response(message, code, status)
    except Exception:
        logger.exception("unexpected prediction failure")
        return error_response("Service unavailable", "SPEAKING_AI_ERROR", 500)
    finally:
        try:
            await file.close()
        except OSError:
            pass
        for path in (normalized_path, temp_path):
            if path:
                try:
                    os.remove(path)
                except OSError:
                    pass
