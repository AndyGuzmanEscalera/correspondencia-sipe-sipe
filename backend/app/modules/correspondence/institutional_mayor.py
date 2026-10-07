"""Resolución del alcalde/alcaldesa titular para encadenamiento (PARA / primer destinatario)."""

from __future__ import annotations

import uuid
from dataclasses import dataclass

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position
from app.modules.system.service import apply_mayor_display_name


@dataclass(frozen=True, slots=True)
class InstitutionalMayor:
    user_id: uuid.UUID
    employee_id: uuid.UUID
    unit_id: uuid.UUID
    employee_name: str
    position_name: str
    unit_name: str

    @property
    def para_label(self) -> str:
        return f"{self.unit_name} — {self.employee_name}"


def resolve_institutional_mayor(db: Session) -> InstitutionalMayor | None:
    settings = get_settings()
    codes = settings.institutional_mayor_position_codes_list
    if not codes:
        return None

    rows = db.execute(
        select(
            User.id.label("user_id"),
            Employee.id.label("employee_id"),
            Employee.unit_id.label("unit_id"),
            Employee.first_name,
            Employee.last_name,
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
            Position.code.in_(codes),
        )
        .order_by(User.created_at)
        .limit(2)
    ).mappings().all()

    if not rows:
        return None
    if len(rows) > 1:
        raise HTTPException(status_code=422, detail="Hay más de un titular ejecutivo activo. Revise los funcionarios y cargos institucionales.")
    row = rows[0]

    first_name = (row["first_name"] or "").strip()
    last_name = (row["last_name"] or "").strip()
    employee_name = f"{first_name} {last_name}".strip()
    employee_name = apply_mayor_display_name(db, employee_name)

    return InstitutionalMayor(
        user_id=row["user_id"],
        employee_id=row["employee_id"],
        unit_id=row["unit_id"],
        employee_name=employee_name,
        position_name=(row["position_name"] or "").strip(),
        unit_name=(row["unit_name"] or "").strip(),
    )
