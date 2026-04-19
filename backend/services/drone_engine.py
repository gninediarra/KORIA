"""
DroneEngine — Digital Twin strategy.
DroneSimulator streams realistic telemetry + AI inference (thermal + multispectral).
When real drone assembled: plug in cameras, zero code changes needed.
"""
import asyncio
import json
import math
import random
import numpy as np
from datetime import datetime
from typing import AsyncGenerator, Optional
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent

# Gabès GCT area waypoints for scanning mission
DEFAULT_WAYPOINTS = [
    {"lat": 33.852, "lon": 9.978, "alt": 50, "name": "GCT_Nord"},
    {"lat": 33.848, "lon": 9.990, "alt": 50, "name": "GCT_Centre"},
    {"lat": 33.840, "lon": 9.975, "alt": 50, "name": "GCT_Sud"},
    {"lat": 33.855, "lon": 9.965, "alt": 50, "name": "GCT_Ouest"},
]

TAKEOFF_COORDS = {"lat": 33.880, "lon": 10.020}


class DroneSimulator:
    """
    Simulates NVIDIA Jetson Nano drone with thermal + multispectral cameras.
    Phases: takeoff → transit → scanning → return
    """

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
        self.current_waypoint_idx = 0
        self._rng = random.Random(hash(mission_id) % 10000)
        self._np_rng = np.random.default_rng(42)

    def _interpolate_position(self, target: dict, speed_m_s: float = 8.0, dt: float = 1.0) -> bool:
        """Move toward target. Returns True when reached."""
        dlat = target["lat"] - self.lat
        dlon = target["lon"] - self.lon
        dist_deg = math.sqrt(dlat ** 2 + dlon ** 2)
        dist_m = dist_deg * 111000

        if dist_m < 5:
            return True

        step_deg = (speed_m_s * dt) / 111000
        ratio = min(1.0, step_deg / dist_deg)
        self.lat += dlat * ratio
        self.lon += dlon * ratio
        return False

    def _get_air_reading(self) -> dict:
        """Simulate onboard air sensor readings."""
        base_so2 = 95.4 if self.zone_id == "gct" else 30.0
        base_pm10 = 87.3 if self.zone_id == "gct" else 40.0

        # Height effect — higher altitude = less pollution
        height_factor = max(0.3, 1.0 - self.altitude / 200.0)

        return {
            "so2_ug_m3": round(base_so2 * height_factor + self._rng.gauss(0, 5), 1),
            "pm10_ug_m3": round(base_pm10 * height_factor + self._rng.gauss(0, 8), 1),
            "temperature_c": round(28.0 + self._rng.gauss(0, 0.5), 1),
            "humidity_pct": round(55.0 + self._rng.gauss(0, 2), 1),
        }

    def _get_gps_quality(self) -> dict:
        return {
            "satellites": self._rng.randint(8, 15),
            "hdop": round(self._rng.uniform(0.8, 1.5), 2),
            "fix": "3D",
        }

    async def stream_telemetry(self) -> AsyncGenerator[dict, None]:
        """Async generator — yields one telemetry packet per second."""
        # Phase 1: Takeoff
        self.phase = "takeoff"
        target_alt = 50.0
        for _ in range(12):
            self.altitude = min(self.altitude + 4.2, target_alt)
            self.battery -= 0.4
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(0)

        # Phase 2: Transit to first waypoint
        self.phase = "transit"
        target = self.waypoints[0]
        for _ in range(60):
            reached = self._interpolate_position(target, speed_m_s=10.0)
            self.battery -= 0.3
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(0)
            if reached:
                break

        # Phase 3: Scanning waypoints
        self.phase = "scanning"
        for wp in self.waypoints:
            self.current_waypoint_idx = self.waypoints.index(wp)
            # Transit to waypoint
            for _ in range(30):
                reached = self._interpolate_position(wp, speed_m_s=6.0)
                self.battery -= 0.25
                self.elapsed += 1
                # AI inference during scan
                ai_results = self._run_ai_inference()
                yield self._build_packet(ai_results=ai_results)
                await asyncio.sleep(0)
                if reached:
                    break
            # Hover and scan
            for _ in range(15):
                self.battery -= 0.3
                self.elapsed += 1
                ai_results = self._run_ai_inference(scanning=True)
                yield self._build_packet(ai_results=ai_results, event="scan")
                await asyncio.sleep(0)

        # Phase 4: Return to base
        self.phase = "return"
        for _ in range(80):
            reached = self._interpolate_position(TAKEOFF_COORDS, speed_m_s=12.0)
            self.battery -= 0.3
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(0)
            if reached:
                break

        # Landing
        self.phase = "landing"
        for _ in range(12):
            self.altitude = max(0.0, self.altitude - 4.2)
            self.battery -= 0.2
            self.elapsed += 1
            yield self._build_packet()
            await asyncio.sleep(0)

        self.phase = "complete"
        yield self._build_packet(event="mission_complete")

    def _build_packet(self, ai_results: dict = None, event: str = None) -> dict:
        air = self._get_air_reading()
        gps = self._get_gps_quality()

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
                "gps": gps,
                "speed_m_s": round(self._rng.uniform(5.5, 10.5), 1) if self.phase not in ["landing", "takeoff"] else round(self.altitude / 10, 1),
                "heading_deg": round(self._rng.uniform(0, 360), 0),
            },
            "jetson_status": {
                "cpu_pct": round(self._rng.uniform(45, 75), 1),
                "gpu_pct": round(self._rng.uniform(60, 90), 1) if ai_results else round(self._rng.uniform(20, 40), 1),
                "temp_c": round(self._rng.uniform(52, 68), 1),
                "inference_ms": round(self._rng.uniform(35, 65), 0) if ai_results else None,
            },
        }

        if ai_results:
            packet["ai_results"] = ai_results
        if event:
            packet["event"] = event

        # Battery low alert
        if self.battery < 20:
            packet["alert"] = "LOW_BATTERY"
        elif self.battery < 10:
            packet["alert"] = "CRITICAL_BATTERY_RTH"

        return packet

    def _run_ai_inference(self, scanning: bool = False) -> dict:
        """Simulate Jetson Nano AI inference on captured frame."""
        # Thermal image — contaminated zones show temperature anomaly
        thermal = simulate_thermal_image(
            lat=self.lat,
            lon=self.lon,
            zone_id=self.zone_id,
        )

        # Multispectral — predict class based on position
        is_near_gct = (abs(self.lat - 33.852) < 0.01 and abs(self.lon - 9.978) < 0.01)
        if is_near_gct:
            seg_class = 4  # contamine_gct
            confidence = round(self._rng.uniform(0.82, 0.96), 3)
        else:
            seg_class = self._rng.randint(0, 3)
            confidence = round(self._rng.uniform(0.71, 0.91), 3)

        class_names = ["vegetation", "sol_agricole", "sol_nu", "sol_degrade", "contamine_gct"]

        return {
            "thermal": {
                "temp_mean_c": thermal["temp_mean_c"],
                "anomaly_detected": thermal["anomaly_detected"],
                "anomaly_delta_c": thermal["anomaly_delta_c"],
                "hotspot_count": thermal["hotspot_count"],
            },
            "segmentation": {
                "class_id": seg_class,
                "class_name": class_names[seg_class],
                "confidence": confidence,
                "is_contaminated": seg_class >= 3,
            },
            "frame_id": f"{self.mission_id}_{self.elapsed:04d}",
            "resolution_cm": 5.0,  # 5cm/px from 50m altitude with typical drone camera
        }


