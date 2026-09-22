import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.common.schemas import ActiveToggleRequest, PaginatedResponse
from app.core.database import get_db
from app.modules.auth.dependencies import require_permission
from app.modules.identity.admin_schemas import (
    CreateUserRequest,
    UpdateUserRequest,
    UserAdminResponse,
)
from app.modules.identity.role import Role
from app.modules.identity.user import User
from app.modules.identity.user_admin_service import UserAdminService

router = APIRouter(prefix="/admin", tags=["admin-users"])


class RoleOptionResponse(BaseModel):
    id: uuid.UUID
    code: str
    name: str


def _users(db: Annotated[Session, Depends(get_db)]) -> UserAdminService:
    return UserAdminService(db)


@router.get("/roles", response_model=list[RoleOptionResponse])
def list_roles_for_admin(
    db: Annotated[Session, Depends(get_db)],
    _user: Annotated[User, Depends(require_permission("master_data.users.read"))],
) -> list[RoleOptionResponse]:
    rows = db.scalars(
        select(Role)
        .where(Role.is_active == True)  # noqa: E712
        .order_by(Role.name)
    ).all()
    return [
        RoleOptionResponse(id=row.id, code=row.code, name=row.name) for row in rows
    ]


@router.get("/users", response_model=PaginatedResponse[UserAdminResponse])
def list_users_admin(
    service: Annotated[UserAdminService, Depends(_users)],
    _user: Annotated[User, Depends(require_permission("master_data.users.read"))],
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str | None = None,
    is_active: bool | None = None,
    unit_id: uuid.UUID | None = None,
) -> PaginatedResponse[UserAdminResponse]:
    return service.list_users(
        page=page,
        page_size=page_size,
        search=search,
        is_active=is_active,
        unit_id=unit_id,
    )


@router.get("/users/{user_id}", response_model=UserAdminResponse)
def get_user_admin(
    user_id: uuid.UUID,
    service: Annotated[UserAdminService, Depends(_users)],
    _user: Annotated[User, Depends(require_permission("master_data.users.read"))],
) -> UserAdminResponse:
    return service.get_user(user_id)


@router.post(
    "/users",
    response_model=UserAdminResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_user_admin(
    body: CreateUserRequest,
    service: Annotated[UserAdminService, Depends(_users)],
    current_user: Annotated[User, Depends(require_permission("master_data.users.manage"))],
) -> UserAdminResponse:
    return service.create_user(current_user, body)


@router.put("/users/{user_id}", response_model=UserAdminResponse)
def update_user_admin(
    user_id: uuid.UUID,
    body: UpdateUserRequest,
    service: Annotated[UserAdminService, Depends(_users)],
    current_user: Annotated[User, Depends(require_permission("master_data.users.manage"))],
) -> UserAdminResponse:
    return service.update_user(current_user, user_id, body)


@router.patch("/users/{user_id}/active", response_model=UserAdminResponse)
def toggle_user_admin(
    user_id: uuid.UUID,
    body: ActiveToggleRequest,
    service: Annotated[UserAdminService, Depends(_users)],
    current_user: Annotated[User, Depends(require_permission("master_data.users.manage"))],
) -> UserAdminResponse:
    return service.set_active(current_user, user_id, is_active=body.is_active)
