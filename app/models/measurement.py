from sqlalchemy import Column, String, Float, Integer, DateTime, Enum as SAEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
import enum
from app.database import Base


class SensorType(str, enum.Enum):
    sol = "sol"
    eau = "eau"
    air = "air"


class Classification(str, enum.Enum):
    vert = "vert"
    orange = "orange"
    rouge = "rouge"


class Measurement(Base):
    __tablename__ = "measurements"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("drone_sessions.id"), nullable=False)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"), nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    sensor_type = Column(SAEnum(SensorType), nullable=False)
    classification = Column(SAEnum(Classification), default=Classification.vert)

    # Sol
    salinite = Column(Float, nullable=True)
    sol_ph = Column(Float, nullable=True)
    humidite = Column(Float, nullable=True)
    contamination = Column(Float, nullable=True)

    # Eau
    turbidite = Column(Float, nullable=True)
    eau_ph = Column(Float, nullable=True)
    phosphates = Column(Float, nullable=True)
    eau_temperature = Column(Float, nullable=True)

    # Air
    so2 = Column(Float, nullable=True)
    h2s = Column(Float, nullable=True)
    nh3 = Column(Float, nullable=True)
    pm25 = Column(Float, nullable=True)
    aqi = Column(Integer, nullable=True)

    etat = Column(String(50), nullable=True)
