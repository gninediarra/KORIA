from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Enum as SAEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
import enum
from app.database import Base


class ActionType(str, enum.Enum):
    report_anomaly       = "report_anomaly"
    cleanup_participation = "cleanup_participation"
    eco_route            = "eco_route"
    vote_priority        = "vote_priority"
    daily_bonus          = "daily_bonus"
    merchant_redeem      = "merchant_redeem"
    utility_redeem       = "utility_redeem"
    admin_award          = "admin_award"
    welcome_bonus        = "welcome_bonus"


class AnomalyStatus(str, enum.Enum):
    pending   = "pending"
    validated = "validated"
    rejected  = "rejected"


class CleanupStatus(str, enum.Enum):
    upcoming  = "upcoming"
    active    = "active"
    completed = "completed"
    cancelled = "cancelled"


class TokenTransaction(Base):
    __tablename__ = "token_transactions"

    id          = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id     = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    amount      = Column(Integer, nullable=False)   # positif = gain, négatif = dépense
    action_type = Column(SAEnum(ActionType), nullable=False)
    description = Column(String(255), nullable=True)
    tx_hash     = Column(String(100), nullable=True)   # hash blockchain (optionnel)
    timestamp   = Column(DateTime(timezone=True), server_default=func.now())


class ReportedAnomaly(Base):
    __tablename__ = "reported_anomalies"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id        = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    description    = Column(String(1000), nullable=False)
    sensor_type    = Column(String(20), nullable=True)   # sol / eau / air
    lat            = Column(Float, nullable=False)
    lng            = Column(Float, nullable=False)
    zone_name      = Column(String(100), nullable=True)
    photo_url      = Column(String(500), nullable=True)
    status         = Column(SAEnum(AnomalyStatus), default=AnomalyStatus.pending, nullable=False)
    tokens_awarded = Column(Integer, default=0)
    validated_by   = Column(String(50), nullable=True)   # "drone" | "admin"
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    validated_at   = Column(DateTime(timezone=True), nullable=True)


class CleanupEvent(Base):
    __tablename__ = "cleanup_events"

    id               = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title            = Column(String(200), nullable=False)
    description      = Column(String(1000), nullable=True)
    zone_name        = Column(String(100), nullable=True)
    lat              = Column(Float, nullable=True)
    lng              = Column(Float, nullable=True)
    date             = Column(DateTime(timezone=True), nullable=False)
    max_participants = Column(Integer, default=50)
    tokens_reward    = Column(Integer, default=100)
    status           = Column(SAEnum(CleanupStatus), default=CleanupStatus.upcoming, nullable=False)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())


class CleanupParticipant(Base):
    __tablename__ = "cleanup_participants"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_id        = Column(UUID(as_uuid=True), ForeignKey("cleanup_events.id", ondelete="CASCADE"), nullable=False)
    user_id         = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    joined_at       = Column(DateTime(timezone=True), server_default=func.now())
    validated       = Column(Boolean, default=False)
    tokens_received = Column(Integer, default=0)


class DronePriorityVote(Base):
    __tablename__ = "drone_priority_votes"

    id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id      = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    zone_name    = Column(String(100), nullable=False)
    week_of      = Column(String(10), nullable=False)   # ex: "2026-W17"
    tokens_spent = Column(Integer, nullable=False)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
