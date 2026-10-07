from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.auth.dependencies import require_permission
from app.modules.identity.user import User
from app.modules.system.schemas import (
    InstitutionalSettingsResponse,
    UpdateInstitutionalSettingsRequest,
)
from app.modules.system.service import SystemSettingsService

router = APIRouter(
    prefix="/admin/system-settings",
    tags=["admin-system-settings"],
)


def _service(db: Annotated[Session, Depends(get_db)]) -> SystemSettingsService:
    return SystemSettingsService(db)


@router.get(
    "/institutional",
    response_model=InstitutionalSettingsResponse,
)
def get_institutional_settings(
    service: Annotated[SystemSettingsService, Depends(_service)],
    _user: Annotated[User, Depends(require_permission("system.settings.read"))],
) -> InstitutionalSettingsResponse:
    return service.get_institutional_settings()


@router.put(
    "/institutional",
    response_model=InstitutionalSettingsResponse,
)
def update_institutional_settings(
    body: UpdateInstitutionalSettingsRequest,
    service: Annotated[SystemSettingsService, Depends(_service)],
    current_user: Annotated[User, Depends(require_permission("system.settings.manage"))],
) -> InstitutionalSettingsResponse:
    return service.update_institutional_settings(current_user, body)
