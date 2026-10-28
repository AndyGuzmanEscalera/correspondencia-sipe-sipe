"""Startup regressions; no database or physical device is contacted."""
import os
from pathlib import Path
import subprocess
import sys
import textwrap


def run_child(body):
    backend = os.getenv("RRHH_SHARED_BACKEND", str(Path(__file__).resolve().parents[1]))
    env = dict(os.environ, DATABASE_URL="postgresql+psycopg://unused@127.0.0.1:1/unused",
               JWT_ACCESS_SECRET="startup-test-only-secret-at-least-32-characters",
               APP_ENV="development", BIOMETRIC_IP="127.0.0.1", BIOMETRIC_DEVICE_ID="startup-test",
               BIOMETRIC_PASSWORD="0")
    setup = "import sys\nsys.path[:0] = " + repr([backend] + sys.path) + "\n"
    block_zk = '''
import builtins
original_import = builtins.__import__
def without_zk(name, *args, **kwargs):
    if name == "zk" or name.startswith("zk."):
        raise ModuleNotFoundError("No module named 'zk'", name="zk")
    return original_import(name, *args, **kwargs)
builtins.__import__ = without_zk
'''
    result = subprocess.run([sys.executable, "-c", setup + textwrap.dedent(block_zk) + textwrap.dedent(body)],
                            env=env, capture_output=True, text=True, timeout=30)
    assert result.returncode == 0, result.stderr


def test_missing_pyzk_does_not_break_health_auth_or_preflight():
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
''')


def test_missing_pyzk_gives_controlled_connector_error():
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
''')
