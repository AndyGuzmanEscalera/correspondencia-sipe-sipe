from __future__ import annotations

import uuid
from dataclasses import asdict

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.modules.identity.user import User
from app.modules.system.constants import INSTITUTIONAL_MAYOR_DISPLAY_NAME, INSTITUTIONAL_MAYOR_EMPLOYEE_ID
from app.modules.correspondence.institutional_mayor import resolve_employee_authority, resolve_institutional_mayor, list_active_authorities
from app.modules.system.schemas import (
    InstitutionalSettingsResponse,
    UpdateInstitutionalSettingsRequest,
    AuthorityEmployeeResponse,
)
from app.modules.system.system_setting import SystemSetting


class SystemSettingsService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def get_institutional_settings(self) -> InstitutionalSettingsResponse:
        row = self._db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
        employee_id = None
        mayor = None
        error = None
        try:
            employee_id = uuid.UUID(row.value) if row and row.value else None
            resolved = resolve_institutional_mayor(self._db)
            if resolved:
                mayor = AuthorityEmployeeResponse(**asdict(resolved))
        except HTTPException as exc:
            error = exc.detail
        except ValueError:
            error = "La referencia al Alcalde/Máxima Autoridad Ejecutiva no es válida. Seleccione un funcionario en Configuración."
        return InstitutionalSettingsResponse(
            mayor_display_name=self.get_mayor_display_name(),
            mayor_employee_id=employee_id,
            mayor=mayor,
            mayor_validation_error=error,
        )

    def list_authority_employees(self) -> list[AuthorityEmployeeResponse]:
        result = []
        for mayor in list_active_authorities(self._db):
            result.append(AuthorityEmployeeResponse(**asdict(mayor)))
        return sorted(result, key=lambda item: item.employee_name.casefold())

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
        if "mayor_employee_id" in body.model_fields_set:
            if body.mayor_employee_id is not None:
                resolve_employee_authority(self._db, body.mayor_employee_id)
            selection = self._db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
            if body.mayor_employee_id is None:
                if selection is not None:
                    self._db.delete(selection)
            elif selection is None:
                self._db.add(SystemSetting(key=INSTITUTIONAL_MAYOR_EMPLOYEE_ID,
                    value=str(body.mayor_employee_id), updated_by_user_id=user.id))
            else:
                selection.value = str(body.mayor_employee_id)
                selection.updated_by_user_id = user.id
        if "mayor_display_name" not in body.model_fields_set:
            self._db.commit()
            return self.get_institutional_settings()
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
