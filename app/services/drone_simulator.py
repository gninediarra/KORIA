"""
DroneSimulator — Digital Twin for GabèsEye drone (DJI Mini 3 Pro + NVIDIA Jetson Nano).
Adapted from KORIA/Mané DroneEngine.
"""
import asyncio
import math
import random
import numpy as np
from datetime import datetime
from typing import AsyncGenerator

DEFAULT_WAYPOINTS = [
    {"lat": 33.852, "lon": 9.978, "alt": 50, "name": "GCT_Nord"},
    {"lat": 33.848, "lon": 9.990, "alt": 50, "name": "GCT_Centre"},
    {"lat": 33.840, "lon": 9.975, "alt": 50, "name": "GCT_Sud"},
    {"lat": 33.855, "lon": 9.965, "alt": 50, "name": "GCT_Ouest"},
]

TAKEOFF_COORDS = {"lat": 33.880, "lon": 10.020}

_active_missions: dict = {}


class DroneSimulator:
    def __init__(self, mission_id: str, waypoints: list = None, zone_id: str = "gct"):
        self.mission_id = mission_id
        self.waypoints = waypoints or DEFAULT_WAYPOINTS
        self.zone_id = zone_id
        self.battery = 100.0
        self.altitude = 0.0
        self.lat = TAKEOFF_COORDS["lat"]
        self.lon = TAKEOFF_COORDS["lon"]
        self.phase = "idle"
        self.elapsed = 0
        self._rng = random.Random(hash(mission_id) % 10000)
        self._np_rng = np.random.default_rng(42)

    def _interpolate_position(self, target: dict, speed_m_s: float = 8.0) -> bool:
        dlat = target["lat"] - self.lat
        dlon = target["lon"] - self.lon
        dist_m = math.sqrt(dlat ** 2 + dlon ** 2) * 111000
        if dist_m < 5:
            return True
        step_deg = (speed_m_s * 1.0) / 111000
        ratio = min(1.0, step_deg / math.sqrt(dlat ** 2 + dlon ** 2))
        self.lat += dlat * ratio
        self.lon += dlon * ratio
        return False

    def _get_air_reading(self) -> dict:
        base_so2 = 95.4 if self.zone_id == "gct" else 30.0
        base_pm10 = 87.3 if self.zone_id == "gct" else 40.0
        height_factor = max(0.3, 1.0 - self.altitude / 200.0)
        return {
            "so2_ug_m3": round(base_so2 * height_factor + self._rng.gauss(0, 5), 1),
            "pm10_ug_m3": round(base_pm10 * height_factor + self._rng.gauss(0, 8), 1),
            "temperature_c": round(28.0 + self._rng.gauss(0, 0.5), 1),
            "humidity_pct": round(55.0 + self._rng.gauss(0, 2), 1),
        }

    def _build_packet(self, ai_results: dict = None, event: str = None) -> dict:
        air = self._get_air_reading()
        packet = {
            "mission_id": self.mission_id,
            "timestamp": datetime.utcnow().isoformat(),
            "elapsed_s": self.elapsed,
            "phase": self.phase,
            "position": {
                "lat": round(self.lat, 6),
                "lon": round(self.lon, 6),
                "altitude_m": round(self.altitude, 1),
            },
            "battery_pct": round(self.battery, 1),
            "sensors": {
                "air": air,
                "gps": {
                    "satellites": self._rng.randint(8, 15),
                    "hdop": round(self._rng.uniform(0.8, 1.5), 2),
                    "fix": "3D",
                },
                "speed_m_s": round(self._rng.uniform(5.5, 10.5), 1) if self.phase not in ["landing", "takeoff"] else 2.0,
                "heading_deg": round(self._rng.uniform(0, 360), 0),
            },
            "jetson_status": {
                "cpu_pct": round(self._rng.uniform(45, 75), 1),
                "gpu_pct": round(self._rng.uniform(60, 90) if ai_results else self._rng.uniform(20, 40), 1),
                "temp_c": round(self._rng.uniform(52, 68), 1),
                "inference_ms": round(self._rng.uniform(35, 65), 0) if ai_results else None,
            },
        }
        if ai_results:
            packet["ai_results"] = ai_results
        if event:
            packet["event"] = event
        if self.battery < 20:
            packet["alert"] = "LOW_BATTERY"
        elif self.battery < 10:
            packet["alert"] = "CRITICAL_BATTERY_RTH"
        return packet

    async def stream_telemetry(self) -> AsyncGenerator[dict, None]:
        self.phase = "takeoff"
        for _ in range(12):
            self.altitude = min(self.altitude + 4.2, 50.0)
            self.battery -= 0.4
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(1)

        self.phase = "transit"
        for _ in range(60):
            reached = self._interpolate_position(self.waypoints[0], speed_m_s=10.0)
            self.battery -= 0.3
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(1)
            if reached:
                break

        self.phase = "scanning"
        for wp in self.waypoints:
            for _ in range(30):
                reached = self._interpolate_position(wp, speed_m_s=6.0)
                self.battery -= 0.25
                self.elapsed += 1
                ai = self._run_inference()
                yield self._build_packet(ai_results=ai)
                await asyncio.sleep(1)
                if reached:
                    break
            for _ in range(10):
                self.battery -= 0.3
                self.elapsed += 1
                yield self._build_packet(ai_results=self._run_inference(), event="scan")
                await asyncio.sleep(1)

        self.phase = "return"
        for _ in range(80):
            reached = self._interpolate_position(TAKEOFF_COORDS, speed_m_s=12.0)
            self.battery -= 0.3
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(1)
            if reached:
                break

        self.phase = "landing"
        for _ in range(12):
            self.altitude = max(0.0, self.altitude - 4.2)
            self.battery -= 0.2
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(1)

        self.phase = "complete"
        yield self._build_packet(event="mission_complete")

    def _run_inference(self) -> dict:
        is_near_gct = abs(self.lat - 33.852) < 0.01 and abs(self.lon - 9.978) < 0.01
        seg_class = 4 if is_near_gct else self._rng.randint(0, 3)
        confidence = self._rng.uniform(0.82, 0.96) if is_near_gct else self._rng.uniform(0.71, 0.91)
        names = ["vegetation", "sol_agricole", "sol_nu", "sol_degrade", "contamine_gct"]
        return {
            "thermal": {
                "temp_mean_c": round(28 + self._rng.gauss(0, 3), 1),
                "anomaly_detected": is_near_gct,
                "anomaly_delta_c": round(self._rng.uniform(5, 15) if is_near_gct else 0.5, 1),
                "hotspot_count": self._rng.randint(3, 8) if is_near_gct else 0,
            },
            "segmentation": {
                "class_id": seg_class,
                "class_name": names[seg_class],
                "confidence": round(confidence, 3),
                "is_contaminated": seg_class >= 3,
            },
            "frame_id": f"{self.mission_id}_{self.elapsed:04d}",
            "resolution_cm": 5.0,
        }


def get_mission_status(mission_id: str) -> dict:
    return {
        "mission_id": mission_id,
        "status": "available",
        "drone_model": "DJI Mini 3 Pro (Digital Twin)",
        "payload": ["Caméra thermique FLIR", "Caméra multispectrale MicaSense", "NVIDIA Jetson Nano"],
        "max_flight_time_min": 38,
        "max_range_km": 12,
        "ai_models": ["U-Net EfficientNet-B3 (sol)", "U-Net EfficientNet-B3 (eau)", "Gaussian Plume (air)"],
        "timestamp": datetime.utcnow().isoformat(),
    }