def simulate_thermal_image(
    lat: float = 33.852,
    lon: float = 9.978,
    zone_id: str = "gct",
    seg_class_map: np.ndarray = None,
    width: int = 256,
    height: int = 256,
) -> dict:
    """
    Realistic thermal camera simulation using Gaussian blob superposition.
    Industrial sources → smooth hot spots. Vegetation → cooling patches.
    Returns full grid for FLIR-quality frontend rendering.
    """
    seed = int(abs(lat) * 1000 + abs(lon) * 100) % 99991
    rng = np.random.default_rng(seed)

    XX, YY = np.meshgrid(np.arange(width, dtype=np.float32),
                          np.arange(height, dtype=np.float32))
    base_temp = 32.0
    temp = np.full((height, width), base_temp, dtype=np.float32)

    # Zone-specific industrial hot spots  (cx_frac, cy_frac, delta_T, sigma_frac)
    profiles = {
        "gct": {
            "hotspots": [
                (0.42, 0.38, 19.0, 0.14),   # cheminée principale GCT
                (0.60, 0.55, 13.0, 0.09),   # cheminée secondaire
                (0.28, 0.68, 10.0, 0.08),   # bassin de décantation
                (0.68, 0.28,  7.0, 0.06),   # zone stockage phosphates
                (0.50, 0.80,  6.0, 0.05),   # rejet liquide
            ],
            "veg": 2, "veg_str": 4.0, "base_noise": 1.5,
        },
        "mer": {
            "hotspots": [
                (0.50, 0.50, 4.0, 0.35),    # zone turbide (absorbe + IR)
                (0.25, 0.30, 3.5, 0.18),
            ],
            "veg": 0, "veg_str": 0.0, "base_noise": 0.8,
        },
        "oasis": {
            "hotspots": [(0.55, 0.45, 5.0, 0.22)],
            "veg": 7, "veg_str": 7.0, "base_noise": 1.0,
        },
        "ville": {
            "hotspots": [
                (0.45, 0.40, 8.0, 0.18),   # zone industrielle périphérique
                (0.60, 0.60, 5.0, 0.12),
            ],
            "veg": 4, "veg_str": 3.5, "base_noise": 1.2,
        },
    }
    prof = profiles.get(zone_id, profiles["gct"])

    # Add industrial hot spots (smooth Gaussian blobs)
    for cx_f, cy_f, dT, sig_f in prof["hotspots"]:
        cx, cy = cx_f * width, cy_f * height
        sigma = sig_f * max(width, height)
        dist_sq = (XX - cx) ** 2 + (YY - cy) ** 2
        temp += dT * np.exp(-dist_sq / (2.0 * sigma ** 2))

    # Add vegetation cooling patches
    for _ in range(prof["veg"]):
        cx = rng.uniform(0.05, 0.95) * width
        cy = rng.uniform(0.05, 0.95) * height
        sigma_v = rng.uniform(0.05, 0.14) * max(width, height)
        strength_v = rng.uniform(2.5, prof["veg_str"])
        dist_sq = (XX - cx) ** 2 + (YY - cy) ** 2
        temp -= strength_v * np.exp(-dist_sq / (2.0 * sigma_v ** 2))

    # Spatially correlated noise (block noise — avoids per-pixel randomness)
    bsize = 16
    bh, bw = max(1, height // bsize), max(1, width // bsize)
    block = rng.normal(0, prof["base_noise"], (bh, bw)).astype(np.float32)
    noise_full = np.repeat(np.repeat(block, bsize, axis=0), bsize, axis=1)
    temp += noise_full[:height, :width]

    temp = np.clip(temp, 22.0, 72.0)

    threshold = base_temp + 10.0
    hotspot_mask = temp > threshold
    hot_mean = float(temp[hotspot_mask].mean()) if hotspot_mask.any() else base_temp + 10
    cold_mean = float(temp[~hotspot_mask].mean()) if (~hotspot_mask).any() else base_temp
    anomaly_delta = hot_mean - cold_mean

    # ── PIL/scipy FLIR Iron PNG (512×512, Gaussian-smoothed) ──────────────
    image_b64 = None
    try:
        try:
            from scipy.ndimage import gaussian_filter
            temp_render = gaussian_filter(temp.astype(np.float64), sigma=3.0).astype(np.float32)
        except ImportError:
            temp_render = temp.copy()
            for _ in range(5):
                t = temp_render.copy()
                temp_render[1:-1, 1:-1] = (
                    t[:-2, 1:-1] + t[2:, 1:-1] + t[1:-1, :-2] + t[1:-1, 2:] + t[1:-1, 1:-1]
                ) / 5.0

        from PIL import Image
        import io, base64 as _b64

        tmin, tmax = temp_render.min(), temp_render.max()
        norm = (temp_render - tmin) / (tmax - tmin + 1e-8)

        # FLIR Iron colormap
        stops_v = [0, .12, .24, .35, .47, .59, .71, .82, .90, 1.0]
        stops_r = [  0,  30,  80, 140, 200, 235, 255, 255, 255, 255]
        stops_g = [  0,   0,   0,   0,  20,  55, 120, 175, 220, 255]
        stops_b = [  0,  50,  80,  60,   0,   0,   0,   0,  60, 255]
        flat = norm.ravel()
        R = np.interp(flat, stops_v, stops_r).reshape(norm.shape).astype(np.uint8)
        G = np.interp(flat, stops_v, stops_g).reshape(norm.shape).astype(np.uint8)
        B = np.interp(flat, stops_v, stops_b).reshape(norm.shape).astype(np.uint8)

        img = Image.fromarray(np.stack([R, G, B], axis=-1)).resize((512, 512), Image.LANCZOS)
        buf = io.BytesIO()
        img.save(buf, format="PNG", optimize=True)
        image_b64 = _b64.b64encode(buf.getvalue()).decode("utf-8")
    except Exception:
        pass

    # Compact 128×128 grid (kept for telemetry fallback)
    step_h = max(1, height // 128)
    step_w = max(1, width // 128)
    full_grid = temp[::step_h, ::step_w].tolist()

    return {
        "temp_min_c": round(float(temp.min()), 1),
        "temp_max_c": round(float(temp.max()), 1),
        "temp_mean_c": round(float(temp.mean()), 1),
        "anomaly_detected": bool(hotspot_mask.mean() > 0.04),
        "anomaly_delta_c": round(anomaly_delta, 1),
        "hotspot_count": int(hotspot_mask.sum()),
        "hotspot_pct": round(float(hotspot_mask.mean()) * 100, 2),
        "zone_id": zone_id,
        "image_b64": image_b64,        # FLIR Iron PNG 512×512 base64
        "grid_rows": len(full_grid),
        "grid_cols": len(full_grid[0]) if full_grid else 0,
        "full_grid": full_grid,
        "thumbnail": temp[::16, ::16].tolist(),
    }


def get_mission_status(mission_id: str) -> dict:
    """Summary status for a completed or ongoing mission."""
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
