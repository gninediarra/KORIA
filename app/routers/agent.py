"""
AI Agent endpoints (Mané-style public routes, no auth required):
  POST /agent/agriculteur
  POST /agent/pecheur
  POST /agent/citoyen
  POST /agent/autorite
  POST /agent/chat
  POST /agent/health-risk
  POST /agent/analyze-image   — vision analysis via Groq + Token Factory
"""
import os
import base64
import aiohttp
from fastapi import APIRouter, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional
from app.services import agent_engine
from app.services.zone_analysis import analyze_zone_sol, analyze_zone_eau
from app.services.realtime_engine import get_realtime_alert, ZONE_COORDS
import asyncio
from datetime import datetime

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
TOKEN_FACTORY_API_KEY = os.getenv("TOKEN_FACTORY_API_KEY", "sk-f3afa662c42946bd9df8cbcb50e22267")
TOKEN_FACTORY_BASE_URL = os.getenv("TOKEN_FACTORY_BASE_URL", "https://api.tokensfactory.io/v1")

router = APIRouter(prefix="/agent", tags=["AI Agents"])


class AgentRequest(BaseModel):
    zone_id: str = "gct"
    langue: str = "fr"
    question: str = ""


class ChatRequest(BaseModel):
    message: str
    history: list = []
    role: str = "citoyen"
    langue: str = "fr"
    zone_id: str = "gct"


class HealthRiskRequest(BaseModel):
    zone_id: str = "gct"
    langue: str = "fr"
    profil: dict = {}


async def _build_zone_context(zone_id: str) -> dict:
    """Build zone context from real-time analysis data."""
    sol = analyze_zone_sol(zone_id)
    eau = analyze_zone_eau(zone_id)
    air_data = await get_realtime_alert(zone_id)
    aq = air_data.get("air_quality", {})
    meteo = air_data.get("meteo", {})
    return {
        "zone_name": f"Zone {zone_id.upper()}",
        "sol": {
            "salinite": sol.get("indices", {}).get("NDSI", 0) * 10,
            "contamination": sol.get("contamination_pct", 0),
            "humidite": abs(sol.get("indices", {}).get("NDWI", 0)) * 100,
            "etat": sol.get("status", "vert"),
        },
        "eau": {
            "turbidite": eau.get("turbidite", 0) * 100,
            "phosphates": abs(eau.get("indices", {}).get("NDCI", 0)) * 10,
            "ph": 7.2,
            "etat": eau.get("status", "vert"),
        },
        "air": {
            "aqi": aq.get("aqi", 0),
            "so2": aq.get("so2", 0),
            "h2s": 0,
            "pm25": aq.get("pm25", 0),
            "etat": aq.get("alert_level", "—"),
        },
        "meteo": {
            "temperature": meteo.get("temperature", 25),
            "vent": meteo.get("wind_speed", 4),
        },
    }


@router.post("/agriculteur")
async def agent_agriculteur(body: AgentRequest):
    ctx = await _build_zone_context(body.zone_id)
    return await agent_engine.role_agent(
        role="agriculteur",
        zone_data=ctx,
        langue=body.langue,
        question=body.question,
    )


@router.post("/pecheur")
async def agent_pecheur(body: AgentRequest):
    ctx = await _build_zone_context(body.zone_id)
    return await agent_engine.role_agent(
        role="pecheur",
        zone_data=ctx,
        langue=body.langue,
        question=body.question,
    )


@router.post("/citoyen")
async def agent_citoyen(body: AgentRequest):
    ctx = await _build_zone_context(body.zone_id)
    return await agent_engine.role_agent(
        role="citoyen",
        zone_data=ctx,
        langue=body.langue,
        question=body.question,
    )


@router.post("/autorite")
async def agent_autorite(body: AgentRequest):
    ctx = await _build_zone_context(body.zone_id)
    return await agent_engine.role_agent(
        role="autorite",
        zone_data=ctx,
        langue=body.langue,
        question=body.question,
    )


@router.post("/chat")
async def agent_chat(body: ChatRequest):
    ctx = await _build_zone_context(body.zone_id)
    return await agent_engine.conversational_agent(
        message=body.message,
        history=body.history,
        role=body.role,
        langue=body.langue,
        zone_data=ctx,
    )


