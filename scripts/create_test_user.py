"""Quick helper: create a test user via Python so we can verify the auth
flow against the real backend. Run it inside the backend container:

  docker cp scripts/create_test_user.py sipe_correspondencia_backend:/tmp/create_test_user.py
  docker exec -it -w /app sipe_correspondencia_backend \
      python /tmp/create_test_user.py --username admin

The second command prompts for the password without echoing it.
"""
from __future__ import annotations

import argparse
import getpass
import sys
import uuid
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
# When copied into the backend container, the application is mounted at /app.
# When run from the Windows project root, it lives under ./backend.
BACKEND_ROOT = (
    Path('/app')
    if Path('/app/app').is_dir()
    else PROJECT_ROOT / 'backend'
)
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.database import SessionLocal  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.modules import organization  # noqa: F401, E402  -- registers FK targets
from app.modules.identity.user import User  # noqa: E402


def create_user(username: str, password: str, email: str | None = None) -> str:
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
            return f"Username already exists: {username}"
        db.add(user)
        db.commit()
        db.refresh(user)
        return str(user.id)


def main() -> None:
    print("*** scripts.create_test_user — DEVELOPMENT ONLY ***", file=sys.stderr)
    parser = argparse.ArgumentParser(description="Create a test user (development only).")
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", required=False, default=None)
    parser.add_argument("--email", required=False, default=None)
    args = parser.parse_args()

    if args.password is None:
        pw = getpass.getpass("Password: ")
        pw2 = getpass.getpass("Confirm password: ")
        if pw != pw2:
            raise SystemExit("Passwords do not match.")
        args.password = pw

    user_id = create_user(args.username, args.password, args.email)
    print(f"OK user_id={user_id} username={args.username}")


if __name__ == "__main__":
    main()
