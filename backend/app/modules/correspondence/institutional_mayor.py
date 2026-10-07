"""Resolución del alcalde/alcaldesa titular para encadenamiento (PARA / primer destinatario)."""

from __future__ import annotations

import uuid
from dataclasses import dataclass

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position
from app.modules.system.constants import INSTITUTIONAL_MAYOR_EMPLOYEE_ID
from app.modules.system.system_setting import SystemSetting


@dataclass(frozen=True, slots=True)
class InstitutionalMayor:
    user_id: uuid.UUID
    employee_id: uuid.UUID
    unit_id: uuid.UUID
    employee_name: str
    position_name: str
    unit_name: str
    document_number: str | None = None

    @property
    def para_label(self) -> str:
        return f"{self.unit_name} — {self.employee_name} ({self.position_name})"


def resolve_institutional_mayor(db: Session) -> InstitutionalMayor | None:
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    if setting is None or not setting.value:
        return None
    try:
        employee_id = uuid.UUID(setting.value)
    except ValueError:
        raise HTTPException(status_code=422, detail="La configuración del Alcalde/Máxima Autoridad Ejecutiva no es válida. Seleccione un funcionario válido en Configuración.")
    return resolve_employee_authority(db, employee_id)


def resolve_employee_authority(db: Session, employee_id: uuid.UUID) -> InstitutionalMayor:
    """EDIE usa to_user_id: requiere funcionario, cargo, unidad y cuenta activos."""
    rows = db.execute(_active_authority_query().where(Employee.id == employee_id).limit(2)).mappings().all()
    if not rows:
        raise HTTPException(status_code=422, detail="El funcionario configurado como Alcalde/Máxima Autoridad Ejecutiva debe existir y tener funcionario, cargo, unidad y cuenta de usuario activos. Revise Configuración.")
    # users.employee_id es único en la BD; mantener defensa para datos inválidos.
    if len(rows) > 1:
        raise HTTPException(status_code=422, detail="El funcionario tiene más de una cuenta activa. Revise sus cuentas antes de configurar la autoridad institucional.")
    return _authority_from_row(rows[0])


def list_active_authorities(db: Session) -> list[InstitutionalMayor]:
    return [_authority_from_row(row) for row in db.execute(_active_authority_query()).mappings()]


def _active_authority_query():
    return (select(
            User.id.label("user_id"),
            Employee.id.label("employee_id"),
            Employee.unit_id.label("unit_id"),
            Employee.first_name,
            Employee.last_name,
            Employee.document_number,
            Position.name.label("position_name"),
            OrganizationalUnit.name.label("unit_name"),
        )
        .join(Employee, Employee.id == User.employee_id)
        .join(Position, Position.id == Employee.position_id)
        .join(OrganizationalUnit, OrganizationalUnit.id == Employee.unit_id)
        .where(
            User.is_active.is_(True),
            Employee.is_active.is_(True),
            Position.is_active.is_(True),
            OrganizationalUnit.is_active.is_(True),
        )
        .order_by(User.created_at)
    )


def _authority_from_row(row) -> InstitutionalMayor:
    first_name = (row["first_name"] or "").strip()
    last_name = (row["last_name"] or "").strip()
    employee_name = f"{first_name} {last_name}".strip()

    return InstitutionalMayor(
        user_id=row["user_id"],
        employee_id=row["employee_id"],
        unit_id=row["unit_id"],
        employee_name=employee_name,
        position_name=(row["position_name"] or "").strip(),
        unit_name=(row["unit_name"] or "").strip(),
        document_number=row["document_number"],
    )
