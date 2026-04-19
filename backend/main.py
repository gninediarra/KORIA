"""
GabèsEye Backend — FastAPI
H12 Innovation Hackathon: AI Healing Gabès

Axes: Sol (U-Net + LSTM + Mahalanobis) | Eau (U-Net + LSTM) | Air (XGBoost + Gaussian Plume + LSTM)
Data: Sentinel-2 Satellite + DroneSimulator (Digital Twin) + Thermal Simulation
LLM: Groq Llama-3.3-70b-versatile (multilingual: FR/AR/EN/Tamazight)
"""
import asyncio
import json
import os
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Query, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from services import zone_engine, alert_engine, lstm_engine, agent_engine, drone_engine

# ─────────────────────────── App setup ──────────────────────────────────────

BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / "data"
_zones_config: dict = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _zones_config
    zones_file = DATA_DIR / "zones.json"
    if zones_file.exists():
        _zones_config = json.loads(zones_file.read_text(encoding="utf-8"))
    groq_key = os.getenv("GROQ_API_KEY", "")
    print("GabesEye Backend ready")
    print("  Zones:", list(_zones_config.get("zones", {}).keys()))
    print("  Groq API key:", "SET" if groq_key else "MISSING — LLM agents will use fallback")
    yield


app = FastAPI(
    title="GabèsEye API",
    description="AI-powered environmental monitoring for Gabès — H12 Hackathon",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────── Models ─────────────────────────────────────────

class AgentRequest(BaseModel):
    zone_id: str = "gct"
    langue: str = "fr"
    question: str = ""
    profil: dict = {}


class ChatRequest(BaseModel):
    message: str
    history: list = []
    role: str = "citoyen"
    langue: str = "fr"
    zone_id: str = "gct"


class MissionRequest(BaseModel):
    zone_id: str = "gct"
    waypoints: list = []


# ─────────────────────────── Health ─────────────────────────────────────────

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def root():
    html_file = BASE_DIR / "static" / "index.html"
    if html_file.exists():
        return HTMLResponse(html_file.read_text(encoding="utf-8"))
    return HTMLResponse("<h1>GabèsEye API</h1><p><a href='/docs'>Swagger docs</a></p>")


@app.get("/api/status", tags=["Status"])
async def api_status():
    return {
        "project": "GabèsEye",
        "version": "1.0.0",
        "hackathon": "H12 Innovation — AI Healing Gabès",
        "axes": ["sol", "eau", "air"],
        "status": "operational",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/health", tags=["Status"])
async def health():
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}


# ─────────────────────────── Zones ──────────────────────────────────────────

@app.get("/zones", tags=["Zones"])
async def get_zones():
    """All zone definitions with geographic info."""
    return _zones_config.get("zones", {})


@app.get("/zones/{zone_id}", tags=["Zones"])
async def get_zone(zone_id: str):
    zones = _zones_config.get("zones", {})
    if zone_id not in zones:
        raise HTTPException(404, f"Zone '{zone_id}' not found. Available: {list(zones.keys())}")
    return zones[zone_id]


# ─────────────────────────── Sol ─────────────────────────────────────────────

@app.get("/sol/{zone_id}", tags=["Sol"])
async def analyze_sol(zone_id: str, use_satellite: bool = False):
    """
    Soil analysis: U-Net segmentation + Mahalanobis anomaly detection.
    Returns health score, contamination %, class distribution.
    """
    return zone_engine.analyze_zone_sol(zone_id, use_satellite=use_satellite)


@app.get("/sol/{zone_id}/timeline", tags=["Sol"])
async def sol_timeline(zone_id: str):
    """Historical soil contamination 2018→2025."""
    return zone_engine.get_contamination_timeline(zone_id)


@app.get("/sol/{zone_id}/predict", tags=["Sol"])
async def predict_sol(
    zone_id: str,
    steps: int = Query(12, ge=1, le=60),
    freq: str = Query("monthly", pattern="^(monthly|daily|hourly)$"),
):
    """LSTM soil health prediction — default 12 months ahead."""
    return lstm_engine.predict_sol(zone_id, steps=steps, freq=freq)


@app.get("/sol/{zone_id}/crop-yield", tags=["Sol"])
async def crop_yield(zone_id: str, culture: str = "olivier"):
    """Predict crop yield impact from soil degradation (2024-2030)."""
    return lstm_engine.predict_crop_yield(zone_id, culture=culture)


# ─────────────────────────── Eau ─────────────────────────────────────────────

@app.get("/eau/{zone_id}", tags=["Eau"])
async def analyze_eau(zone_id: str, use_satellite: bool = False):
    """
    Water quality analysis: U-Net segmentation, turbidity index, anomaly detection.
    """
    return zone_engine.analyze_zone_eau(zone_id, use_satellite=use_satellite)


@app.get("/eau/{zone_id}/predict", tags=["Eau"])
async def predict_eau(
    zone_id: str,
    steps: int = Query(12, ge=1, le=60),
    freq: str = Query("monthly", pattern="^(monthly|daily|hourly)$"),
):
    """LSTM water turbidity prediction."""
    return lstm_engine.predict_eau(zone_id, steps=steps, freq=freq)


# ─────────────────────────── Air ─────────────────────────────────────────────

@app.get("/air/{zone_id}/realtime", tags=["Air"])
async def air_realtime(zone_id: str):
    """
    Real-time air quality: Open-Meteo + XGBoost episode prediction + Gaussian Plume.
    """
    return await alert_engine.get_realtime_alert(zone_id)


@app.get("/air/{zone_id}/predict", tags=["Air"])
async def predict_air(
    zone_id: str,
    steps: int = Query(30, ge=1, le=90),
    freq: str = Query("daily", pattern="^(monthly|daily|hourly)$"),
):
    """LSTM AQI prediction — default 30 days ahead."""
    return lstm_engine.predict_air(zone_id, steps=steps, freq=freq)


@app.get("/air/plume/{zone_id}", tags=["Air"])
async def gaussian_plume(
    zone_id: str,
    emission_rate: float = Query(85.0, ge=0),
    stack_height: float = Query(120.0, ge=0),
    wind_speed: float = Query(4.0, ge=0.1),
    stability: str = Query("D", pattern="^[ABCDEF]$"),
):
    """
    Gaussian Plume SO₂ dispersion model.
    stability: A (very unstable) → F (very stable), D = neutral.
    """
    result = alert_engine.gaussian_plume(
        Q=emission_rate,
        H=stack_height,
        u=wind_speed,
        stability=stability,
    )
    # Remove full grid from response for performance (available in /air/plume/grid)
    result.pop("grid", None)
    return result


@app.get("/air/plume/{zone_id}/grid", tags=["Air"])
async def gaussian_plume_grid(
    zone_id: str,
    wind_speed: float = Query(4.0, ge=0.1),
    stability: str = Query("D", pattern="^[ABCDEF]$"),
):
    """Full concentration grid for map visualization."""
    return alert_engine.gaussian_plume(Q=85.0, H=120.0, u=wind_speed, stability=stability)


# ─────────────────────────── Dashboard ───────────────────────────────────────

@app.get("/dashboard", tags=["Dashboard"])
async def dashboard():
    """
    Predictive dashboard — all zones, all axes, latest status.
    Used by React website home page.
    """
    all_zones = list(_zones_config.get("zones", {}).keys())
    results = {}

    for zone_id in all_zones:
        sol = zone_engine.analyze_zone_sol(zone_id)
        eau = zone_engine.analyze_zone_eau(zone_id)
        results[zone_id] = {
            "sol": {
                "health_score": sol["health_score"],
                "contamination_pct": sol["contamination_pct"],
                "status": sol["status"],
            },
            "eau": {
                "turbidite": eau["turbidite"],
                "contamination_pct": eau["contamination_pct"],
                "status": eau["status"],
            },
            "zone_info": _zones_config["zones"][zone_id],
        }

    air = await alert_engine.get_realtime_alert("gct")

    return {
        "timestamp": datetime.utcnow().isoformat(),
        "zones": results,
        "air_quality": {
            "aqi": air["air_quality"]["aqi"],
            "alert_level": air["global_alert_level"],
            "so2": air["air_quality"]["so2"],
            "pm10": air["air_quality"]["pm10"],
        },
        "meteo": air["meteo"],
        "cascade_alert": air["cascade_alert"],
        "recommendations": air["recommendations"],
    }


# ─────────────────────────── Agents ───────────────────────────────────────────

@app.post("/agent/agriculteur", tags=["Agents"])
async def agent_agriculteur(req: AgentRequest):
    """Multilingual AI agent for farmers (sol + meteo analysis)."""
    sol_data = zone_engine.analyze_zone_sol(req.zone_id)
    meteo, _ = await asyncio.gather(
        alert_engine.fetch_weather_openmeteo(),
        asyncio.sleep(0),
    )
    return await agent_engine.recommandation_agriculteur(
        zone_data={"sol": sol_data, "meteo": meteo},
        langue=req.langue,
        question=req.question,
    )


@app.post("/agent/pecheur", tags=["Agents"])
async def agent_pecheur(req: AgentRequest):
    """Multilingual AI agent for fishermen (water quality + marine weather)."""
    eau_data = zone_engine.analyze_zone_eau(req.zone_id)
    meteo = await alert_engine.fetch_weather_openmeteo()
    return await agent_engine.alerte_pecheur(eau_data, meteo, langue=req.langue)


@app.post("/agent/citoyen", tags=["Agents"])
async def agent_citoyen(req: AgentRequest):
    """Multilingual AI agent for citizens (air quality health advice)."""
    air_data = await alert_engine.fetch_air_quality_openmeteo()
    return await agent_engine.alerte_citoyen(air_data, langue=req.langue)


@app.post("/agent/autorite", tags=["Agents"])
async def agent_autorite(req: AgentRequest):
    """Full multi-axis official report for authorities."""
    sol = zone_engine.analyze_zone_sol(req.zone_id)
    eau = zone_engine.analyze_zone_eau(req.zone_id)
    air_task, meteo_task = await asyncio.gather(
        alert_engine.fetch_air_quality_openmeteo(),
        alert_engine.fetch_weather_openmeteo(),
    )
    return await agent_engine.rapport_autorite(
        all_data={"sol": sol, "eau": eau, "air": air_task, "meteo": meteo_task},
        langue=req.langue,
    )


@app.post("/agent/chat", tags=["Agents"])
async def agent_chat(req: ChatRequest):
    """General conversational agent — multi-turn dialogue."""
    air_data = await alert_engine.fetch_air_quality_openmeteo()
    sol_data = zone_engine.analyze_zone_sol(req.zone_id)
    return await agent_engine.conversational_agent(
        message=req.message,
        history=req.history,
        role=req.role,
        langue=req.langue,
        context_data={"sol": sol_data, "air": air_data},
    )


@app.post("/agent/health-risk", tags=["Agents"])
async def agent_health_risk(req: AgentRequest):
    """Personalized health risk assessment."""
    air_data = await alert_engine.fetch_air_quality_openmeteo()
    return await agent_engine.health_risk_personalized(
        zone_id=req.zone_id,
        air_data=air_data,
        profil=req.profil,
    )


# ─────────────────────────── Drone ─────────────────────────────────────────

@app.get("/drone/status", tags=["Drone"])
async def drone_status():
    """Drone Digital Twin system status."""
    return drone_engine.get_mission_status("system")


@app.get("/drone/thermal", tags=["Drone"])
async def thermal_image(
    lat: float = Query(33.852, ge=30, le=37),
    lon: float = Query(9.978, ge=8, le=13),
    zone_id: str = "gct",
):
    """Simulate thermal camera capture at given coordinates."""
    return drone_engine.simulate_thermal_image(lat=lat, lon=lon, zone_id=zone_id)


# ─────────────────────────── WebSockets ────────────────────────────────────

@app.websocket("/ws/drone/{mission_id}")
async def ws_drone(websocket: WebSocket, mission_id: str, zone_id: str = "gct"):
    """
    WebSocket: real-time drone telemetry + AI inference.
    Streams 1 packet/second during simulated mission.
    Connect: ws://localhost:8000/ws/drone/{mission_id}?zone_id=gct
    """
    await websocket.accept()
    try:
        simulator = drone_engine.DroneSimulator(mission_id=mission_id, zone_id=zone_id)
        await websocket.send_json({
            "type": "mission_start",
            "mission_id": mission_id,
            "zone_id": zone_id,
            "waypoints": drone_engine.DEFAULT_WAYPOINTS,
            "timestamp": datetime.utcnow().isoformat(),
        })

        async for packet in simulator.stream_telemetry():
            await websocket.send_json({"type": "telemetry", **packet})
            await asyncio.sleep(1.0)  # 1 packet/second

        await websocket.send_json({"type": "mission_end", "mission_id": mission_id})
    except WebSocketDisconnect:
        print(f"[WS] Drone client disconnected: {mission_id}")
    except Exception as e:
        await websocket.send_json({"type": "error", "message": str(e)})
        await websocket.close()


@app.websocket("/ws/live/{role}")
async def ws_live(websocket: WebSocket, role: str = "citoyen", langue: str = "fr"):
    """
    WebSocket: 30-second interval live environmental updates.
    role: citoyen | agriculteur | pecheur
    Sends: AQI + wind + alert level + zone status.
    Connect: ws://localhost:8000/ws/live/citoyen?langue=fr
    """
    await websocket.accept()
    try:
        await websocket.send_json({
            "type": "connected",
            "role": role,
            "message": "GabèsEye live monitoring active",
            "update_interval_s": 30,
        })
        while True:
            air = await alert_engine.get_realtime_alert("gct")
            sol_gct = zone_engine.analyze_zone_sol("gct")

            update = {
                "type": "live_update",
                "timestamp": datetime.utcnow().isoformat(),
                "air_quality": {
                    "aqi": air["air_quality"]["aqi"],
                    "so2": air["air_quality"]["so2"],
                    "pm10": air["air_quality"]["pm10"],
                    "alert_level": air["global_alert_level"],
                },
                "meteo": air["meteo"],
                "cascade_alert": air["cascade_alert"],
                "sol_status": sol_gct["status"],
                "recommendations": air["recommendations"][:2],
            }

            # Add role-specific data
            if role == "pecheur":
                eau = zone_engine.analyze_zone_eau("mer")
                update["eau"] = {"turbidite": eau["turbidite"], "status": eau["status"]}
            elif role == "agriculteur":
                sol_oasis = zone_engine.analyze_zone_sol("oasis")
                update["sol_oasis"] = {"health_score": sol_oasis["health_score"], "status": sol_oasis["status"]}

            await websocket.send_json(update)
            await asyncio.sleep(30)
    except WebSocketDisconnect:
        print(f"[WS] Live client disconnected: role={role}")
    except Exception as e:
        print(f"[WS] Error: {e}")


# ─────────────────────────── Map ─────────────────────────────────────────────

@app.get("/map/living", tags=["Map"])
async def living_map():
    """
    Living Contamination Map — all zones snapshot for frontend Leaflet/Mapbox.
    Returns GeoJSON-compatible zone data with current status.
    """
    zones = _zones_config.get("zones", {})
    features = []

    for zone_id, zone_info in zones.items():
        sol = zone_engine.analyze_zone_sol(zone_id)
        eau = zone_engine.analyze_zone_eau(zone_id)
        bbox = zone_info["bbox"]
        centre = zone_info["centre"]

        # GeoJSON Feature
        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Polygon",
                "coordinates": [[
                    [bbox[0], bbox[1]],
                    [bbox[2], bbox[1]],
                    [bbox[2], bbox[3]],
                    [bbox[0], bbox[3]],
                    [bbox[0], bbox[1]],
                ]],
            },
            "properties": {
                "zone_id": zone_id,
                "nom": zone_info["nom"],
                "nom_ar": zone_info["nom_ar"],
                "couleur": zone_info["couleur"],
                "sol_status": sol["status"],
                "sol_health": sol["health_score"],
                "sol_contamination_pct": sol["contamination_pct"],
                "eau_status": eau["status"],
                "eau_turbidite": eau["turbidite"],
                "global_status": sol["status"] if sol["status"] == "rouge" else eau["status"],
                "centre_lat": centre[0],
                "centre_lon": centre[1],
                "popup_html": (
                    f"<b>{zone_info['nom']}</b><br>"
                    f"Sol: {sol['contamination_pct']}% contaminé ({sol['status']})<br>"
                    f"Eau: turbidité {eau['turbidite']} ({eau['status']})<br>"
                    f"Score santé: {sol['health_score']}/100"
                ),
            },
        })

    air = await alert_engine.get_realtime_alert("gct")
    pollution_sources = _zones_config.get("sources_pollution", [])

    return {
        "type": "FeatureCollection",
        "features": features,
        "air_quality": air["air_quality"],
        "meteo": air["meteo"],
        "pollution_sources": pollution_sources,
        "timestamp": datetime.utcnow().isoformat(),
    }


