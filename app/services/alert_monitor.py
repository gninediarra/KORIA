"""
AlertMonitor — Background task that checks air quality every 5 min.
Creates DB alerts when SO₂/AQI/PM2.5 exceed thresholds.
Runs as an asyncio background task during FastAPI lifespan.
"""
import asyncio
from datetime import datetime
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.services.realtime_engine import get_realtime_alert

_ZONES = ["gct", "ville", "mer", "oasis"]

# (warn_threshold, crit_threshold)
_THRESHOLDS = {
    "so2":  (100.0, 200.0),
    "aqi":  (150.0, 250.0),
    "pm25": (35.0,  75.0),
}

_RECOMMANDATIONS = {
    "so2": [
        "Fermez les fenêtres et restez à l'intérieur.",
        "Évitez tout effort physique en extérieur.",
        "Portez un masque FFP2 si vous devez sortir.",
        "Contactez un médecin si vous avez des difficultés respiratoires.",
    ],
    "aqi": [
        "Limitez les sorties, surtout pour les enfants et personnes âgées.",
        "Fenêtres fermées recommandées entre 10h et 16h.",
        "Consultez la carte GabèsEye pour les zones les moins polluées.",
    ],
    "pm25": [
        "Évitez les activités sportives en extérieur.",
        "Utilisez un purificateur d'air si disponible.",
        "Personnes asthmatiques: précautions maximales.",
    ],
}

_ROLES_ALL = ["citoyen", "autorite", "agriculteur", "pecheur"]


async def run_alert_monitor():
    """Infinite loop — checks every 5 minutes and creates DB alerts."""
    # Wait for server to fully start
    await asyncio.sleep(15)

    fired_keys: set[str] = set()
    print("[AlertMonitor] Started — checking every 5 minutes")

    while True:
        try:
            for zone_id in _ZONES:
                try:
                    air = await get_realtime_alert(zone_id)
                    aq = air.get("air_quality", {})

                    so2  = float(aq.get("so2")  or 0)
                    aqi  = float(aq.get("aqi")  or 0)
                    pm25 = float(aq.get("pm25") or 0)

                    checks = [
                        ("so2",  so2,  f"SO₂ = {so2:.1f} µg/m³ (seuil OMS: 100 µg/m³)"),
                        ("aqi",  aqi,  f"AQI = {int(aqi)} — Niveau MAUVAIS (seuil: 150)"),
                        ("pm25", pm25, f"PM2.5 = {pm25:.1f} µg/m³ (seuil: 35 µg/m³)"),
                    ]

                    for metric, val, description in checks:
                        warn_th, crit_th = _THRESHOLDS[metric]
                        bucket = int(val / 50)  # key changes when value crosses a 50-unit bucket

                        if val > crit_th:
                            from app.models.alert import AlertSeverity
                            sev = AlertSeverity.critique
                            titre = f"🚨 {metric.upper()} CRITIQUE — Zone {zone_id.upper()}"
                        elif val > warn_th:
                            from app.models.alert import AlertSeverity
                            sev = AlertSeverity.avertissement
                            titre = f"⚠️ {metric.upper()} élevé — Zone {zone_id.upper()}"
                        else:
                            fired_keys.discard(f"{zone_id}_{metric}")
                            continue

                        alert_key = f"{zone_id}_{metric}_{bucket}"
                        if alert_key in fired_keys:
                            continue
                        fired_keys.add(alert_key)

                        # Create alert in DB
                        db: Session = SessionLocal()
                        try:
                            from app.models.alert import Alert
                            alert = Alert(
                                titre=titre,
                                description=description,
                                severite=sev,
                                roles_target=_ROLES_ALL,
                                zone_name=zone_id.upper(),
                                recommandations=_RECOMMANDATIONS.get(metric, []),
                            )
                            db.add(alert)
                            db.commit()
                            print(f"[AlertMonitor] Created alert: {titre}")
                        except Exception as e:
                            print(f"[AlertMonitor] DB error creating alert: {e}")
                            db.rollback()
                        finally:
                            db.close()

                except Exception as e:
                    print(f"[AlertMonitor] Zone {zone_id} check error: {e}")

        except Exception as e:
            print(f"[AlertMonitor] Outer error: {e}")

        await asyncio.sleep(300)  # 5 minutes
