from sqlalchemy import Column, String, Boolean, DateTime, Enum as SAEnum, JSON, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
import enum
from app.database import Base


class AlertSeverity(str, enum.Enum):
    critique = "critique"
    avertissement = "avertissement"
    info = "info"


class Alert(Base):
    __tablename__ = "alerts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    titre = Column(String(200), nullable=False)
    description = Column(String(1000), nullable=False)
    severite = Column(SAEnum(AlertSeverity), nullable=False)
    roles_target = Column(JSON, nullable=False)   # ["agriculteur", "citoyen", ...]
    zone_name = Column(String(100), nullable=False)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"), nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    recommandations = Column(JSON, default=list)
    is_active = Column(Boolean, default=True)
