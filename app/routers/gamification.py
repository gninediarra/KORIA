from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List
from datetime import datetime, timezone

from app.database import get_db
from app.models.user import User
from app.models.token import (
    ReportedAnomaly, AnomalyStatus,
    CleanupEvent, CleanupParticipant, CleanupStatus,
    TokenTransaction, ActionType,
)
from app.schemas.token import (
    ReportAnomalyIn, AnomalyOut, ValidateAnomalyIn,
    CleanupEventOut, CreateCleanupEventIn,
)
from app.services.deps import get_current_user
from app.services.blockchain import award_tokens_onchain

router = APIRouter(prefix="/api/gamification", tags=["gamification"])

ANOMALY_TOKENS = 50
CLEANUP_TOKENS = 100


# ─── Signalement d'anomalies ─────────────────────────────────────────────────

@router.post("/report-anomaly", response_model=AnomalyOut, status_code=201)
def report_anomaly(
    body: ReportAnomalyIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    report = ReportedAnomaly(
        user_id=current_user.id,
        description=body.description,
        sensor_type=body.sensor_type,
        lat=body.lat,
        lng=body.lng,
        zone_name=body.zone_name,
        photo_url=body.photo_url,
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report


@router.get("/my-reports", response_model=List[AnomalyOut])
def my_reports(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(ReportedAnomaly)
        .filter(ReportedAnomaly.user_id == current_user.id)
        .order_by(desc(ReportedAnomaly.created_at))
        .all()
    )


@router.get("/reports", response_model=List[AnomalyOut])
def all_reports(
    status: AnomalyStatus = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role.value != "autorite":
        raise HTTPException(status_code=403, detail="Réservé aux autorités")
    q = db.query(ReportedAnomaly)
    if status:
        q = q.filter(ReportedAnomaly.status == status)
    return q.order_by(desc(ReportedAnomaly.created_at)).all()


@router.put("/reports/{report_id}/validate", response_model=AnomalyOut)
def validate_anomaly(
    report_id: str,
    body: ValidateAnomalyIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role.value != "autorite":
        raise HTTPException(status_code=403, detail="Réservé aux autorités")

    report = db.query(ReportedAnomaly).filter(ReportedAnomaly.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Signalement introuvable")
    if report.status != AnomalyStatus.pending:
        raise HTTPException(status_code=400, detail="Signalement déjà traité")

    reporter = db.query(User).filter(User.id == report.user_id).first()
    tokens = body.tokens_to_award

    report.status        = AnomalyStatus.validated
    report.validated_by  = body.validated_by
    report.validated_at  = datetime.now(timezone.utc)
    report.tokens_awarded = tokens

    reporter.eco_tokens += tokens
    tx_hash = award_tokens_onchain(
        reporter.wallet_address or "", tokens, f"anomaly_validated:{report_id}"
    )
    db.add(TokenTransaction(
        user_id=reporter.id,
        amount=tokens,
        action_type=ActionType.report_anomaly,
        description=f"Anomalie validée — {report.zone_name or 'zone inconnue'}",
        tx_hash=tx_hash,
    ))
    db.commit()
    db.refresh(report)
    return report


@router.put("/reports/{report_id}/reject", response_model=AnomalyOut)
def reject_anomaly(
    report_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role.value != "autorite":
        raise HTTPException(status_code=403, detail="Réservé aux autorités")

    report = db.query(ReportedAnomaly).filter(ReportedAnomaly.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Signalement introuvable")

    report.status       = AnomalyStatus.rejected
    report.validated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(report)
    return report


# ─── Événements de nettoyage ─────────────────────────────────────────────────

def _enrich(event: CleanupEvent, db: Session) -> CleanupEventOut:
    count = db.query(CleanupParticipant).filter(
        CleanupParticipant.event_id == event.id
    ).count()
    out = CleanupEventOut.model_validate(event)
    out.participant_count = count
    return out


@router.get("/cleanup-events", response_model=List[CleanupEventOut])
def list_cleanup_events(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    events = db.query(CleanupEvent).order_by(CleanupEvent.date).all()
    return [_enrich(e, db) for e in events]


@router.post("/cleanup-events", response_model=CleanupEventOut, status_code=201)
def create_cleanup_event(
    body: CreateCleanupEventIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role.value != "autorite":
        raise HTTPException(status_code=403, detail="Réservé aux autorités")

    event = CleanupEvent(**body.model_dump())
    db.add(event)
    db.commit()
    db.refresh(event)
    return _enrich(event, db)


@router.post("/cleanup-events/{event_id}/join", status_code=200)
def join_cleanup_event(
    event_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    event = db.query(CleanupEvent).filter(CleanupEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Événement introuvable")
    if event.status == CleanupStatus.completed:
        raise HTTPException(status_code=400, detail="Événement terminé")

    already = db.query(CleanupParticipant).filter(
        CleanupParticipant.event_id == event_id,
        CleanupParticipant.user_id == current_user.id,
    ).first()
    if already:
        raise HTTPException(status_code=400, detail="Déjà inscrit")

    count = db.query(CleanupParticipant).filter(CleanupParticipant.event_id == event_id).count()
    if count >= event.max_participants:
        raise HTTPException(status_code=400, detail="Événement complet")

    db.add(CleanupParticipant(event_id=event_id, user_id=current_user.id))
    db.commit()
    return {"message": "Inscription confirmée", "tokens_reward": event.tokens_reward}


@router.put("/cleanup-events/{event_id}/validate/{user_id}", status_code=200)
def validate_cleanup_participation(
    event_id: str,
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role.value != "autorite":
        raise HTTPException(status_code=403, detail="Réservé aux autorités")

    event = db.query(CleanupEvent).filter(CleanupEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Événement introuvable")

    participant = db.query(CleanupParticipant).filter(
        CleanupParticipant.event_id == event_id,
        CleanupParticipant.user_id == user_id,
    ).first()
    if not participant:
        raise HTTPException(status_code=404, detail="Participant introuvable")
    if participant.validated:
        raise HTTPException(status_code=400, detail="Déjà validé")

    user = db.query(User).filter(User.id == user_id).first()
    tokens = event.tokens_reward

    participant.validated       = True
    participant.tokens_received = tokens
    user.eco_tokens            += tokens

    tx_hash = award_tokens_onchain(
        user.wallet_address or "", tokens, f"cleanup:{event_id}"
    )
    db.add(TokenTransaction(
        user_id=user.id,
        amount=tokens,
        action_type=ActionType.cleanup_participation,
        description=f"Nettoyage validé — {event.title}",
        tx_hash=tx_hash,
    ))
    db.commit()
    return {"message": "Participation validée", "tokens_awarded": tokens}
