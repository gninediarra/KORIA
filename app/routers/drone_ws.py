"""
Drone real-time endpoints:
  GET /drone/status            — mission info
  GET /drone/thermal           — thermal image simulation
  WS  /ws/drone/{mission_id}  — live telemetry stream (1 packet/s)
  WS  /ws/live/{role}         — environmental updates every 30s
"""
import asyncio
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.services.drone_simulator import DroneSimulator, get_mission_status
from app.services.realtime_engine import get_realtime_alert, ZONE_COORDS

router = APIRouter(tags=["Drone"])


@router.get("/drone/status")
def drone_status(mission_id: str = Query("mission_gabes_01")):
    return get_mission_status(mission_id)


@router.get("/drone/thermal")
async def drone_thermal(
    lat: float = Query(33.852),
    lon: float = Query(9.978),
    zone_id: str = Query("gct"),
):
    """Simulated thermal imagery at given coordinates."""
    import random
    import math
    rng = random.Random(int(abs(lat) * 1000 + abs(lon) * 100) % 99991)
    is_hot = zone_id == "gct"
    return {
        "temp_min_c": round(22.0 + rng.uniform(0, 2), 1),
        "temp_max_c": round(45.0 + rng.uniform(0, 15) if is_hot else 32.0, 1),
        "temp_mean_c": round(28.0 + rng.uniform(0, 8), 1),
        "anomaly_detected": is_hot,
        "anomaly_delta_c": round(rng.uniform(8, 18) if is_hot else 1.5, 1),
        "hotspot_count": rng.randint(3, 7) if is_hot else 0,
        "hotspot_pct": round(rng.uniform(5, 15) if is_hot else 1.0, 2),
        "zone_id": zone_id,
        "image_b64": None,
    }


@router.websocket("/ws/drone/{mission_id}")
async def drone_telemetry_ws(websocket: WebSocket, mission_id: str):
    """Real-time drone telemetry — 1 packet per second via WebSocket."""
    await websocket.accept()
    simulator = DroneSimulator(mission_id=mission_id)
    try:
        async for packet in simulator.stream_telemetry():
            await websocket.send_text(json.dumps(packet))
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        try:
            await websocket.close()
        except Exception:
            pass


@router.websocket("/ws/live/{role}")
async def live_environmental_ws(websocket: WebSocket, role: str):
    """Environmental updates every 30s filtered by role."""
    await websocket.accept()
    zone_priorities = {
        "agriculteur": ["oasis", "gct"],
        "pecheur": ["mer", "gct"],
        "citoyen": ["ville", "gct"],
        "autorite": ["gct", "ville", "mer", "oasis"],
    }
    zones = zone_priorities.get(role, ["gct", "ville"])

    try:
        while True:
            for zone_id in zones:
                try:
                    air_data = await get_realtime_alert(zone_id)
                    update = {
                        "zone_id": zone_id,
                        "role": role,
                        "air": air_data,
                        "type": "live_update",
                    }
                    await websocket.send_text(json.dumps(update))
                    await asyncio.sleep(1)
                except Exception:
                    pass
            await asyncio.sleep(28)  # ~30s total per cycle
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        try:
            await websocket.close()
        except Exception:
            pass
