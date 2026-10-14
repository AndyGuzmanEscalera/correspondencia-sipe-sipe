import uuid
from sqlalchemy import select, func, update, or_
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.modules.notifications.notification import Notification
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.organization.organizational_unit import OrganizationalUnit


def notify_movement(db, correspondence, movement):
    """Same transaction as the movement; delivery never grants document visibility."""
    if movement.movement_type not in {"DERIVED", "REOPENED"}:
        return
    reopened = movement.movement_type == "REOPENED"
    unit_id = movement.from_unit_id if reopened else movement.to_unit_id
    direct_user = movement.from_user_id if reopened else movement.to_user_id
    candidates = db.scalars(select(User.id).join(Employee, Employee.id == User.employee_id)
        .join(Position, Position.id == Employee.position_id)
        .join(OrganizationalUnit, OrganizationalUnit.id == Employee.unit_id)
        .where(User.is_active.is_(True), Employee.is_active.is_(True), Position.is_active.is_(True),
            OrganizationalUnit.is_active.is_(True), Employee.unit_id == unit_id,
            or_(User.id == direct_user, Position.can_view_unit_correspondence.is_(True))))
    recipients = set(candidates) - {movement.created_by_user_id}
    kind = "REOPENED" if reopened else ("ASSIGNED" if movement.sequence_number == 2 else "DERIVED")
    label = "Correspondencia reabierta" if reopened else "Correspondencia recibida"
    for user_id in recipients:
        db.execute(insert(Notification).values(id=uuid.uuid4(), user_id=user_id,
            correspondence_id=correspondence.id, movement_id=movement.id, type=kind,
            title=f"{label}: {correspondence.route_number}", message=correspondence.subject,
            is_read=False).on_conflict_do_nothing(constraint="uq_notifications_movement_user"))


class NotificationService:
    def __init__(self, db: Session):
        self.db = db

    def unread_count(self, user):
        return self.db.scalar(select(func.count()).select_from(Notification)
            .where(Notification.user_id == user.id, Notification.is_read.is_(False))) or 0

    def list(self, user, page, page_size):
        query = select(Notification).where(Notification.user_id == user.id)
        total = self.db.scalar(select(func.count()).select_from(query.subquery())) or 0
        rows = self.db.scalars(query.order_by(Notification.created_at.desc(), Notification.id.desc())
            .offset((page - 1) * page_size).limit(page_size))
        return {"items": [{"id": row.id, "correspondence_id": row.correspondence_id,
            "type": row.type, "title": row.title, "message": row.message,
            "is_read": row.is_read, "created_at": row.created_at, "read_at": row.read_at} for row in rows],
            "total": total, "page": page, "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size, "unread": self.unread_count(user)}

    def read(self, user, notification_id):
        row = self.db.scalar(select(Notification).where(Notification.id == notification_id,
            Notification.user_id == user.id).with_for_update())
        if row is None:
            raise HTTPException(status_code=404, detail="Notificación no encontrada")
        if not row.is_read:
            row.is_read = True
            row.read_at = func.now()
        self.db.commit()
        return {"unread": self.unread_count(user)}

    def read_all(self, user):
        self.db.execute(update(Notification).where(Notification.user_id == user.id,
            Notification.is_read.is_(False)).values(is_read=True, read_at=func.now()))
        self.db.commit()
        return {"unread": self.unread_count(user)}
