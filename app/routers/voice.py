"""
Voice endpoints:
  GET  /api/tts         — text-to-speech via gTTS (fr/en/ar)
  POST /api/transcribe  — audio-to-text via Groq Whisper
"""
import os
import io
import aiohttp
from fastapi import APIRouter, Query, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse
from datetime import datetime

router = APIRouter(prefix="/api", tags=["Voice"])

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
WHISPER_MODEL = "whisper-large-v3-turbo"


@router.get("/tts")
async def text_to_speech(
    text: str = Query(..., max_length=1000),
    lang: str = Query("fr"),
):
    """Convert text to speech. lang: fr | en | ar"""
    try:
        from gtts import gTTS
    except ImportError:
        raise HTTPException(status_code=503, detail="gTTS non installé — pip install gtts")

    lang_map = {"fr": "fr", "en": "en", "ar": "ar"}
    gtts_lang = lang_map.get(lang, "fr")

    try:
        tts = gTTS(text=text, lang=gtts_lang, slow=False)
        buf = io.BytesIO()
        tts.write_to_fp(buf)
        buf.seek(0)
        return StreamingResponse(buf, media_type="audio/mpeg")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur TTS: {str(e)}")


@router.post("/transcribe")
async def transcribe_audio(
    audio: UploadFile = File(...),
    lang: str = Query("fr"),
):
    """Transcribe audio via Groq Whisper."""
    if not GROQ_API_KEY:
        raise HTTPException(status_code=503, detail="GROQ_API_KEY non configuré")

    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Fichier audio vide")

    lang_map = {"fr": "fr", "en": "en", "ar": "ar"}
    whisper_lang = lang_map.get(lang, "fr")

    try:
        data = aiohttp.FormData()
        data.add_field("file", audio_bytes, filename=audio.filename or "recording.webm",
                       content_type=audio.content_type or "audio/webm")
        data.add_field("model", WHISPER_MODEL)
        data.add_field("language", whisper_lang)
        data.add_field("response_format", "json")

        headers = {"Authorization": f"Bearer {GROQ_API_KEY}"}
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as s:
            async with s.post(
                "https://api.groq.com/openai/v1/audio/transcriptions",
                headers=headers,
                data=data,
            ) as resp:
                if resp.status == 200:
                    result = await resp.json()
                    return {
                        "text": result.get("text", ""),
                        "langue": lang,
                        "timestamp": datetime.utcnow().isoformat(),
                    }
                err = await resp.text()
                raise HTTPException(status_code=resp.status, detail=f"Erreur Groq: {err}")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur transcription: {str(e)}")
