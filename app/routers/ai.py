"""
GabèsEye AI Router — LLM agents + zone intelligence.
Integrates Groq Llama-3.3-70b-versatile via agent_engine.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from uuid import UUID

from app.database import get_db
from app.models.zone import Zone
from app.models.user import User
from app.schemas.zone import ZoneOut
from app.services.deps import get_current_user
from app.services import agent_engine

router = APIRouter(prefix="/api/ai", tags=["AI Agents"])

SUPPORTED_ROLES = {"citoyen", "agriculteur", "pecheur", "autorite"}


# ── Request models ────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    history: list = []
    langue: str = "fr"
    zone_id: Optional[str] = None


class AgentRequest(BaseModel):
    role: str = "citoyen"
    langue: str = "fr"
    question: str = ""
    zone_id: Optional[str] = None


class HealthRiskRequest(BaseModel):
    zone_id: Optional[str] = None
    age: int = 35
    conditions: list = []
    activite: str = "bureau"
    langue: str = "fr"


# ── Helpers ───────────────────────────────────────────────────────────────────

def _zone_to_context(z: Zone) -> dict:
    return {
        "zone_name": z.name,
        "sol": {
            "salinite": z.sol_salinite,
            "contamination": z.sol_contamination,
            "humidite": z.sol_humidite,
            "etat": z.sol_etat,
        },
        "eau": {
            "turbidite": z.eau_turbidite,
            "phosphates": z.eau_phosphates,
            "ph": z.eau_ph,
            "etat": z.eau_etat,
        },
        "air": {
            "aqi": z.air_aqi,
            "so2": z.air_so2,
            "h2s": z.air_h2s,
            "pm25": z.air_pm25,
            "etat": z.air_etat,
        },
    }


def _best_zone(role: str, user: User, db: Session) -> dict:
    """Pick the most relevant zone for this user's role."""
    zones = db.query(Zone).all()
    if not zones:
        return {}

    if role == "agriculteur":
        # Prefer sol zones
        z = next((z for z in zones if z.type and "sol" in z.type.value.lower()), zones[0])
    elif role == "pecheur":
        # Prefer water zones
        z = next((z for z in zones if z.type and "eau" in z.type.value.lower()), zones[0])
    else:
        # Default: worst air quality zone (most relevant for citoyen/autorite)
        zones_with_aqi = [z for z in zones if z.air_aqi is not None]
        if zones_with_aqi:
            z = max(zones_with_aqi, key=lambda x: x.air_aqi)
        else:
            z = zones[0]

    return _zone_to_context(z)


def _get_zone_by_id(zone_id: str, db: Session) -> dict:
    try:
        zone = db.query(Zone).filter(Zone.id == UUID(zone_id)).first()
    except Exception:
        zone = db.query(Zone).filter(Zone.name.ilike(f"%{zone_id}%")).first()
    if not zone:
        return {}
    return _zone_to_context(zone)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/chat")
async def chat(
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Multi-turn conversational AI agent — role-aware, zone-contextual."""
    role = current_user.role.value

    if body.zone_id:
        zone_data = _get_zone_by_id(body.zone_id, db)
    else:
        zone_data = _best_zone(role, current_user, db)

    result = await agent_engine.conversational_agent(
        message=body.message,
        history=body.history,
        role=role,
        langue=body.langue,
        zone_data=zone_data,
    )
    return result


@router.post("/agent")
async def agent_query(
    body: AgentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """One-shot role agent — returns a full environmental analysis."""
    role = body.role if body.role in SUPPORTED_ROLES else current_user.role.value

    if body.zone_id:
        zone_data = _get_zone_by_id(body.zone_id, db)
    else:
        zone_data = _best_zone(role, current_user, db)

    return await agent_engine.role_agent(
        role=role,
        zone_data=zone_data,
        langue=body.langue,
        question=body.question,
    )


@router.post("/health-risk")
async def health_risk_assessment(
    body: HealthRiskRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Personalized health risk based on user profile + current air quality."""
    if body.zone_id:
        zone_data = _get_zone_by_id(body.zone_id, db)
    else:
        zone_data = _best_zone("citoyen", current_user, db)

    profil = {
        "age": body.age,
        "conditions": body.conditions,
        "activite": body.activite,
        "langue": body.langue,
    }
    return await agent_engine.health_risk(zone_data=zone_data, profil=profil)


@router.get("/zone/{zone_id}/summary")
def zone_summary(
    zone_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """Returns structured zone data formatted for AI context display."""
    zone_data = _get_zone_by_id(zone_id, db)
    if not zone_data:
        raise HTTPException(status_code=404, detail="Zone introuvable")
    return zone_data


@router.get("/zones/summary")
def all_zones_summary(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """Returns a summary of all zones for the AI dashboard."""
    zones = db.query(Zone).all()
    return [_zone_to_context(z) for z in zones]
