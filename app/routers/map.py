from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models.zone import Zone
from app.models.measurement import Measurement, SensorType
from app.schemas.zone import ZoneCreate, ZoneOut, SoilReadings, WaterReadings, AirReadings
from app.services.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/api/map", tags=["map"])


@router.get("/zones", response_model=List[ZoneOut])
def list_zones(
    type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    q = db.query(Zone)
    if type:
        q = q.filter(Zone.type == type)
    if status:
        q = q.filter(Zone.status == status)
    zones = q.all()
    return [ZoneOut.from_orm_zone(z) for z in zones]


@router.get("/zones/{zone_id}", response_model=ZoneOut)
def get_zone(zone_id: str, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    zone = db.query(Zone).filter(Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone introuvable")
    return ZoneOut.from_orm_zone(zone)


@router.post("/zones", response_model=ZoneOut, status_code=201)
def create_zone(body: ZoneCreate, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    sol = body.sol or SoilReadings()
    water = body.water or WaterReadings()
    air = body.air or AirReadings()

    zone = Zone(
        name=body.name,
        type=body.type,
        center_lat=body.center_lat,
        center_lng=body.center_lng,
        polygon=body.polygon,
        sol_salinite=sol.salinite, sol_ph=sol.ph,
        sol_humidite=sol.humidite, sol_contamination=sol.contamination, sol_etat=sol.etat,
        eau_turbidite=water.turbidite, eau_ph=water.ph,
        eau_phosphates=water.phosphates, eau_temperature=water.temperature, eau_etat=water.etat,
        air_so2=air.so2, air_h2s=air.h2s, air_nh3=air.nh3,
        air_pm25=air.pm25, air_aqi=air.aqi, air_etat=air.etat,
        recommandations=body.recommandations or [],
    )
    db.add(zone)
    db.commit()
    db.refresh(zone)
    return ZoneOut.from_orm_zone(zone)


@router.get("/layers/{layer_type}")
def get_map_layer(
    layer_type: str,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """Returns latest measurements for the map layer (sol / eau / air)."""
    valid = ["sol", "eau", "air"]
    if layer_type not in valid:
        raise HTTPException(status_code=400, detail=f"layer_type must be one of {valid}")

    sensor = SensorType(layer_type)

    # Latest measurement per (lat, lng) bucket — last 24h data
    measurements = (
        db.query(Measurement)
        .filter(Measurement.sensor_type == sensor)
        .order_by(Measurement.timestamp.desc())
        .limit(500)
        .all()
    )

    return {
        "layer": layer_type,
        "count": len(measurements),
        "points": [
            {
                "lat": m.lat,
                "lng": m.lng,
                "classification": m.classification.value,
                "etat": m.etat,
                "timestamp": m.timestamp.isoformat(),
                "data": _extract_layer_data(m, layer_type),
            }
            for m in measurements
        ],
    }


def _extract_layer_data(m: Measurement, layer: str) -> dict:
    if layer == "sol":
        return {"salinite": m.salinite, "ph": m.sol_ph, "humidite": m.humidite, "contamination": m.contamination}
    if layer == "eau":
        return {"turbidite": m.turbidite, "ph": m.eau_ph, "phosphates": m.phosphates, "temperature": m.eau_temperature}
    return {"so2": m.so2, "h2s": m.h2s, "nh3": m.nh3, "pm25": m.pm25, "aqi": m.aqi}
