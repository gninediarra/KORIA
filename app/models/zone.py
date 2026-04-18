from sqlalchemy import Column, String, Float, Integer, DateTime, Enum as SAEnum, ARRAY, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
import enum
from app.database import Base


class ZoneType(str, enum.Enum):
    industriel = "industriel"
    portuaire = "portuaire"
    agricole = "agricole"
    cotier = "cotier"
    urbain = "urbain"
    maritime = "maritime"


class Zone(Base):
    __tablename__ = "zones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    type = Column(SAEnum(ZoneType), nullable=False)
    status = Column(String(20), default="vert")  # vert / orange / rouge

    # Géométrie
    polygon = Column(JSON, nullable=True)       # [{"lat": x, "lng": y}, ...]
    center_lat = Column(Float, nullable=False)
    center_lng = Column(Float, nullable=False)

    # Lecture Sol
    sol_salinite = Column(Float, nullable=True)
    sol_ph = Column(Float, nullable=True)
    sol_humidite = Column(Float, nullable=True)
    sol_contamination = Column(Float, nullable=True)
    sol_etat = Column(String(50), nullable=True)

    # Lecture Eau
    eau_turbidite = Column(Float, nullable=True)
    eau_ph = Column(Float, nullable=True)
    eau_phosphates = Column(Float, nullable=True)
    eau_temperature = Column(Float, nullable=True)
    eau_etat = Column(String(50), nullable=True)

    # Lecture Air
    air_so2 = Column(Float, nullable=True)
    air_h2s = Column(Float, nullable=True)
    air_nh3 = Column(Float, nullable=True)
    air_pm25 = Column(Float, nullable=True)
    air_aqi = Column(Integer, nullable=True)
    air_etat = Column(String(50), nullable=True)

    recommandations = Column(JSON, default=list)   # ["...", "..."]
    derniere_analyse = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
