"""
ZoneEngine — Satellite analysis: U-Net segmentation + Mahalanobis anomaly detection.
Uses Sentinel-2 L2A via SentinelHub (CDSE) or cached numpy arrays.
"""
import os
import json
import time
import numpy as np
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

BASE_DIR = Path(__file__).parent.parent
MODELS_DIR = BASE_DIR / "models"
DATA_DIR = BASE_DIR / "data"
CACHE_DIR = BASE_DIR / "cache"

# Lazy imports — heavy libs loaded only when needed
_unet_sol = None
_unet_eau = None
_device = None


def _get_device():
    global _device
    if _device is None:
        import torch
        _device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    return _device


def _load_unet_sol():
    global _unet_sol
    if _unet_sol is not None:
        return _unet_sol
    model_path = MODELS_DIR / "unet_finetuned.pth"
    if not model_path.exists():
        return None
    try:
        import torch
        import segmentation_models_pytorch as smp
        device = _get_device()
        model = smp.Unet(
            encoder_name="efficientnet-b3",
            encoder_weights=None,
            in_channels=5,
            classes=5,
        )
        state_dict = torch.load(model_path, map_location=device, weights_only=False)
        model.load_state_dict(state_dict)
        model.to(device)
        model.eval()
        _unet_sol = model
        print(f"[ZoneEngine] Loaded U-Net Sol from {model_path.name}")
        return model
    except Exception as e:
        print(f"[ZoneEngine] Cannot load U-Net Sol: {e}")
        return None


def _load_unet_eau():
    global _unet_eau
    if _unet_eau is not None:
        return _unet_eau
    model_path = MODELS_DIR / "unet_eau_final.pth"
    if not model_path.exists():
        return None
    try:
        import torch
        import segmentation_models_pytorch as smp
        device = _get_device()
        model = smp.Unet(
            encoder_name="efficientnet-b3",
            encoder_weights=None,
            in_channels=6,
            classes=5,
        )
        state_dict = torch.load(model_path, map_location=device, weights_only=False)
        model.load_state_dict(state_dict)
        model.to(device)
        model.eval()
        _unet_eau = model
        print(f"[ZoneEngine] Loaded U-Net Eau from {model_path.name}")
        return model
    except Exception as e:
        print(f"[ZoneEngine] Cannot load U-Net Eau: {e}")
        return None


def _spectral_indices_sol(bands: np.ndarray) -> dict:
    """bands shape: (H, W, 5) — B2, B4, B8, B11, B12 normalized [0,1]"""
    eps = 1e-8
    B2, B4, B8, B11 = bands[..., 1], bands[..., 1], bands[..., 2], bands[..., 3]
    B2_orig = bands[..., 0]
    NDVI = (B8 - B4) / (B8 + B4 + eps)
    NDSI = (B11 - B8) / (B11 + B8 + eps)
    BSI = ((B11 + B4) - (B8 + B2_orig)) / ((B11 + B4) + (B8 + B2_orig) + eps)
    NBR = (B8 - B11) / (B8 + B11 + eps)
    return {"NDVI": NDVI, "NDSI": NDSI, "BSI": BSI, "NBR": NBR}


def _spectral_indices_eau(bands: np.ndarray) -> dict:
    """bands shape: (H, W, 5) — B2, B3, B4, B5, B8 normalized [0,1]"""
    eps = 1e-8
    B2, B3, B4, B5, B8 = bands[..., 0], bands[..., 1], bands[..., 2], bands[..., 3], bands[..., 4]
    NDWI = (B3 - B8) / (B3 + B8 + eps)
    Turbidite = B4 / (B2 + eps)
    NDCI = (B5 - B4) / (B5 + B4 + eps)
    SPM = (B4 - B3) / (B4 + B3 + eps)
    return {"NDWI": NDWI, "Turbidite": Turbidite, "NDCI": NDCI, "SPM": SPM}


