from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime
from app.models.drone import DroneStatus


class DroneSessionCreate(BaseModel):
    secteur: str
    mission_actuelle: Optional[str] = None


class DroneSessionOut(BaseModel):
    id: UUID
    secteur: str
    status: DroneStatus
    started_at: datetime
    ended_at: Optional[datetime]
    mission_actuelle: Optional[str]
    distance_parcourue: float

    model_config = {"from_attributes": True}


class TelemetryIn(BaseModel):
    session_id: UUID
    lat: float
    lng: float
    altitude: float = 0.0
    batterie: float = 100.0
    vitesse: float = 0.0
    signal_force: float = 100.0
    vent: float = 0.0
    temperature: float = 25.0
    status: DroneStatus = DroneStatus.en_vol
    mission_actuelle: Optional[str] = None
    mission_progress: float = 0.0
    distance_parcourue: float = 0.0
    multispectral_actif: bool = True
    thermique_actif: bool = True
    atmospherique_actif: bool = True


class TelemetryOut(TelemetryIn):
    id: UUID
    timestamp: datetime

    model_config = {"from_attributes": True}
