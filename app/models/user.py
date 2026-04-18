from sqlalchemy import Column, String, Boolean, DateTime, Integer, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
import enum
from app.database import Base


class UserRole(str, enum.Enum):
    agriculteur = "agriculteur"
    pecheur     = "pecheur"
    autorite    = "autorite"
    citoyen     = "citoyen"


class User(Base):
    __tablename__ = "users"

    id                    = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name                  = Column(String(100), nullable=False)
    email                 = Column(String(255), unique=True, nullable=False, index=True)
    password_hash         = Column(String(255), nullable=False)
    role                  = Column(SAEnum(UserRole), nullable=False, default=UserRole.citoyen)
    quartier              = Column(String(100), nullable=True)
    parcelle              = Column(String(100), nullable=True)
    is_active             = Column(Boolean, default=True)
    created_at            = Column(DateTime(timezone=True), server_default=func.now())

    # ─── Blockchain ───────────────────────────────────────────────────────────
    wallet_address        = Column(String(42), unique=True, nullable=True)   # 0x + 40 hex
    encrypted_private_key = Column(String(500), nullable=True)               # Fernet-encrypted
    eco_tokens            = Column(Integer, default=0, nullable=False)       # Solde local (cache)
