"""Lightweight suite for the HTTPS client. No database and no real network."""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OVERLAY_RRHH = ROOT / "app/modules/rrhh"
shared = os.environ.get("RRHH_SHARED_BACKEND")
if shared:
    sys.path.insert(0, shared)

# The portable runtime may already point at the shared backend. Prefer the
# local overlay package contents (api_client, updated service) without copying.
import app.modules.rrhh as rrhh_pkg
overlay = str(OVERLAY_RRHH)
if overlay not in rrhh_pkg.__path__:
    rrhh_pkg.__path__.insert(0, overlay)

os.environ.setdefault("BIOMETRIC_API_URL", "https://biometric.example.test")
os.environ.setdefault("BIOMETRIC_API_TOKEN", "test-token-not-for-production")
os.environ.setdefault("BIOMETRIC_DEVICE_ID", "alcaldia-central")
