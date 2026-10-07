from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from app.modules.identity.user import User
from app.modules.system.constants import INSTITUTIONAL_MAYOR_DISPLAY_NAME
from app.modules.system.schemas import (
    InstitutionalSettingsResponse,
    UpdateInstitutionalSettingsRequest,
)
from app.modules.system.system_setting import SystemSetting


class SystemSettingsService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def get_institutional_settings(self) -> InstitutionalSettingsResponse:
        return InstitutionalSettingsResponse(
            mayor_display_name=self.get_mayor_display_name(),
        )

    def get_mayor_display_name(self) -> str | None:
        row = self._db.get(SystemSetting, INSTITUTIONAL_MAYOR_DISPLAY_NAME)
        if row is None or row.value is None:
            return None
        trimmed = row.value.strip()
        return trimmed or None

    def update_institutional_settings(
        self,
        user: User,
        body: UpdateInstitutionalSettingsRequest,
    ) -> InstitutionalSettingsResponse:
        normalized = self._normalize_mayor_name(body.mayor_display_name)
        row = self._db.get(SystemSetting, INSTITUTIONAL_MAYOR_DISPLAY_NAME)
        if normalized is None:
            if row is not None:
                self._db.delete(row)
        elif row is None:
            self._db.add(
                SystemSetting(
                    key=INSTITUTIONAL_MAYOR_DISPLAY_NAME,
                    value=normalized,
                    updated_by_user_id=user.id,
                )
            )
        else:
            row.value = normalized
            row.updated_by_user_id = user.id
        self._db.commit()
        return self.get_institutional_settings()

    @staticmethod
    def _normalize_mayor_name(value: str | None) -> str | None:
        if value is None:
            return None
        trimmed = value.strip()
        return trimmed or None


def apply_mayor_display_name(
    db: Session,
    employee_name: str,
) -> str:
    """Nombre configurado en sistema, o el del funcionario titular."""
    service = SystemSettingsService(db)
    override = service.get_mayor_display_name()
    if override:
        return override
    return employee_name
