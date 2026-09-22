import uuid

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.common.audit import apply_audit
from app.common.db_commit import commit_or_conflict, conflict, flush_or_conflict
from app.core.security import hash_password
from app.common.schemas import PaginatedResponse, paginate
from app.modules.identity.admin_schemas import (
    CreateUserRequest,
    UpdateUserRequest,
    UserAdminResponse,
)
from app.modules.identity.rbac_service import RbacService
from app.modules.identity.role import Role
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee as OrgEmployee
from app.modules.organization.organizational_unit import OrganizationalUnit


class UserAdminService:
    def __init__(self, db: Session) -> None:
        self._db = db
        self._rbac = RbacService(db)

    def list_users(
        self,
        *,
        page: int,
        page_size: int,
        search: str | None,
        is_active: bool | None,
        unit_id: uuid.UUID | None,
    ) -> PaginatedResponse[UserAdminResponse]:
        query = select(User)
        if is_active is not None:
            query = query.where(User.is_active == is_active)
        if unit_id:
            query = query.join(OrgEmployee, User.employee_id == OrgEmployee.id).where(
                OrgEmployee.unit_id == unit_id
            )
        if search:
            term = f"%{search.strip()}%"
            query = query.where(
                User.username.ilike(term) | User.email.ilike(term)
            )
        total = self._db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0
        offset = (page - 1) * page_size
        rows = self._db.scalars(
            query.order_by(User.username).offset(offset).limit(page_size)
        ).all()
        items = [self._to_response(row) for row in rows]
        return paginate(items=items, total=total, page=page, page_size=page_size)

    def get_user(self, user_id: uuid.UUID) -> UserAdminResponse:
        row = self._get_or_404(user_id)
        return self._to_response(row)

    def create_user(
        self,
        actor: User,
        body: CreateUserRequest,
    ) -> UserAdminResponse:
        username = body.username.strip()
        email = body.email.strip() if body.email else None
        self._ensure_username_unique(username)
        if email:
            self._ensure_email_unique(email)
        employee = self._get_active_employee(body.employee_id)
        self._ensure_employee_available(employee.id)
        self._rbac.validate_active_role_ids(body.role_ids)

        row = User(
            username=username,
            email=email,
            employee_id=employee.id,
            password_hash=hash_password(body.initial_password),
            is_active=True,
        )
        apply_audit(row, actor.id, is_create=True)
        self._db.add(row)
        flush_or_conflict(
            self._db,
            values={"username": username, "email": email or ""},
        )
        self._replace_roles(row.id, body.role_ids, actor.id)
        commit_or_conflict(
            self._db,
            values={"username": username, "email": email or ""},
        )
        self._db.refresh(row)
        return self._to_response(row)

    def update_user(
        self,
        actor: User,
        user_id: uuid.UUID,
        body: UpdateUserRequest,
    ) -> UserAdminResponse:
        row = self._get_or_404(user_id)
        username = body.username.strip()
        email = body.email.strip() if body.email else None
        self._ensure_username_unique(username, exclude_id=user_id)
        if email:
            self._ensure_email_unique(email, exclude_id=user_id)
        employee = self._get_active_employee(body.employee_id)
        self._ensure_employee_available(employee.id, exclude_user_id=user_id)
        self._rbac.validate_active_role_ids(body.role_ids)

        row.username = username
        row.email = email
        row.employee_id = employee.id
        apply_audit(row, actor.id)
        self._replace_roles(row.id, body.role_ids, actor.id)
        commit_or_conflict(
            self._db,
            values={"username": username, "email": email or ""},
        )
        self._db.refresh(row)
        return self._to_response(row)

    def set_active(
        self,
        actor: User,
        user_id: uuid.UUID,
        *,
        is_active: bool,
    ) -> UserAdminResponse:
        row = self._get_or_404(user_id)
        row.is_active = is_active
        apply_audit(row, actor.id)
        self._db.commit()
        self._db.refresh(row)
        return self._to_response(row)

    def _replace_roles(
        self,
        user_id: uuid.UUID,
        role_ids: list[uuid.UUID],
        assigned_by: uuid.UUID,
    ) -> None:
        existing = self._db.scalars(
            select(UserRole).where(UserRole.user_id == user_id)
        ).all()
        for item in existing:
            self._db.delete(item)
        for role_id in role_ids:
            self._db.add(
                UserRole(
                    user_id=user_id,
                    role_id=role_id,
                    assigned_by=assigned_by,
                )
            )

    def _get_active_employee(self, employee_id: uuid.UUID) -> OrgEmployee:
        employee = self._db.get(OrgEmployee, employee_id)
        if employee is None or not employee.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Funcionario no encontrado o inactivo",
            )
        return employee

    def _ensure_employee_available(
        self,
        employee_id: uuid.UUID,
        *,
        exclude_user_id: uuid.UUID | None = None,
    ) -> None:
        query = select(User.id).where(User.employee_id == employee_id)
        if exclude_user_id:
            query = query.where(User.id != exclude_user_id)
        if self._db.scalar(query):
            raise conflict("El funcionario ya tiene una cuenta de usuario vinculada.")

    def _ensure_username_unique(
        self,
        username: str,
        *,
        exclude_id: uuid.UUID | None = None,
    ) -> None:
        query = select(User.id).where(func.lower(User.username) == username.lower())
        if exclude_id:
            query = query.where(User.id != exclude_id)
        if self._db.scalar(query):
            raise conflict(f"Ya existe un usuario con el nombre {username}.")

    def _ensure_email_unique(
        self,
        email: str,
        *,
        exclude_id: uuid.UUID | None = None,
    ) -> None:
        query = select(User.id).where(func.lower(User.email) == email.lower())
        if exclude_id:
            query = query.where(User.id != exclude_id)
        if self._db.scalar(query):
            raise conflict(f"Ya existe un usuario con el correo {email}.")

    def _get_or_404(self, user_id: uuid.UUID) -> User:
        row = self._db.get(User, user_id)
        if row is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado",
            )
        return row

    def _to_response(self, row: User) -> UserAdminResponse:
        employee_name = None
        unit_name = None
        if row.employee_id:
            employee = self._db.get(OrgEmployee, row.employee_id)
            if employee:
                employee_name = f"{employee.first_name} {employee.last_name}".strip()
                if employee.unit_id:
                    unit = self._db.get(OrganizationalUnit, employee.unit_id)
                    unit_name = unit.name if unit else None
        role_codes = self._rbac.get_user_role_codes(row.id)
        return UserAdminResponse(
            id=row.id,
            username=row.username,
            email=row.email,
            employee_id=row.employee_id,
            employee_name=employee_name,
            unit_name=unit_name,
            is_active=row.is_active,
            role_codes=role_codes,
            created_at=row.created_at,
            updated_at=row.updated_at,
            created_by_user_id=row.created_by_user_id,
            updated_by_user_id=row.updated_by_user_id,
        )