@router.post("/health-risk")
async def agent_health_risk(body: HealthRiskRequest):
    ctx = await _build_zone_context(body.zone_id)
    profil = {"langue": body.langue, **body.profil}
    return await agent_engine.health_risk(zone_data=ctx, profil=profil)


# ── Image / file analysis ─────────────────────────────────────────────────────

async def _analyze_with_groq_vision(image_b64: str, mime: str, question: str, langue: str) -> str:
    """Use Groq LLaMA-4 vision model to analyze image."""
    if not GROQ_API_KEY:
        return None
    lang_map = {"fr": "French", "ar": "Arabic", "en": "English"}
    lang = lang_map.get(langue, "French")

    system = f"""Tu es GabèsEye VisionBot, expert en analyse environnementale.
Analyse les images envoyées par les citoyens de Gabès, Tunisie.
Tu identifies: contamination de l'eau, déchets industriels, pollution visible, état des sols.
Réponds toujours en {lang}. Sois précis, scientifique, et donne des recommandations pratiques.
Si tu détectes un danger, indique clairement le niveau de risque (faible/modéré/élevé/critique)."""

    payload = {
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "messages": [
            {"role": "system", "content": system},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{mime};base64,{image_b64}"},
                    },
                    {"type": "text", "text": question or "Analyse cette image et donne ton évaluation environnementale."},
                ],
            },
        ],
        "temperature": 0.3,
        "max_tokens": 800,
    }
    headers = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as s:
            async with s.post("https://api.groq.com/openai/v1/chat/completions",
                              headers=headers, json=payload) as r:
                if r.status == 200:
                    data = await r.json()
                    return data["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"[VisionBot] Groq error: {e}")
    return None


async def _analyze_with_token_factory(image_b64: str, mime: str, question: str, langue: str) -> str:
    """Fallback: use Token Factory vision API."""
    lang_map = {"fr": "French", "ar": "Arabic", "en": "English"}
    lang = lang_map.get(langue, "French")

    payload = {
        "model": "gpt-4o",
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{image_b64}"}},
                    {"type": "text", "text": f"[Respond in {lang}] {question or 'Analyse this image for environmental contamination.'}"},
                ],
            }
        ],
        "max_tokens": 800,
        "temperature": 0.3,
    }
    headers = {"Authorization": f"Bearer {TOKEN_FACTORY_API_KEY}", "Content-Type": "application/json"}
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as s:
            async with s.post(f"{TOKEN_FACTORY_BASE_URL}/chat/completions",
                              headers=headers, json=payload) as r:
                if r.status == 200:
                    data = await r.json()
                    return data["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"[VisionBot] Token Factory error: {e}")
    return None


@router.post("/analyze-image")
async def analyze_image(
    file: UploadFile = File(...),
    question: str = Form(default=""),
    langue: str = Form(default="fr"),
    zone_id: str = Form(default="gct"),
):
    """
    Analyze an image or file for environmental content.
    - Water contamination detection
    - Industrial waste identification
    - Soil degradation assessment
    Uses Groq LLaMA-4 vision → Token Factory fallback.
    """
    raw = await file.read()
    if not raw:
        return {"error": "Fichier vide"}

    mime = file.content_type or "image/jpeg"
    image_b64 = base64.b64encode(raw).decode("utf-8")

    # Enrich question with zone context
    zone_ctx = ""
    try:
        air = await get_realtime_alert(zone_id)
        aq = air.get("air_quality", {})
        zone_ctx = f" (Zone: {zone_id.upper()}, AQI={aq.get('aqi', '?')}, SO₂={aq.get('so2', '?')} µg/m³)"
    except Exception:
        pass

    full_question = f"{question}{zone_ctx}".strip() or "Analyse cette image pour détecter toute contamination ou problème environnemental."

    # Try Groq first, fall back to Token Factory
    response = await _analyze_with_groq_vision(image_b64, mime, full_question, langue)
    if not response:
        response = await _analyze_with_token_factory(image_b64, mime, full_question, langue)
    if not response:
        response = "❌ Service d'analyse d'image indisponible. Vérifiez GROQ_API_KEY ou TOKEN_FACTORY_API_KEY."

    return {
        "response": response,
        "agent": "vision_bot",
        "langue": langue,
        "zone_id": zone_id,
        "file_type": mime,
        "timestamp": datetime.utcnow().isoformat(),
    }
