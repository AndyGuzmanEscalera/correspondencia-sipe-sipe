#!/usr/bin/env python3
"""Bootstrap an institutional admin role with master_data permissions.

Usage (inside backend container or with DATABASE_URL configured):

    python scripts/bootstrap_admin_role.py \\
        --username existing_user \\
        --role-code ADMIN \\
        --role-name "Administrador del sistema"

Does NOT create users or print secrets.
"""

from __future__ import annotations

import argparse
import sys
import uuid
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import func, select  # noqa: E402

from app.core.database import SessionLocal  # noqa: E402
from app.modules.identity.permission import Permission  # noqa: E402
from app.modules.identity.role import Role  # noqa: E402
from app.modules.identity.role_permission import RolePermission  # noqa: E402
from app.modules.identity.user import User  # noqa: E402
from app.modules.identity.user_role import UserRole  # noqa: E402

MASTER_DATA_PERMISSIONS = [
    "master_data.organizational_units.read",
    "master_data.organizational_units.manage",
    "master_data.positions.read",
    "master_data.positions.manage",
    "master_data.employees.read",
    "master_data.employees.manage",
    "master_data.users.read",
    "master_data.users.manage",
    "master_data.document_types.read",
    "master_data.document_types.manage",
]


def main() -> int:
    parser = argparse.ArgumentParser(description="Bootstrap admin role permissions")
    parser.add_argument("--username", required=True, help="Existing active username")
    parser.add_argument("--role-code", required=True, help="Institutional role code")
    parser.add_argument("--role-name", required=True, help="Institutional role name")
    args = parser.parse_args()

    db = SessionLocal()
    try:
        user = db.scalar(
            select(User).where(
                User.is_active == True,  # noqa: E712
                func.lower(User.username) == args.username.strip().lower(),
            )
        )
        if user is None:
            print("Usuario no encontrado o inactivo", file=sys.stderr)
            return 1

        role = db.scalar(select(Role).where(Role.code == args.role_code.strip()))
        if role is None:
            role = Role(
                id=uuid.uuid4(),
                code=args.role_code.strip(),
                name=args.role_name.strip(),
                is_active=True,
            )
            db.add(role)
            db.flush()
            print(f"Rol creado: {role.code}")
        else:
            print(f"Rol existente reutilizado: {role.code}")

        permissions = db.scalars(
            select(Permission).where(Permission.code.in_(MASTER_DATA_PERMISSIONS))
        ).all()
        permission_by_code = {perm.code: perm for perm in permissions}
        missing = [code for code in MASTER_DATA_PERMISSIONS if code not in permission_by_code]
        if missing:
            print(f"Permisos faltantes en DB: {', '.join(missing)}", file=sys.stderr)
            return 1

        for perm in permissions:
            exists = db.scalar(
                select(RolePermission).where(
                    RolePermission.role_id == role.id,
                    RolePermission.permission_id == perm.id,
                )
            )
            if exists is None:
                db.add(RolePermission(role_id=role.id, permission_id=perm.id))

        user_role = db.scalar(
            select(UserRole).where(
                UserRole.user_id == user.id,
                UserRole.role_id == role.id,
            )
        )
        if user_role is None:
            db.add(UserRole(user_id=user.id, role_id=role.id, assigned_by=user.id))

        db.commit()
        print(f"Permisos master_data asignados al rol {role.code}")
        print(f"Rol {role.code} asignado al usuario {user.username}")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
