"""
AlertEngine — Real-time air quality + Gaussian Plume SO₂ dispersion.
Data sources: Open-Meteo API (free, no key) + XGBoost classifier.
"""
import json
import math
import asyncio
import aiohttp
import numpy as np
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

BASE_DIR = Path(__file__).parent.parent
MODELS_DIR = BASE_DIR / "models"

_xgb_model = None

# Pasquill-Gifford stability class sigma parameters
_PG_PARAMS = {
    "A": {"sy_a": 0.22, "sy_b": 0.0001, "sz_a": 0.20, "sz_b": 0.000},
    "B": {"sy_a": 0.16, "sy_b": 0.0001, "sz_a": 0.12, "sz_b": 0.000},
    "C": {"sy_a": 0.11, "sy_b": 0.0001, "sz_a": 0.08, "sz_b": 0.0002},
    "D": {"sy_a": 0.08, "sy_b": 0.0001, "sz_a": 0.06, "sz_b": 0.0015},
    "E": {"sy_a": 0.06, "sy_b": 0.0001, "sz_a": 0.03, "sz_b": 0.0003},
    "F": {"sy_a": 0.04, "sy_b": 0.0001, "sz_a": 0.016, "sz_b": 0.0003},
}


def _load_xgb():
    global _xgb_model
    if _xgb_model is not None:
        return _xgb_model
    import pickle
    model_path = MODELS_DIR / "xgb_air.pkl"
    if not model_path.exists():
        return None
    try:
        with open(model_path, "rb") as f:
            _xgb_model = pickle.load(f)
        return _xgb_model
    except Exception as e:
        print(f"[AlertEngine] Cannot load XGBoost: {e}")
        return None


async def fetch_weather_openmeteo(lat: float = 33.88, lon: float = 10.10) -> dict:
    """Fetch current weather from Open-Meteo (free, no API key)."""
    url = (
        f"https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lon}"
        f"&current=temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,"
        f"surface_pressure,precipitation,cloud_cover"
        f"&hourly=temperature_2m,wind_speed_10m,wind_direction_10m&forecast_days=1"
        f"&timezone=Africa/Tunis"
    )
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=10)) as session:
            async with session.get(url) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    c = data.get("current", {})
                    return {
                        "temperature": c.get("temperature_2m", 25.0),
                        "humidity": c.get("relative_humidity_2m", 60.0),
                        "wind_speed": c.get("wind_speed_10m", 4.0),
                        "wind_direction": c.get("wind_direction_10m", 270.0),
                        "pressure": c.get("surface_pressure", 1013.0),
                        "precipitation": c.get("precipitation", 0.0),
                        "cloud_cover": c.get("cloud_cover", 30.0),
                        "source": "open-meteo",
                        "timestamp": datetime.utcnow().isoformat(),
                    }
    except Exception:
        pass
    # Fallback — realistic Gabès values
    return {
        "temperature": 28.0,
        "humidity": 55.0,
        "wind_speed": 5.2,
        "wind_direction": 270.0,
        "pressure": 1013.0,
        "precipitation": 0.0,
        "cloud_cover": 20.0,
        "source": "fallback",
        "timestamp": datetime.utcnow().isoformat(),
    }


async def fetch_air_quality_openmeteo(lat: float = 33.88, lon: float = 10.10) -> dict:
    """Fetch air quality from Open-Meteo Air Quality API."""
    url = (
        f"https://air-quality-api.open-meteo.com/v1/air-quality?"
        f"latitude={lat}&longitude={lon}"
        f"&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,european_aqi"
        f"&hourly=pm10,pm2_5,sulphur_dioxide&forecast_days=1"
        f"&timezone=Africa/Tunis"
    )
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=10)) as session:
            async with session.get(url) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    c = data.get("current", {})
                    aqi = c.get("european_aqi", 0) or 0
                    pm10 = c.get("pm10", 0) or 0
                    pm25 = c.get("pm2_5", 0) or 0
                    so2 = c.get("sulphur_dioxide", 0) or 0
                    no2 = c.get("nitrogen_dioxide", 0) or 0
                    o3 = c.get("ozone", 0) or 0
                    co = c.get("carbon_monoxide", 0) or 0
                    return {
                        "aqi": round(float(aqi), 1),
                        "pm10": round(float(pm10), 1),
                        "pm25": round(float(pm25), 1),
                        "so2": round(float(so2), 1),
                        "no2": round(float(no2), 1),
                        "o3": round(float(o3), 1),
                        "co": round(float(co), 1),
                        "alert_level": _aqi_to_level(aqi),
                        "source": "open-meteo-air",
                        "timestamp": datetime.utcnow().isoformat(),
                    }
    except Exception:
        pass
    # Fallback based on Kaggle findings — GCT zone typical values
    return {
        "aqi": 112.0,
        "pm10": 87.3,
        "pm25": 42.1,
        "so2": 95.4,
        "no2": 38.2,
        "o3": 62.0,
        "co": 0.8,
        "alert_level": "mauvais",
        "source": "fallback",
        "timestamp": datetime.utcnow().isoformat(),
    }


