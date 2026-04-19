"""
Dashboard & utility endpoints:
  GET /dashboard    — multi-zone snapshot
  GET /map/living   — GeoJSON contamination map
  GET /api/status   — project status
  GET /health       — health check
"""
from fastapi import APIRouter
from datetime import datetime
from app.services.zone_analysis import analyze_zone_sol, analyze_zone_eau, get_zones_list
from app.services.realtime_engine import get_realtime_alert
import asyncio

router = APIRouter(tags=["Dashboard"])

ZONES = ["gct", "ville", "mer", "oasis"]


@router.get("/dashboard")
async def dashboard():
    """Multi-zone snapshot for the Flutter dashboard."""
    results = {}
    for zone_id in ZONES:
        sol, eau, air = await asyncio.gather(
            asyncio.to_thread(analyze_zone_sol, zone_id),
            asyncio.to_thread(analyze_zone_eau, zone_id),
            get_realtime_alert(zone_id),
        )
        results[zone_id] = {
            "sol": sol,
            "eau": eau,
            "air": air,
        }

    # Global summary
    critical_zones = [z for z, d in results.items() if d["air"].get("global_alert_level") == "rouge"]
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "zones": results,
        "summary": {
            "total_zones": len(ZONES),
            "critical_zones": len(critical_zones),
            "critical_zone_ids": critical_zones,
        },
    }


@router.get("/map/living")
async def living_map():
    """GeoJSON FeatureCollection with contamination status per zone."""
    zones_config = get_zones_list()
    features = []

    for zone_info in zones_config:
        zone_id = zone_info["id"]
        sol = analyze_zone_sol(zone_id)
        air = await get_realtime_alert(zone_id)
        aq = air.get("air_quality", {})

        status = sol.get("status", "vert")
        air_level = air.get("global_alert_level", "vert")
        if air_level == "rouge" or status == "rouge":
            combined_status = "rouge"
        elif air_level == "orange" or status == "orange":
            combined_status = "orange"
        else:
            combined_status = "vert"

        bbox = zone_info["bbox"]
        center = zone_info["center"]
        lon_min, lat_min, lon_max, lat_max = bbox

        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Polygon",
                "coordinates": [[
                    [lon_min, lat_min],
                    [lon_max, lat_min],
                    [lon_max, lat_max],
                    [lon_min, lat_max],
                    [lon_min, lat_min],
                ]],
            },
            "properties": {
                "id": zone_id,
                "name": zone_info["name"],
                "type": zone_info["type"],
                "status": combined_status,
                "contamination_sol": sol.get("contamination_pct"),
                "aqi": aq.get("aqi"),
                "so2": aq.get("so2"),
                "alert_level": air_level,
                "color": zone_info["couleur"],
            },
        })

    return {"type": "FeatureCollection", "features": features, "timestamp": datetime.utcnow().isoformat()}


@router.get("/api/status")
def project_status():
    return {
        "status": "operational",
        "project": "GabèsEye",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat(),
        "services": {
            "zone_analysis": "ok",
            "air_quality": "ok",
            "drone_simulator": "ok",
            "ai_agents": "ok",
        },
    }


@router.get("/health")
def health():
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}
