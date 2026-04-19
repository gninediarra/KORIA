"""
Environmental analysis endpoints:
  GET /sol/{zone_id}               — soil analysis
  GET /sol/{zone_id}/timeline      — historical contamination
  GET /sol/{zone_id}/predict       — LSTM soil prediction
  GET /sol/{zone_id}/crop-yield    — crop yield impact
  GET /eau/{zone_id}               — water quality
  GET /eau/{zone_id}/predict       — LSTM water prediction
  GET /air/{zone_id}/realtime      — real-time air quality + meteo + plume
  GET /air/{zone_id}/predict       — AQI forecast
  GET /air/plume/{zone_id}         — Gaussian plume detail
  GET /air/plume/{zone_id}/grid    — plume concentration grid
"""
from fastapi import APIRouter, Query, HTTPException
from app.services.zone_analysis import (
    analyze_zone_sol, analyze_zone_eau,
    get_contamination_timeline, predict_sol, predict_eau, get_crop_yield_impact,
    get_zones_list,
)
from app.services.realtime_engine import (
    get_realtime_alert, predict_air, gaussian_plume,
    _wind_to_stability_class, fetch_weather, ZONE_COORDS,
)
import asyncio
from datetime import datetime

router = APIRouter(tags=["Analysis"])

VALID_ZONES = {"gct", "ville", "mer", "oasis"}


def _check_zone(zone_id: str):
    if zone_id not in VALID_ZONES:
        raise HTTPException(status_code=404, detail=f"Zone '{zone_id}' inconnue. Valides: {list(VALID_ZONES)}")


# ── Sol ───────────────────────────────────────────────────────────────────────

@router.get("/sol/{zone_id}")
def sol_analysis(zone_id: str):
    _check_zone(zone_id)
    return analyze_zone_sol(zone_id)


@router.get("/sol/{zone_id}/timeline")
def sol_timeline(zone_id: str):
    _check_zone(zone_id)
    return get_contamination_timeline(zone_id)


@router.get("/sol/{zone_id}/predict")
def sol_predict(
    zone_id: str,
    steps: int = Query(12, ge=1, le=60),
    freq: str = Query("monthly"),
):
    _check_zone(zone_id)
    return predict_sol(zone_id, steps=steps, freq=freq)


@router.get("/sol/{zone_id}/crop-yield")
def sol_crop_yield(zone_id: str):
    _check_zone(zone_id)
    return get_crop_yield_impact(zone_id)


# ── Eau ───────────────────────────────────────────────────────────────────────

@router.get("/eau/{zone_id}")
def eau_analysis(zone_id: str):
    _check_zone(zone_id)
    return analyze_zone_eau(zone_id)


@router.get("/eau/{zone_id}/predict")
def eau_predict(
    zone_id: str,
    steps: int = Query(12, ge=1, le=60),
    freq: str = Query("monthly"),
):
    _check_zone(zone_id)
    return predict_eau(zone_id, steps=steps, freq=freq)


# ── Air ───────────────────────────────────────────────────────────────────────

@router.get("/air/{zone_id}/realtime")
async def air_realtime(zone_id: str):
    _check_zone(zone_id)
    return await get_realtime_alert(zone_id)


@router.get("/air/{zone_id}/predict")
def air_predict(
    zone_id: str,
    steps: int = Query(30, ge=1, le=90),
    freq: str = Query("daily"),
):
    _check_zone(zone_id)
    return predict_air(zone_id, steps=steps, freq=freq)


@router.get("/air/plume/{zone_id}")
def air_plume(
    zone_id: str,
    emission_rate: float = Query(85.0),
    stack_height: float = Query(120.0),
    wind_speed: float = Query(4.0),
    stability: str = Query("D", pattern="^[ABCDEF]$"),
):
    _check_zone(zone_id)
    result = gaussian_plume(
        Q=emission_rate, H=stack_height, u=wind_speed, stability=stability
    )
    result.pop("grid", None)  # Grid excluded from plume summary
    return result


@router.get("/air/plume/{zone_id}/grid")
def air_plume_grid(
    zone_id: str,
    wind_speed: float = Query(4.0),
    stability: str = Query("D"),
):
    _check_zone(zone_id)
    return gaussian_plume(Q=85.0, H=120.0, u=wind_speed, stability=stability)