def _aqi_to_level(aqi: float) -> str:
    if aqi <= 50:
        return "bon"
    elif aqi <= 100:
        return "modere"
    elif aqi <= 150:
        return "mauvais"
    elif aqi <= 200:
        return "tres_mauvais"
    return "dangereux"


def _wind_to_stability_class(wind_speed: float, cloud_cover: float, hour: int = 12) -> str:
    """Estimate Pasquill-Gifford stability class from wind & cloud."""
    is_day = 7 <= hour <= 19
    if wind_speed < 2:
        return "A" if is_day and cloud_cover < 30 else "F"
    elif wind_speed < 3:
        return "B" if is_day else "E"
    elif wind_speed < 5:
        return "C" if is_day else "D"
    elif wind_speed < 6:
        return "D"
    return "D"


def gaussian_plume(
    Q: float,          # Emission rate [g/s]
    H: float,          # Stack height [m]
    u: float,          # Wind speed [m/s]
    stability: str,    # Pasquill-Gifford class
    x_range: float = 5000,   # Max downwind distance [m]
    y_range: float = 2000,   # Cross-wind range [m]
    nx: int = 100,
    ny: int = 80,
) -> dict:
    """
    Gaussian Plume Model for SO₂ dispersion.
    Returns concentration grid + risk zones.
    """
    params = _PG_PARAMS.get(stability, _PG_PARAMS["D"])
    x_vals = np.linspace(50, x_range, nx)
    y_vals = np.linspace(-y_range, y_range, ny)
    X, Y = np.meshgrid(x_vals, y_vals)

    u = max(u, 0.5)
    sy = params["sy_a"] * X * (1 + params["sy_b"] * X) ** (-0.5)
    sz = params["sz_a"] * X * np.exp(-params["sz_b"] * (np.log(X)) ** 2)

    # Concentration at ground level z=0
    C = (Q / (2 * math.pi * u)) * \
        (1 / (sy * sz)) * \
        np.exp(-0.5 * (Y / sy) ** 2) * \
        (np.exp(-0.5 * (H / sz) ** 2) + np.exp(-0.5 * (H / sz) ** 2))

    C = np.maximum(C, 0)

    # WHO thresholds for SO₂ (µg/m³)
    # Convert g/m³ → µg/m³
    C_ug = C * 1e6

    safe_mask = C_ug < 20
    moderate_mask = (C_ug >= 20) & (C_ug < 500)
    danger_mask = C_ug >= 500

    return {
        "x_range_m": x_range,
        "y_range_m": y_range,
        "stability_class": stability,
        "emission_rate_g_s": Q,
        "stack_height_m": H,
        "wind_speed_m_s": u,
        "concentration_max_ug_m3": round(float(C_ug.max()), 2),
        "concentration_mean_ug_m3": round(float(C_ug.mean()), 2),
        "affected_area_km2": round(float(danger_mask.sum()) * (x_range / nx) * (2 * y_range / ny) / 1e6, 3),
        "risk_zones": {
            "safe_pct": round(float(safe_mask.mean()) * 100, 1),
            "moderate_pct": round(float(moderate_mask.mean()) * 100, 1),
            "danger_pct": round(float(danger_mask.mean()) * 100, 1),
        },
        "grid": {
            "x": x_vals.tolist(),
            "y": y_vals.tolist(),
            "concentration": C_ug.tolist(),
        },
    }


