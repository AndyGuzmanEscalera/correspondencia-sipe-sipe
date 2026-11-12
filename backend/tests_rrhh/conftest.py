"""Isolated integration suite; never inherits Correspondencia's data-seeding fixtures."""
import os
import sys
from pathlib import Path

# Require a specifically named disposable database; never use backend/.env implicitly.
url = os.environ.get("RRHH_TEST_DATABASE_URL", "")
if not url or "rrhh_biometric_test" not in url.rsplit("/", 1)[-1]:
    raise RuntimeError("Set RRHH_TEST_DATABASE_URL to a disposable rrhh_biometric_test database")
os.environ["DATABASE_URL"] = url
os.environ["JWT_ACCESS_SECRET"] = "rrhh-test-only-secret-32-characters-minimum"
os.environ["BIOMETRIC_API_URL"] = "https://biometric.example.test"
os.environ["BIOMETRIC_API_TOKEN"] = "test-token-not-for-production"
os.environ["BIOMETRIC_API_TIMEOUT"] = "5"
os.environ["BIOMETRIC_DEVICE_ID"] = "test-clock"
os.environ["BIOMETRIC_MATCH_DOCUMENT_NUMBER"] = "false"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

# Shared backend supplies auth/core; the local overlay supplies the RRHH module
# under test (api_client, worker, router) without installing into Correspondencia.
shared = os.environ.get("RRHH_SHARED_BACKEND")
if shared:
    sys.path.insert(0, shared)
import app.modules.rrhh as rrhh_pkg
overlay_rrhh = str(Path(__file__).resolve().parents[1] / "app/modules/rrhh")
if overlay_rrhh not in rrhh_pkg.__path__:
    rrhh_pkg.__path__.insert(0, overlay_rrhh)

from app.main import app
from app.core.database import Base, get_db
from app.modules.rrhh.router import router
from app.modules.rrhh import models

if not any(route.path == "/rrhh/biometric/status" for route in app.routes):
    app.include_router(router)

test_engine = create_engine(url)


@pytest.fixture(scope="session", autouse=True)
def schema():
    Base.metadata.create_all(test_engine)
    yield
    test_engine.dispose()


@pytest.fixture(autouse=True)
def clean(schema):
    with test_engine.begin() as connection:
        # This URL was explicitly guarded above. Only the disposable database is touched.
        connection.execute(text("TRUNCATE " + ",".join('"' + t + '"' for t in Base.metadata.tables) + " CASCADE"))
    yield
    app.dependency_overrides.clear()


@pytest.fixture
def db():
    with Session(test_engine, expire_on_commit=False) as session:
        yield session


@pytest.fixture
def client():
    def session():
        with Session(test_engine, expire_on_commit=False) as db:
            yield db
    app.dependency_overrides[get_db] = session
    with TestClient(app) as client:
        yield client
