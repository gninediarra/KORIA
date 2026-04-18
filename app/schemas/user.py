from pydantic import BaseModel, EmailStr
from typing import Optional
from uuid import UUID
from datetime import datetime
from app.models.user import UserRole


class UserCreate(BaseModel):
    name:     str
    email:    EmailStr
    password: str
    role:     UserRole = UserRole.citoyen
    quartier: Optional[str] = None
    parcelle: Optional[str] = None


class UserUpdate(BaseModel):
    name:     Optional[str] = None
    quartier: Optional[str] = None
    parcelle: Optional[str] = None


class UserOut(BaseModel):
    id:             UUID
    name:           str
    email:          str
    role:           UserRole
    quartier:       Optional[str]
    parcelle:       Optional[str]
    is_active:      bool
    created_at:     datetime
    wallet_address: Optional[str] = None
    eco_tokens:     int = 0

    model_config = {"from_attributes": True}


class RegisterOut(UserOut):
    """Réponse enrichie à l'inscription : expose l'adresse du nouveau portefeuille."""
    wallet_address: str   # toujours présent à l'inscription


class Token(BaseModel):
    access_token: str
    token_type:   str = "bearer"
    user:         UserOut


class LoginRequest(BaseModel):
    email:    EmailStr
    password: str
