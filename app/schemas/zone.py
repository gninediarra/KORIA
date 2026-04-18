from pydantic import BaseModel
from typing import Optional, List, Any
from uuid import UUID
from datetime import datetime
from app.models.zone import ZoneType


class SoilReadings(BaseModel):
    salinite: Optional[float] = None
    ph: Optional[float] = None
    humidite: Optional[float] = None
    contamination: Optional[float] = None
    etat: Optional[str] = None


class WaterReadings(BaseModel):
    turbidite: Optional[float] = None
    ph: Optional[float] = None
    phosphates: Optional[float] = None
    temperature: Optional[float] = None
    etat: Optional[str] = None


class AirReadings(BaseModel):
    so2: Optional[float] = None
    h2s: Optional[float] = None
    nh3: Optional[float] = None
    pm25: Optional[float] = None
    aqi: Optional[int] = None
    etat: Optional[str] = None


class ZoneCreate(BaseModel):
    name: str
    type: ZoneType
    center_lat: float
    center_lng: float
    polygon: Optional[List[Any]] = None
    sol: Optional[SoilReadings] = None
    water: Optional[WaterReadings] = None
    air: Optional[AirReadings] = None
    recommandations: Optional[List[str]] = None


class ZoneOut(BaseModel):
    id: UUID
    name: str
    type: ZoneType
    status: str
    center_lat: float
    center_lng: float
    polygon: Optional[Any]
    sol: SoilReadings
    water: WaterReadings
    air: AirReadings
    recommandations: List[str]
    derniere_analyse: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_zone(cls, z):
        return cls(
            id=z.id,
            name=z.name,
            type=z.type,
            status=z.status,
            center_lat=z.center_lat,
            center_lng=z.center_lng,
            polygon=z.polygon,
            sol=SoilReadings(
                salinite=z.sol_salinite, ph=z.sol_ph,
                humidite=z.sol_humidite, contamination=z.sol_contamination, etat=z.sol_etat,
            ),
            water=WaterReadings(
                turbidite=z.eau_turbidite, ph=z.eau_ph,
                phosphates=z.eau_phosphates, temperature=z.eau_temperature, etat=z.eau_etat,
            ),
            air=AirReadings(
                so2=z.air_so2, h2s=z.air_h2s, nh3=z.air_nh3,
                pm25=z.air_pm25, aqi=z.air_aqi, etat=z.air_etat,
            ),
            recommandations=z.recommandations or [],
            derniere_analyse=z.derniere_analyse,
        )
