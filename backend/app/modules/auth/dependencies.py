import uuid
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.security import decode_access_token
from app.modules.identity.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    token: Annotated[str | None, Depends(oauth2_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    settings = get_settings()
    if not token:
        raise _unauthorized("Token requerido")

    if not settings.jwt_access_secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="JWT_ACCESS_SECRET no configurado",
        )

    try:
        payload = decode_access_token(token)
    except (ValueError, jwt.exceptions.InvalidTokenError):
        # Generic 401: do not leak internal validation details to the client.
        raise _unauthorized("Token inválido")

    sub = payload.get("sub")
    if not sub:
        raise _unauthorized("Token inválido")

    try:
        user_id = uuid.UUID(sub)
    except ValueError:
        raise _unauthorized("Token inválido")

    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise _unauthorized("Usuario no disponible")

    return user


def require_permission(permission_code: str):
    """Dependency factory: current user must have the given permission code
    via an active role.
    """
    from app.modules.identity.permission import Permission
    from app.modules.identity.role import Role
    from app.modules.identity.role_permission import RolePermission
    from app.modules.identity.user_role import UserRole

    def dependency(
        current_user: Annotated[User, Depends(get_current_user)],
        db: Annotated[Session, Depends(get_db)],
    ) -> User:
        exists = db.execute(
            select(1)
            .select_from(UserRole)
            .join(
                Role,
                and_(Role.id == UserRole.role_id, Role.is_active == True),  # noqa: E712
            )
            .join(RolePermission, RolePermission.role_id == Role.id)
            .join(Permission, Permission.id == RolePermission.permission_id)
            .where(
                UserRole.user_id == current_user.id,
                Permission.code == permission_code,
            )
        ).first()
        if exists is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permiso insuficiente",
            )
        return current_user

    return dependency
