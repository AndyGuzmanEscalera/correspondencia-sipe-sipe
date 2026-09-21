#!/usr/bin/env python
"""
*** DEVELOPMENT-ONLY helper ***

Creates a single user for manual testing.

This script is intentionally NOT a production seed.
It must NOT be invoked automatically by any deploy / migrate / startup flow.

Security notes:
- Reads the password from stdin via getpass (never echoed, never logged).
- If --password is provided on the command line, the value WILL appear in the
  shell history; in that case the script still does not echo it but warns.
- Never print the password; never include it in logs.
- Connection settings come from .env (gitignored) via app.core.config.

Usage:
    python -m scripts.create_test_user --username jperez
    python -m scripts.create_test_user --username jperez --email jperez@sipe.gob.bo

When --password is omitted, the script prompts securely via getpass.
"""

from __future__ import annotations

import argparse
import getpass
import sys
import uuid
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent.parent / "backend"
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.database import SessionLocal  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.modules.identity.user import User  # noqa: E402
from app.modules import organization  # noqa: F401, E402  -- registers Employee for FK resolution


def _read_password(args: argparse.Namespace) -> str:
    if args.password is not None:
        # Warn: command-line passwords leak into shell history.
        print(
            "WARNING: passing --password on the command line is insecure "
            "(shell history). Prefer omitting it to be prompted via getpass.",
            file=sys.stderr,
        )
        return args.password
    pw1 = getpass.getpass("Password: ")
    pw2 = getpass.getpass("Confirm password: ")
    if pw1 != pw2:
        raise SystemExit("Passwords do not match.")
    if not pw1:
        raise SystemExit("Password must not be empty.")
    return pw1


def create_user(username: str, password: str, email: str | None) -> str:
    password_hash = hash_password(password)
    user = User(
        id=uuid.uuid4(),
        username=username,
        email=email,
        password_hash=password_hash,
        is_active=True,
    )
    with SessionLocal() as db:
        existing = db.query(User).filter(User.username == username).first()
        if existing is not None:
            raise SystemExit(f"Username already exists: {username}")
        db.add(user)
        db.commit()
        db.refresh(user)
        return str(user.id)


def main() -> None:
    print("*** scripts.create_test_user — DEVELOPMENT ONLY ***", file=sys.stderr)
    parser = argparse.ArgumentParser(description="Create a test user (development only).")
    parser.add_argument("--username", required=True)
    parser.add_argument(
        "--password",
        required=False,
        default=None,
        help="If omitted, you will be prompted securely via getpass.",
    )
    parser.add_argument("--email", required=False, default=None)
    args = parser.parse_args()

    password = _read_password(args)
    user_id = create_user(args.username, password, args.email)
    # Only the user_id is printed; never the password.
    print(f"OK user_id={user_id} username={args.username}")


if __name__ == "__main__":
    main()
