from sqlalchemy import Column, String, Float, Boolean, DateTime, Enum as SAEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
import enum
from app.database import Base


class DroneStatus(str, enum.Enum):
    en_vol = "en_vol"
    pause = "pause"
    maintenance = "maintenance"
    deconnecte = "deconnecte"


class DroneSession(Base):
    __tablename__ = "drone_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    secteur = Column(String(100), nullable=False)
    status = Column(SAEnum(DroneStatus), default=DroneStatus.deconnecte)
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    ended_at = Column(DateTime(timezone=True), nullable=True)
    mission_actuelle = Column(String(200), nullable=True)
    distance_parcourue = Column(Float, default=0.0)


class DroneTelemetry(Base):
    __tablename__ = "drone_telemetry"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("drone_sessions.id"), nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    # Position
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    altitude = Column(Float, default=0.0)

    # Flight data
    batterie = Column(Float, default=100.0)
    vitesse = Column(Float, default=0.0)
    signal_force = Column(Float, default=100.0)
    vent = Column(Float, default=0.0)
    temperature = Column(Float, default=25.0)
    status = Column(SAEnum(DroneStatus), default=DroneStatus.deconnecte)

    # Mission
    mission_actuelle = Column(String(200), nullable=True)
    mission_progress = Column(Float, default=0.0)
    distance_parcourue = Column(Float, default=0.0)

    # Capteurs actifs
    multispectral_actif = Column(Boolean, default=True)
    thermique_actif = Column(Boolean, default=True)
    atmospherique_actif = Column(Boolean, default=True)
