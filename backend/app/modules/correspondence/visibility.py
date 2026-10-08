"""Alcance operativo actual y seguimiento personal; no usa roles."""
from dataclasses import dataclass
import uuid

from fastapi import HTTPException
from sqlalchemy import exists, false, or_, select
from sqlalchemy.orm import Session

from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.constants import MOVEMENT_DERIVED
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.organization.organizational_unit import OrganizationalUnit


@dataclass(frozen=True)
class VisibilityContext:
    user_id: uuid.UUID
    unit_id: uuid.UUID
    can_view_unit_correspondence: bool


def resolve_visibility_context(db: Session, user: User) -> VisibilityContext | None:
    row = db.execute(select(Employee.unit_id, Position.can_view_unit_correspondence)
        .join(Position, Position.id == Employee.position_id)
        .join(OrganizationalUnit, OrganizationalUnit.id == Employee.unit_id)
        .where(Employee.id == user.employee_id, Employee.is_active.is_(True),
               Position.is_active.is_(True), OrganizationalUnit.is_active.is_(True))) .first()
    if not user.is_active or row is None:
        return None
    return VisibilityContext(user.id, row.unit_id, row.can_view_unit_correspondence)


def operational_visibility_filter(db: Session, user: User):
    context = resolve_visibility_context(db, user)
    if context is None:
        return false()
    unit = Correspondence.current_unit_id == context.unit_id
    if context.can_view_unit_correspondence:
        return unit
    return unit & (Correspondence.current_user_id == context.user_id)


def tracking_visibility_filter(user_id: uuid.UUID):
    """Semántica de Sent: creado o derivado personalmente, sin alcance por unidad."""
    derived_by_me = exists(select(1).where(
        CorrespondenceMovement.correspondence_id == Correspondence.id,
        CorrespondenceMovement.movement_type == MOVEMENT_DERIVED,
        CorrespondenceMovement.created_by_user_id == user_id,
    ))
    return or_(Correspondence.created_by_user_id == user_id, derived_by_me)


def read_visibility_filter(db: Session, user: User):
    if not user.is_active:
        return false()
    return or_(operational_visibility_filter(db, user), tracking_visibility_filter(user.id))


def require_visible_correspondence(db: Session, user: User, correspondence_id: uuid.UUID):
    correspondence = db.scalar(select(Correspondence).where(
        Correspondence.id == correspondence_id, Correspondence.is_active.is_(True),
        read_visibility_filter(db, user),
    ))
    if correspondence is None:
        # Misma respuesta para inexistente y fuera de alcance: no revela IDs.
        raise HTTPException(status_code=404, detail="Correspondencia no encontrada")
    return correspondence
