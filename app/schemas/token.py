from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime
from app.models.token import ActionType, AnomalyStatus, CleanupStatus

# ─── Token balance ────────────────────────────────────────────────────────────

class TokenBalance(BaseModel):
    wallet_address: Optional[str]
    eco_tokens: int
    onchain_balance: Optional[int] = None   # None si blockchain non disponible

# ─── Token transaction ────────────────────────────────────────────────────────

class TokenTransactionOut(BaseModel):
    id: UUID
    amount: int
    action_type: ActionType
    description: Optional[str]
    tx_hash: Optional[str]
    timestamp: datetime

    model_config = {"from_attributes": True}

# ─── Anomaly report ───────────────────────────────────────────────────────────

class ReportAnomalyIn(BaseModel):
    description: str = Field(..., min_length=10, max_length=1000)
    sensor_type: Optional[str] = None   # sol / eau / air
    lat: float
    lng: float
    zone_name: Optional[str] = None
    photo_url: Optional[str] = None

class AnomalyOut(BaseModel):
    id: UUID
    description: str
    sensor_type: Optional[str]
    lat: float
    lng: float
    zone_name: Optional[str]
    status: AnomalyStatus
    tokens_awarded: int
    validated_by: Optional[str]
    created_at: datetime
    validated_at: Optional[datetime]

    model_config = {"from_attributes": True}

class ValidateAnomalyIn(BaseModel):
    validated_by: str = "admin"   # "drone" ou "admin"
    tokens_to_award: int = 50

# ─── Cleanup event ────────────────────────────────────────────────────────────

class CleanupEventOut(BaseModel):
    id: UUID
    title: str
    description: Optional[str]
    zone_name: Optional[str]
    lat: Optional[float]
    lng: Optional[float]
    date: datetime
    max_participants: int
    tokens_reward: int
    status: CleanupStatus
    participant_count: int = 0

    model_config = {"from_attributes": True}

class CreateCleanupEventIn(BaseModel):
    title: str
    description: Optional[str] = None
    zone_name: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    date: datetime
    max_participants: int = 50
    tokens_reward: int = 100

# ─── Drone priority vote ──────────────────────────────────────────────────────

class VotePriorityIn(BaseModel):
    zone_name: str
    tokens_to_spend: int = Field(20, ge=20)

class VotePriorityOut(BaseModel):
    zone_name: str
    week_of: str
    tokens_spent: int
    remaining_balance: int

class DronePriorityResult(BaseModel):
    zone_name: str
    total_votes: int
    total_tokens: int

# ─── Leaderboard ─────────────────────────────────────────────────────────────

class LeaderboardEntry(BaseModel):
    rank: int
    user_id: UUID
    name: str
    eco_tokens: int
    role: str
