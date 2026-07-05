import os
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

ENGINE = "wav2vec2-indonesian-levenshtein"
MODEL_NAME = os.getenv("SPEAKING_AI_MODEL", "indonesian-nlp/wav2vec2-large-xlsr-indonesian")
MAX_FILE_SIZE_BYTES = int(os.getenv("SPEAKING_AI_MAX_FILE_SIZE_MB", "5")) * 1024 * 1024
SAFE_EXTENSIONS = {".wav", ".webm", ".mp3", ".mp4", ".m4a", ".mpeg", ".mpga", ".ogg", ".oga"}
SAFE_CONTENT_TYPES = {
    "audio/wav",
    "audio/x-wav",
    "audio/webm",
    "video/webm",
    "audio/mpeg",
    "audio/mp4",
    "audio/m4a",
    "audio/ogg",
}
WARNING = "Model is Indonesian STT; Mekongga pronunciation scoring is approximate."

app = FastAPI(title="EMI Speaking AI", version="0.1.0")
_model: dict[str, Any] | None = None


def error_response(message: str, code: str, status_code: int) -> JSONResponse:
    return JSONResponse({"error": message, "code": code}, status_code=status_code)


def validate_upload(file: UploadFile) -> None:
    suffix = Path(file.filename or "").suffix.lower()
    content_type = (file.content_type or "").lower().split(";", 1)[0].strip()

    if content_type == "application/octet-stream" and suffix in SAFE_EXTENSIONS:
        return

    if content_type not in SAFE_CONTENT_TYPES:
        raise HTTPException(status_code=422, detail="Jenis audio tidak didukung.")


def prepare_audio_for_transcription(path: str) -> tuple[str, str | None]:
    suffix = Path(path).suffix.lower()
    if suffix == ".wav":
        return path, None

    wav_file = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    wav_path = wav_file.name
    wav_file.close()

    try:
        subprocess.run(
            ["ffmpeg", "-y", "-i", path, "-ac", "1", "-ar", "16000", wav_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return wav_path, wav_path
    except (FileNotFoundError, subprocess.CalledProcessError):
        try:
            os.remove(wav_path)
        except FileNotFoundError:
            pass
        return path, None


def levenshtein_score(target: str, transcription: str) -> tuple[float, dict[str, int]]:
    target_words = target.lower().split()
    transcription_words = transcription.lower().split()
    alignment: dict[str, int] = {}
    matches = 0

    for index, word in enumerate(target_words):
        matched = word in transcription_words
        alignment[f"{index}_{word}"] = 100 if matched else 0
        matches += 1 if matched else 0

    if not target_words:
        return 0.0, alignment

    return round((matches / len(target_words)) * 100, 2), alignment


def load_model() -> dict[str, Any]:
    global _model
    if _model is not None:
        return _model

    try:
        import torch
        import librosa
        from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor

        processor = Wav2Vec2Processor.from_pretrained(MODEL_NAME)
        model = Wav2Vec2ForCTC.from_pretrained(MODEL_NAME)
        _model = {"torch": torch, "librosa": librosa, "processor": processor, "model": model}
        return _model
    except Exception as exc:
        raise RuntimeError(f"Model tidak dapat dimuat: {exc}") from exc


def transcribe(path: str) -> str:
    bundle = load_model()
    torch = bundle["torch"]
    librosa = bundle["librosa"]
    processor = bundle["processor"]
    model = bundle["model"]

    speech, _ = librosa.load(path, sr=16000)
    inputs = processor(speech, sampling_rate=16000, return_tensors="pt", padding=True)

    with torch.no_grad():
        logits = model(inputs.input_values).logits

    predicted_ids = torch.argmax(logits, dim=-1)
    transcription = processor.batch_decode(predicted_ids)[0]
    return str(transcription).strip().lower()


@app.exception_handler(HTTPException)
async def http_exception_handler(_, exc: HTTPException) -> JSONResponse:
    return error_response(str(exc.detail), "SPEAKING_AI_VALIDATION_ERROR", exc.status_code)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "engine": ENGINE, "model": MODEL_NAME}


@app.post("/predict")
async def predict(target_text: str = Form(...), file: UploadFile = File(...)) -> JSONResponse:
    if not target_text.strip():
        raise HTTPException(status_code=422, detail="target_text wajib diisi.")

    validate_upload(file)
    suffix = Path(file.filename or "recording.wav").suffix.lower()
    if suffix not in SAFE_EXTENSIONS:
        suffix = ".wav"

    temp_path = None
    converted_path = None

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_path = temp_file.name
            total = 0
            while chunk := await file.read(1024 * 1024):
                total += len(chunk)
                if total > MAX_FILE_SIZE_BYTES:
                    raise HTTPException(status_code=422, detail="Ukuran audio melebihi batas.")
                temp_file.write(chunk)

        transcription_path, converted_path = prepare_audio_for_transcription(temp_path)
        transcription = transcribe(transcription_path)
        score, alignment = levenshtein_score(target_text, transcription)

        return JSONResponse({
            "engine": ENGINE,
            "model": MODEL_NAME,
            "target": target_text,
            "transcription": transcription,
            "score": score,
            "alignment": alignment,
            "warnings": [WARNING],
        })
    except HTTPException:
        raise
    except Exception as exc:
        return error_response(str(exc), "SPEAKING_AI_ERROR", 500)
    finally:
        await file.close()
        for path in [converted_path, temp_path]:
            if path:
                try:
                    os.remove(path)
                except FileNotFoundError:
                    pass
