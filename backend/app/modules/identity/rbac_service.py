import uuid

from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user_role import UserRole


class RbacService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def get_user_role_codes(self, user_id: uuid.UUID) -> list[str]:
        rows = self._db.scalars(
            select(Role.code)
            .join(UserRole, UserRole.role_id == Role.id)
            .where(
                UserRole.user_id == user_id,
                Role.is_active == True,  # noqa: E712
            )
            .order_by(Role.code)
        ).all()
        return list(rows)

    def get_user_permission_codes(self, user_id: uuid.UUID) -> list[str]:
        rows = self._db.scalars(
            select(Permission.code)
            .join(RolePermission, RolePermission.permission_id == Permission.id)
            .join(Role, Role.id == RolePermission.role_id)
            .join(UserRole, UserRole.role_id == Role.id)
            .where(
                UserRole.user_id == user_id,
                Role.is_active == True,  # noqa: E712
            )
            .distinct()
            .order_by(Permission.code)
        ).all()
        return list(rows)

    def validate_active_role_ids(self, role_ids: list[uuid.UUID]) -> None:
        from fastapi import HTTPException, status

        if not role_ids:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Debe asignar al menos un rol",
            )
        found = self._db.scalars(
            select(Role.id).where(
                Role.id.in_(role_ids),
                Role.is_active == True,  # noqa: E712
            )
        ).all()
        if len(found) != len(set(role_ids)):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Uno o más roles no existen o están inactivos",
            )
