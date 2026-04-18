"""
Rule-based environmental classifier for Gabès sensor data.
Thresholds derived from WHO guidelines and GCT industrial pollution context.
"""
from app.models.measurement import Classification


# ── Soil thresholds ───────────────────────────────────────────────────────────
SOIL_THRESHOLDS = {
    "salinite":     {"orange": 4.0,  "rouge": 8.0},   # dS/m
    "contamination":{"orange": 0.3,  "rouge": 0.6},   # index 0-1
    "humidite":     {"orange": 15.0, "rouge": 8.0},   # % (low = critical)
}

# ── Water thresholds ──────────────────────────────────────────────────────────
WATER_THRESHOLDS = {
    "turbidite":  {"orange": 10.0, "rouge": 50.0},    # NTU
    "phosphates": {"orange": 0.5,  "rouge": 2.0},     # mg/L
    "eau_ph":     {"orange": 6.5,  "rouge": 5.5},     # pH (below = worse)
}

# ── Air thresholds (µg/m³) ────────────────────────────────────────────────────
AIR_THRESHOLDS = {
    "so2":  {"orange": 125.0, "rouge": 350.0},
    "h2s":  {"orange": 7.0,   "rouge": 14.0},
    "nh3":  {"orange": 200.0, "rouge": 400.0},
    "pm25": {"orange": 35.0,  "rouge": 75.0},
    "aqi":  {"orange": 100,   "rouge": 150},
}


def _classify_value(value: float, thresholds: dict, lower_is_worse: bool = False) -> Classification:
    if value is None:
        return Classification.vert
    orange_t = thresholds["orange"]
    rouge_t = thresholds["rouge"]
    if lower_is_worse:
        if value <= rouge_t:
            return Classification.rouge
        if value <= orange_t:
            return Classification.orange
        return Classification.vert
    else:
        if value >= rouge_t:
            return Classification.rouge
        if value >= orange_t:
            return Classification.orange
        return Classification.vert


def classify_soil(salinite=None, contamination=None, humidite=None) -> tuple[Classification, str]:
    results = []
    if salinite is not None:
        results.append(_classify_value(salinite, SOIL_THRESHOLDS["salinite"]))
    if contamination is not None:
        results.append(_classify_value(contamination, SOIL_THRESHOLDS["contamination"]))
    if humidite is not None:
        results.append(_classify_value(humidite, SOIL_THRESHOLDS["humidite"], lower_is_worse=True))

    if not results:
        return Classification.vert, "Normal"
    if Classification.rouge in results:
        return Classification.rouge, "Contamination critique détectée"
    if Classification.orange in results:
        return Classification.orange, "Stress détecté — surveillance requise"
    return Classification.vert, "État normal"


def classify_water(turbidite=None, phosphates=None, eau_ph=None) -> tuple[Classification, str]:
    results = []
    if turbidite is not None:
        results.append(_classify_value(turbidite, WATER_THRESHOLDS["turbidite"]))
    if phosphates is not None:
        results.append(_classify_value(phosphates, WATER_THRESHOLDS["phosphates"]))
    if eau_ph is not None:
        results.append(_classify_value(eau_ph, WATER_THRESHOLDS["eau_ph"], lower_is_worse=True))

    if not results:
        return Classification.vert, "Normal"
    if Classification.rouge in results:
        return Classification.rouge, "Rejet industriel probable — zone dangereuse"
    if Classification.orange in results:
        return Classification.orange, "Qualité dégradée — prudence requise"
    return Classification.vert, "Eau saine"


def classify_air(so2=None, h2s=None, nh3=None, pm25=None, aqi=None) -> tuple[Classification, str]:
    results = []
    for val, key in [(so2, "so2"), (h2s, "h2s"), (nh3, "nh3"), (pm25, "pm25"), (aqi, "aqi")]:
        if val is not None:
            results.append(_classify_value(val, AIR_THRESHOLDS[key]))

    if not results:
        return Classification.vert, "Normal"
    if Classification.rouge in results:
        return Classification.rouge, "Qualité de l'air dangereuse — restez à l'intérieur"
    if Classification.orange in results:
        return Classification.orange, "Qualité de l'air dégradée — limiter l'exposition"
    return Classification.vert, "Air sain"


def classify_measurement(sensor_type: str, data: dict) -> tuple[Classification, str]:
    if sensor_type == "sol":
        return classify_soil(
            salinite=data.get("salinite"),
            contamination=data.get("contamination"),
            humidite=data.get("humidite"),
        )
    elif sensor_type == "eau":
        return classify_water(
            turbidite=data.get("turbidite"),
            phosphates=data.get("phosphates"),
            eau_ph=data.get("eau_ph"),
        )
    elif sensor_type == "air":
        return classify_air(
            so2=data.get("so2"),
            h2s=data.get("h2s"),
            nh3=data.get("nh3"),
            pm25=data.get("pm25"),
            aqi=data.get("aqi"),
        )
    return Classification.vert, "Normal"
