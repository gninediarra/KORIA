from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime
from app.models.measurement import SensorType, Classification


class MeasurementIn(BaseModel):
    session_id: UUID
    zone_id: Optional[UUID] = None
    lat: float
    lng: float
    sensor_type: SensorType

    # Sol
    salinite: Optional[float] = None
    sol_ph: Optional[float] = None
    humidite: Optional[float] = None
    contamination: Optional[float] = None

    # Eau
    turbidite: Optional[float] = None
    eau_ph: Optional[float] = None
    phosphates: Optional[float] = None
    eau_temperature: Optional[float] = None

    # Air
    so2: Optional[float] = None
    h2s: Optional[float] = None
    nh3: Optional[float] = None
    pm25: Optional[float] = None
    aqi: Optional[int] = None


class MeasurementOut(MeasurementIn):
    id: UUID
    timestamp: datetime
    classification: Classification
    etat: Optional[str]

    model_config = {"from_attributes": True}
