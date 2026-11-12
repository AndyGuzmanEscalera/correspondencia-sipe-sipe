"""Startup regressions; no database or physical device is contacted."""
import os
from pathlib import Path
import subprocess
import sys
import textwrap


OVERLAY = Path(__file__).resolve().parents[1]


def run_child(body, *, block_zk=False, block_httpx_for_client=False, env_extra=None):
    shared = os.getenv("RRHH_SHARED_BACKEND", str(OVERLAY))
    env = dict(os.environ, DATABASE_URL="postgresql+psycopg://unused@127.0.0.1:1/unused",
               JWT_ACCESS_SECRET="startup-test-only-secret-at-least-32-characters",
               APP_ENV="development")
    for key in ("BIOMETRIC_IP", "BIOMETRIC_PASSWORD", "BIOMETRIC_PORT", "BIOMETRIC_TRANSPORT",
                "BIOMETRIC_API_URL", "BIOMETRIC_API_TOKEN", "BIOMETRIC_DEVICE_ID"):
        env.pop(key, None)
    if env_extra:
        env.update(env_extra)
    setup = textwrap.dedent(f'''
import sys, os, tempfile
from pathlib import Path
sys.path[:0] = {repr([shared] + sys.path)}
# Isolate from a developer backend/.env that may contain real BIOMETRIC_API_* values.
os.chdir(tempfile.mkdtemp(prefix="rrhh-startup-"))
import app.modules.rrhh as rrhh_pkg
overlay = {repr(str(OVERLAY / "app/modules/rrhh"))}
if overlay not in rrhh_pkg.__path__:
    rrhh_pkg.__path__.insert(0, overlay)
''')
    block = ""
    if block_zk:
        block += textwrap.dedent('''
import builtins
original_import = builtins.__import__
def without_zk(name, *args, **kwargs):
    if name == "zk" or name.startswith("zk."):
        raise ModuleNotFoundError("No module named 'zk'", name="zk")
    return original_import(name, *args, **kwargs)
builtins.__import__ = without_zk
''')
    if block_httpx_for_client:
        # Keep httpx available for Starlette TestClient; fail only the biometric client import.
        block += textwrap.dedent('''
import sys
import types
fake = types.ModuleType("app.modules.rrhh.api_client.client")
def _missing(*_a, **_k):
    raise ImportError("No module named 'httpx'")
class BiometricApiClient:
    def __init__(self, *args, **kwargs):
        raise ImportError("No module named 'httpx'")
fake.BiometricApiClient = BiometricApiClient
sys.modules["app.modules.rrhh.api_client.client"] = fake
''')
    result = subprocess.run([sys.executable, "-c", setup + block + textwrap.dedent(body)],
                            env=env, capture_output=True, text=True, timeout=30)
    assert result.returncode == 0, result.stderr + result.stdout


def test_missing_pyzk_does_not_break_health_auth_or_preflight():
    # Reader/pyzk remains optional at boot; auth and health must not import it.
    run_child('''
from app.main import app
from fastapi.testclient import TestClient
with TestClient(app) as client:
    assert client.get("/health").status_code == 200
    headers = {"Origin": "http://localhost:5000", "Access-Control-Request-Method": "POST",
               "Access-Control-Request-Headers": "content-type"}
    result = client.options("/auth/refresh", headers=headers)
    assert result.status_code == 200
    assert result.headers["access-control-allow-origin"] == "http://localhost:5000"
    assert result.headers["access-control-allow-credentials"] == "true"
    assert client.post("/auth/refresh").status_code == 401
''', block_zk=True)


def test_missing_api_configuration_is_controlled():
    run_child('''
from app.modules.rrhh.biometric_service import BiometricService
from fastapi import HTTPException
try:
    BiometricService()
except HTTPException as exc:
    assert exc.status_code == 503
    assert exc.detail["code"] == "biometric_invalid_configuration"
else:
    raise AssertionError("Expected a controlled configuration error")
''')


def test_missing_httpx_client_with_valid_config_gives_controlled_connector_error():
    run_child('''
from app.modules.rrhh.biometric_service import BiometricService
from fastapi import HTTPException
try:
    BiometricService()
except HTTPException as exc:
    assert exc.status_code == 503
    assert exc.detail["code"] == "biometric_dependency_missing"
else:
    raise AssertionError("Expected a controlled connector error")
''', block_httpx_for_client=True, env_extra={
        "BIOMETRIC_API_URL": "https://biometric.example.test",
        "BIOMETRIC_API_TOKEN": "startup-test-token",
        "BIOMETRIC_DEVICE_ID": "startup-test",
    })