# ─────────────────────────── TTS + Transcription ────────────────────────────

@app.get("/api/tts", tags=["Voice"])
async def text_to_speech(text: str = Query(..., max_length=1000), lang: str = Query("fr")):
    """
    Convert text to speech via gTTS. lang: fr | en | ar
    Returns audio/mpeg stream.
    """
    try:
        import io
        from gtts import gTTS
        tts = gTTS(text=text, lang=lang, slow=False)
        buf = io.BytesIO()
        tts.write_to_fp(buf)
        buf.seek(0)
        return StreamingResponse(buf, media_type="audio/mpeg",
                                 headers={"Cache-Control": "no-store"})
    except Exception as e:
        raise HTTPException(500, f"TTS error: {e}")


@app.post("/api/transcribe", tags=["Voice"])
async def transcribe_audio(audio: UploadFile = File(...), lang: str = Query("fr")):
    """
    Transcribe audio blob via Groq Whisper (whisper-large-v3-turbo).
    Accepts audio/webm or any audio format.
    """
    import aiohttp as _aiohttp
    groq_key = os.getenv("GROQ_API_KEY", "")
    if not groq_key:
        raise HTTPException(503, "GROQ_API_KEY not set — transcription unavailable")
    try:
        audio_bytes = await audio.read()
        content_type = audio.content_type or "audio/webm"
        async with _aiohttp.ClientSession() as session:
            form = _aiohttp.FormData()
            form.add_field("file", audio_bytes,
                           filename="audio.webm", content_type=content_type)
            form.add_field("model", "whisper-large-v3-turbo")
            if lang in ("fr", "en", "ar"):
                form.add_field("language", lang)
            async with session.post(
                "https://api.groq.com/openai/v1/audio/transcriptions",
                headers={"Authorization": f"Bearer {groq_key}"},
                data=form,
            ) as resp:
                result = await resp.json()
                if resp.status != 200:
                    raise HTTPException(500, f"Whisper API error: {result}")
                return {"text": result.get("text", ""), "language": lang}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Transcription error: {e}")


# ─────────────────────────── Static assets (css/js if needed) ───────────────

_static_dir = BASE_DIR / "static"
if _static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(_static_dir)), name="static")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
