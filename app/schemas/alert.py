from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID
from datetime import datetime
from app.models.alert import AlertSeverity
from app.models.user import UserRole


class AlertCreate(BaseModel):
    titre: str
    description: str
    severite: AlertSeverity
    roles_target: List[UserRole]
    zone_name: str
    zone_id: Optional[UUID] = None
    recommandations: Optional[List[str]] = None


class AlertOut(BaseModel):
    id: UUID
    titre: str
    description: str
    severite: AlertSeverity
    roles_target: List[str]
    zone_name: str
    zone_id: Optional[UUID]
    timestamp: datetime
    recommandations: List[str]
    is_active: bool

    model_config = {"from_attributes": True}
