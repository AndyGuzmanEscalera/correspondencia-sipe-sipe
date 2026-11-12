import os
import sys
from pathlib import Path

# The extension can be tested before installation against the shared app package.
backend = Path(__file__).resolve().parents[1]
shared = os.getenv("RRHH_SHARED_BACKEND")
os.environ.setdefault("JWT_ACCESS_SECRET", "evaluation-tests-only-secret-at-least-32-characters")
os.environ.setdefault("DATABASE_URL", "postgresql+psycopg://unused@127.0.0.1:1/unused")
if shared:
    sys.path.insert(0, shared)
import app.modules.rrhh as rrhh_pkg
overlay = str(backend / "app/modules/rrhh")
if overlay not in rrhh_pkg.__path__:
    rrhh_pkg.__path__.insert(0, overlay)
