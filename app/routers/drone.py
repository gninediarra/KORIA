from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone
from app.database import get_db
from app.models.drone import DroneSession, DroneTelemetry, DroneStatus
from app.models.measurement import Measurement
from app.schemas.drone import DroneSessionCreate, DroneSessionOut, TelemetryIn, TelemetryOut
from app.schemas.measurement import MeasurementIn, MeasurementOut
from app.services.ai_classifier import classify_measurement
from app.services.alert_engine import generate_alerts
from app.services.deps import get_current_user
from app.models.user import User
from app.models.alert import Alert

router = APIRouter(prefix="/api/drone", tags=["drone"])


@router.get("/sessions", response_model=List[DroneSessionOut])
def list_sessions(db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return db.query(DroneSession).order_by(DroneSession.started_at.desc()).all()


@router.post("/sessions", response_model=DroneSessionOut, status_code=status.HTTP_201_CREATED)
def create_session(
    body: DroneSessionCreate,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    session = DroneSession(secteur=body.secteur, mission_actuelle=body.mission_actuelle)
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("/sessions/{session_id}", response_model=DroneSessionOut)
def get_session(session_id: str, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    session = db.query(DroneSession).filter(DroneSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")
    return session


@router.put("/sessions/{session_id}/end", response_model=DroneSessionOut)
def end_session(session_id: str, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    session = db.query(DroneSession).filter(DroneSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")
    session.ended_at = datetime.now(timezone.utc)
    session.status = DroneStatus.deconnecte
    db.commit()
    db.refresh(session)
    return session


@router.post("/telemetry", response_model=TelemetryOut, status_code=status.HTTP_201_CREATED)
def push_telemetry(body: TelemetryIn, db: Session = Depends(get_db)):
    session = db.query(DroneSession).filter(DroneSession.id == body.session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")

    session.status = body.status
    if body.mission_actuelle:
        session.mission_actuelle = body.mission_actuelle
    session.distance_parcourue = body.distance_parcourue

    t = DroneTelemetry(**body.model_dump())
    db.add(t)
    db.commit()
    db.refresh(t)
    return t


@router.get("/telemetry/latest/{session_id}", response_model=TelemetryOut)
def latest_telemetry(session_id: str, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    t = (
        db.query(DroneTelemetry)
        .filter(DroneTelemetry.session_id == session_id)
        .order_by(DroneTelemetry.timestamp.desc())
        .first()
    )
    if not t:
        raise HTTPException(status_code=404, detail="Aucune télémétrie disponible")
    return t


@router.post("/measurements", response_model=MeasurementOut, status_code=status.HTTP_201_CREATED)
def push_measurement(body: MeasurementIn, db: Session = Depends(get_db)):
    session = db.query(DroneSession).filter(DroneSession.id == body.session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")

    data = body.model_dump()
    classification, etat = classify_measurement(body.sensor_type.value, data)

    m = Measurement(**data, classification=classification, etat=etat)
    db.add(m)
    db.flush()

    # Auto-generate alerts for orange/rouge
    zone_name = session.secteur
    alerts_data = generate_alerts(body.sensor_type.value, classification, zone_name, body.zone_id)
    if alerts_data:
        for a in alerts_data:
            db.add(Alert(**a))

    db.commit()
    db.refresh(m)
    return m