def predict_critical_episode(meteo: dict, air_quality: dict) -> dict:
    """
    XGBoost classifier: predict if next 6h will be a critical air quality episode.
    Features: temperature, humidity, wind_speed, wind_direction, pressure, pm10, so2
    """
    model = _load_xgb()

    features = np.array([[
        meteo.get("temperature", 28.0),
        meteo.get("humidity", 55.0),
        meteo.get("wind_speed", 4.0),
        meteo.get("wind_direction", 270.0),
        meteo.get("pressure", 1013.0),
        air_quality.get("pm10", 50.0),
        air_quality.get("so2", 30.0),
    ]])

    if model is not None:
        try:
            proba = model.predict_proba(features)[0]
            is_critical = bool(model.predict(features)[0])
            confidence = float(proba[1])
        except Exception:
            is_critical, confidence = _heuristic_episode(meteo, air_quality)
    else:
        is_critical, confidence = _heuristic_episode(meteo, air_quality)

    # Determine episode type
    episode_type = "normal"
    if is_critical:
        if air_quality.get("so2", 0) > 100:
            episode_type = "pic_so2"
        elif air_quality.get("pm10", 0) > 100:
            episode_type = "pic_pm10"
        elif meteo.get("wind_speed", 5) < 2:
            episode_type = "stagnation"
        else:
            episode_type = "episode_mixte"

    return {
        "is_critical": is_critical,
        "confidence": round(confidence, 3),
        "episode_type": episode_type,
        "alert_level": "rouge" if (is_critical and confidence > 0.7) else "orange" if is_critical else "vert",
        "next_6h_prediction": "episode_critique" if is_critical else "qualite_normale",
        "timestamp": datetime.utcnow().isoformat(),
    }


def _heuristic_episode(meteo: dict, air: dict) -> tuple:
    """Rule-based fallback when XGBoost unavailable."""
    score = 0
    if air.get("aqi", 0) > 150:
        score += 3
    elif air.get("aqi", 0) > 100:
        score += 1
    if air.get("so2", 0) > 100:
        score += 2
    if air.get("pm10", 0) > 100:
        score += 2
    if meteo.get("wind_speed", 5) < 2:
        score += 2  # stagnation
    if meteo.get("humidity", 50) > 80:
        score += 1
    is_critical = score >= 4
    confidence = min(0.99, score / 8.0)
    return is_critical, confidence


async def get_realtime_alert(zone_id: str = "gct") -> dict:
    """Full real-time alert combining weather + air quality + Gaussian plume + XGBoost."""
    zone_coords = {
        "gct": (33.852, 9.978),
        "ville": (33.882, 10.020),
        "mer": (33.900, 10.105),
        "oasis": (33.910, 9.940),
    }
    lat, lon = zone_coords.get(zone_id, (33.88, 10.10))

    meteo, air_quality = await asyncio.gather(
        fetch_weather_openmeteo(lat, lon),
        fetch_air_quality_openmeteo(lat, lon),
    )

    episode = predict_critical_episode(meteo, air_quality)

    # Gaussian plume from GCT main stack
    stability = _wind_to_stability_class(
        meteo["wind_speed"],
        meteo["cloud_cover"],
        datetime.utcnow().hour,
    )
    plume = gaussian_plume(
        Q=85.0,
        H=120.0,
        u=meteo["wind_speed"],
        stability=stability,
    )

    # Cascade alert — check if multiple zones affected
    cascade_risk = air_quality["aqi"] > 100 and meteo["wind_speed"] > 3

    return {
        "zone_id": zone_id,
        "timestamp": datetime.utcnow().isoformat(),
        "meteo": meteo,
        "air_quality": air_quality,
        "episode_prediction": episode,
        "gaussian_plume": {
            "stability_class": plume["stability_class"],
            "concentration_max_ug_m3": plume["concentration_max_ug_m3"],
            "affected_area_km2": plume["affected_area_km2"],
            "risk_zones": plume["risk_zones"],
        },
        "cascade_alert": cascade_risk,
        "global_alert_level": episode["alert_level"],
        "recommendations": _build_recommendations(air_quality, episode, meteo),
    }


def _build_recommendations(air: dict, episode: dict, meteo: dict) -> list:
    recs = []
    if air["aqi"] > 150:
        recs.append({"type": "urgent", "message": "Évitez toute activité extérieure prolongée", "icon": "🚨"})
    if air["so2"] > 100:
        recs.append({"type": "warning", "message": f"SO₂ élevé: {air['so2']} µg/m³ — Fermez les fenêtres", "icon": "⚠️"})
    if meteo["wind_speed"] < 2:
        recs.append({"type": "info", "message": "Vent faible — risque d'accumulation des polluants", "icon": "ℹ️"})
    if episode["is_critical"]:
        recs.append({"type": "urgent", "message": "Épisode critique prévu dans les 6 prochaines heures", "icon": "🔴"})
    if not recs:
        recs.append({"type": "ok", "message": "Qualité de l'air acceptable aujourd'hui", "icon": "✅"})
    return recs