def _mahalanobis_anomalies(indices: dict, threshold: float = 3.0) -> np.ndarray:
    """Pure numpy Mahalanobis distance — no sklearn."""
    keys = list(indices.keys())
    H, W = indices[keys[0]].shape
    X = np.stack([indices[k].flatten() for k in keys], axis=1).astype(np.float64)
    mask_valid = np.all(np.isfinite(X), axis=1)
    X_valid = X[mask_valid]

    mean = np.mean(X_valid, axis=0)
    cov = np.cov(X_valid.T)
    try:
        cov_inv = np.linalg.inv(cov + np.eye(len(keys)) * 1e-6)
    except np.linalg.LinAlgError:
        cov_inv = np.eye(len(keys))

    diff = X_valid - mean
    dist_sq = np.sum(diff @ cov_inv * diff, axis=1)
    distances = np.sqrt(np.maximum(dist_sq, 0))

    full_dist = np.zeros(H * W)
    full_dist[mask_valid] = distances

    anomaly_mask = np.zeros(H * W, dtype=bool)
    anomaly_mask[mask_valid] = distances > threshold

    # Directional constraint: anomaly AND degraded (low NDVI, high BSI)
    if "NDVI" in indices and "BSI" in indices:
        ndvi_flat = indices["NDVI"].flatten()
        bsi_flat = indices["BSI"].flatten()
        ndvi_mean = np.mean(ndvi_flat[mask_valid])
        bsi_mean = np.mean(bsi_flat[mask_valid])
        directional = (ndvi_flat < ndvi_mean) & (bsi_flat > bsi_mean)
        anomaly_mask = anomaly_mask & directional

    return anomaly_mask.reshape(H, W)


def _run_unet_inference(model, bands: np.ndarray) -> np.ndarray:
    """Run U-Net on full image with tiling. Returns class map (H, W)."""
    import torch
    device = _get_device()
    H, W, C = bands.shape
    tile_size = 256
    stride = 224
    class_map = np.zeros((H, W), dtype=np.uint8)
    count_map = np.zeros((H, W), dtype=np.uint8)

    for y in range(0, H, stride):
        for x in range(0, W, stride):
            y_end = min(y + tile_size, H)
            x_end = min(x + tile_size, W)
            tile = bands[y:y_end, x:x_end, :]
            th, tw = tile.shape[:2]
            if th < 16 or tw < 16:
                continue
            # Pad to tile_size
            pad_h = tile_size - th
            pad_w = tile_size - tw
            if pad_h > 0 or pad_w > 0:
                tile = np.pad(tile, ((0, pad_h), (0, pad_w), (0, 0)), mode="reflect")

            tensor = torch.from_numpy(tile.transpose(2, 0, 1)).float().unsqueeze(0).to(device)
            with torch.no_grad():
                logits = model(tensor)
                preds = torch.argmax(logits, dim=1).squeeze(0).cpu().numpy().astype(np.uint8)

            class_map[y:y_end, x:x_end] = preds[:th, :tw]
            count_map[y:y_end, x:x_end] += 1

    return class_map


def _simulate_sol_data(zone_id: str) -> dict:
    """Fallback when models/satellite data unavailable — realistic simulation."""
    rng = np.random.default_rng(42 + hash(zone_id) % 1000)

    # Based on Kaggle results: ~29% contaminated for GCT zone
    contamination_pct = {
        "gct": 0.29, "ville": 0.18, "mer": 0.05, "oasis": 0.22
    }.get(zone_id, 0.20)

    noise = rng.uniform(-0.05, 0.05)
    contamination_pct = max(0.01, min(0.99, contamination_pct + noise))

    ndvi_mean = 0.08 + rng.uniform(-0.02, 0.02)
    bsi_mean = 0.31 + rng.uniform(-0.03, 0.03)

    health_score = max(5, min(95, 100 * (1 - contamination_pct) * (0.3 + ndvi_mean)))

    anomaly_pct = contamination_pct * 0.8

    if contamination_pct > 0.25:
        status = "rouge"
    elif contamination_pct > 0.15:
        status = "orange"
    else:
        status = "vert"

    class_distribution = {
        "vegetation": round((1 - contamination_pct) * 0.35 * 100, 1),
        "sol_agricole": round((1 - contamination_pct) * 0.40 * 100, 1),
        "sol_nu": round((1 - contamination_pct) * 0.15 * 100, 1),
        "sol_degrade": round(contamination_pct * 0.60 * 100, 1),
        "contamine_gct": round(contamination_pct * 0.40 * 100, 1),
    }

    return {
        "zone_id": zone_id,
        "type": "sol",
        "timestamp": datetime.utcnow().isoformat(),
        "source": "simulation",
        "health_score": round(health_score, 1),
        "contamination_pct": round(contamination_pct * 100, 1),
        "anomaly_pct": round(anomaly_pct * 100, 1),
        "status": status,
        "indices": {
            "NDVI": round(ndvi_mean, 4),
            "NDSI": round(0.12 + rng.uniform(-0.02, 0.02), 4),
            "BSI": round(bsi_mean, 4),
            "NBR": round(0.05 + rng.uniform(-0.01, 0.01), 4),
        },
        "class_distribution": class_distribution,
        "anomaly_pixels": int(anomaly_pct * 500 * 600),
        "total_pixels": 500 * 600,
    }


