from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models.alert import Alert
from app.schemas.alert import AlertCreate, AlertOut
from app.services.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/api/alerts", tags=["alerts"])


@router.get("/", response_model=List[AlertOut])
def get_alerts(
    role: Optional[str] = Query(None, description="Filtrer par rôle utilisateur"),
    severite: Optional[str] = Query(None),
    active_only: bool = Query(True),
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(Alert)
    if active_only:
        q = q.filter(Alert.is_active == True)

    target_role = role or current_user.role.value
    # Filter by role: alert targets the user's role
    alerts = q.order_by(Alert.timestamp.desc()).limit(limit * 3).all()
    filtered = [a for a in alerts if target_role in (a.roles_target or [])]

    if severite:
        filtered = [a for a in filtered if a.severite.value == severite]

    return filtered[:limit]


@router.get("/{alert_id}", response_model=AlertOut)
def get_alert(alert_id: str, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Alerte introuvable")
    return alert


@router.post("/", response_model=AlertOut, status_code=201)
def create_alert(
    body: AlertCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    alert = Alert(
        titre=body.titre,
        description=body.description,
        severite=body.severite,
        roles_target=[r.value for r in body.roles_target],
        zone_name=body.zone_name,
        zone_id=body.zone_id,
        recommandations=body.recommandations or [],
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    return alert
