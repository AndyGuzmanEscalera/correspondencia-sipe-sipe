"""Controlled migration. Dry-run is the default and opens a read-only transaction."""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from sqlalchemy import text
from app.core.database import SessionLocal
from app.modules.identity.role_transition import (
    plan_role_transition,
    plan_sha256,
    apply_role_transition,
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--apply", action="store_true")
    parser.add_argument(
        "--include-admin",
        action="append",
        default=[],
        metavar="USERNAME",
        help="Convertir este ADMIN a OPERADOR conservando grants; nunca a SUPERADMIN",
    )
    parser.add_argument(
        "--plan-sha256", help="Huella del plan revisado, obligatoria al aplicar"
    )
    args = parser.parse_args()
    if args.apply and not args.plan_sha256:
        parser.error("--apply requiere --plan-sha256 obtenido de un --dry-run revisado")
    with SessionLocal() as db:
        try:
            if args.apply:
                result = apply_role_transition(
                    db,
                    expected_sha256=args.plan_sha256,
                    approved_admins=args.include_admin,
                )
                db.commit()
            else:
                db.execute(text("SET TRANSACTION READ ONLY"))
                plan = plan_role_transition(db, approved_admins=args.include_admin)
                result = {
                    "dry_run": True,
                    "plan_sha256": plan_sha256(plan),
                    "users": plan,
                }
                db.rollback()
            print(json.dumps(result, ensure_ascii=False, indent=2))
        except Exception as error:
            db.rollback()
            print(str(error), file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