def _simulate_eau_data(zone_id: str) -> dict:
    """Fallback water quality simulation."""
    rng = np.random.default_rng(99 + hash(zone_id) % 1000)

    turbidite_base = {
        "gct": 0.62, "mer": 0.45, "ville": 0.30, "oasis": 0.20
    }.get(zone_id, 0.40)
    turbidite = max(0.01, turbidite_base + rng.uniform(-0.05, 0.05))

    ndwi_mean = 0.15 + rng.uniform(-0.02, 0.02)
    contamination_pct = min(0.9, turbidite * 0.7 + rng.uniform(0, 0.1))
    anomaly_pct = contamination_pct * 0.65

    if turbidite > 0.5:
        status = "rouge"
    elif turbidite > 0.3:
        status = "orange"
    else:
        status = "vert"

    return {
        "zone_id": zone_id,
        "type": "eau",
        "timestamp": datetime.utcnow().isoformat(),
        "source": "simulation",
        "turbidite": round(turbidite, 4),
        "contamination_pct": round(contamination_pct * 100, 1),
        "anomaly_pct": round(anomaly_pct * 100, 1),
        "status": status,
        "indices": {
            "NDWI": round(ndwi_mean, 4),
            "Turbidite": round(turbidite, 4),
            "NDCI": round(0.08 + rng.uniform(-0.01, 0.01), 4),
            "SPM": round(0.12 + rng.uniform(-0.02, 0.02), 4),
        },
        "anomaly_pixels": int(anomaly_pct * 800 * 700),
        "total_pixels": 800 * 700,
    }


def analyze_zone_sol(zone_id: str, use_satellite: bool = False) -> dict:
    """
    Main entry point for soil analysis.
    Returns health score, contamination %, class distribution, anomalies.
    """
    cache_file = CACHE_DIR / f"sol_{zone_id}_{datetime.utcnow().strftime('%Y%m%d_%H')}.json"
    if cache_file.exists():
        with open(cache_file) as f:
            return json.load(f)

    # Try real U-Net inference if model loaded and satellite data available
    if use_satellite:
        model = _load_unet_sol()
        if model is not None:
            # In production: fetch from SentinelHub — here use cached .npy if available
            sat_cache = CACHE_DIR / f"sat_sol_{zone_id}.npy"
            if sat_cache.exists():
                bands = np.load(str(sat_cache))
                class_map = _run_unet_inference(model, bands)
                indices = _spectral_indices_sol(bands)
                anomaly_map = _mahalanobis_anomalies(indices)

                H, W = class_map.shape
                total = H * W
                classes, counts = np.unique(class_map, return_counts=True)
                class_pct = {int(c): round(cnt / total * 100, 1) for c, cnt in zip(classes, counts)}
                contamination_pct = class_pct.get(4, 0.0)
                anomaly_pct = round(anomaly_map.sum() / total * 100, 1)
                ndvi_mean = float(np.mean(indices["NDVI"][np.isfinite(indices["NDVI"])]))
                health_score = max(5, min(95, 100 * (1 - contamination_pct / 100) * (0.3 + ndvi_mean)))

                status = "rouge" if contamination_pct > 25 else "orange" if contamination_pct > 15 else "vert"
                result = {
                    "zone_id": zone_id,
                    "type": "sol",
                    "timestamp": datetime.utcnow().isoformat(),
                    "source": "satellite_unet",
                    "health_score": round(health_score, 1),
                    "contamination_pct": contamination_pct,
                    "anomaly_pct": anomaly_pct,
                    "status": status,
                    "indices": {k: round(float(np.mean(v[np.isfinite(v)])), 4) for k, v in indices.items()},
                    "class_distribution": {
                        "vegetation": class_pct.get(0, 0),
                        "sol_agricole": class_pct.get(1, 0),
                        "sol_nu": class_pct.get(2, 0),
                        "sol_degrade": class_pct.get(3, 0),
                        "contamine_gct": class_pct.get(4, 0),
                    },
                    "anomaly_pixels": int(anomaly_map.sum()),
                    "total_pixels": total,
                }
                with open(cache_file, "w") as f:
                    json.dump(result, f)
                return result

    result = _simulate_sol_data(zone_id)
    with open(cache_file, "w") as f:
        json.dump(result, f)
    return result


def analyze_zone_eau(zone_id: str, use_satellite: bool = False) -> dict:
    """Main entry point for water quality analysis."""
    cache_file = CACHE_DIR / f"eau_{zone_id}_{datetime.utcnow().strftime('%Y%m%d_%H')}.json"
    if cache_file.exists():
        with open(cache_file) as f:
            return json.load(f)

    if use_satellite:
        model = _load_unet_eau()
        if model is not None:
            sat_cache = CACHE_DIR / f"sat_eau_{zone_id}.npy"
            if sat_cache.exists():
                bands = np.load(str(sat_cache))
                class_map = _run_unet_inference(model, bands)
                indices = _spectral_indices_eau(bands)
                H, W = class_map.shape
                total = H * W
                turbidite_mean = float(np.mean(indices["Turbidite"][np.isfinite(indices["Turbidite"])]))
                contamination_pct = round(float(np.mean(class_map >= 3)) * 100, 1)
                status = "rouge" if turbidite_mean > 0.5 else "orange" if turbidite_mean > 0.3 else "vert"
                result = {
                    "zone_id": zone_id,
                    "type": "eau",
                    "timestamp": datetime.utcnow().isoformat(),
                    "source": "satellite_unet",
                    "turbidite": round(turbidite_mean, 4),
                    "contamination_pct": contamination_pct,
                    "status": status,
                    "indices": {k: round(float(np.mean(v[np.isfinite(v)])), 4) for k, v in indices.items()},
                    "anomaly_pixels": int((class_map >= 3).sum()),
                    "total_pixels": total,
                }
                with open(cache_file, "w") as f:
                    json.dump(result, f)
                return result

    result = _simulate_eau_data(zone_id)
    with open(cache_file, "w") as f:
        json.dump(result, f)
    return result


def get_all_zones_status() -> dict:
    """Snapshot of all zones — used for the live map."""
    zones_config = json.loads((DATA_DIR / "zones.json").read_text())
    result = {}
    for zone_id in zones_config["zones"]:
        sol = analyze_zone_sol(zone_id)
        eau = analyze_zone_eau(zone_id)
        result[zone_id] = {
            "sol": sol,
            "eau": eau,
            "zone_info": zones_config["zones"][zone_id],
        }
    return result


def get_contamination_timeline(zone_id: str, years: list = None) -> list:
    """Historical contamination trend — uses simulated data anchored to Kaggle results."""
    if years is None:
        years = list(range(2018, 2026))

    # Anchored to real Kaggle findings: degradation visible 2018→2024
    baseline = {
        "gct": {"contamination": 22, "health": 58},
        "ville": {"contamination": 12, "health": 70},
        "mer": {"contamination": 4, "health": 85},
        "oasis": {"contamination": 16, "health": 64},
    }.get(zone_id, {"contamination": 15, "health": 68})

    rng = np.random.default_rng(77)
    timeline = []
    contamination = baseline["contamination"]
    health = baseline["health"]

    for year in years:
        delta_c = rng.uniform(0.5, 1.5)
        delta_h = rng.uniform(-1.5, -0.3)
        contamination = min(50, contamination + delta_c)
        health = max(10, health + delta_h)
        timeline.append({
            "year": year,
            "contamination_pct": round(contamination, 1),
            "health_score": round(health, 1),
            "ndvi_mean": round(0.12 - (year - 2018) * 0.005 + rng.uniform(-0.005, 0.005), 4),
        })

    return timeline
