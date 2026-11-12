import json
from contextlib import contextmanager
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.modules.rrhh.attendance_source import PendingAttendanceSource, get_attendance_source
from app.modules.rrhh.staging_check import preflight
from app.modules.rrhh.staging_source import StagingAttendanceSource, StagingConfiguration


def configuration():
    return json.loads((Path(__file__).resolve().parents[1] / "staging/attendance.example.json").read_text(encoding="utf-8"))


@pytest.mark.parametrize("change", [
    {"database_name": "institutional"}, {"purpose": "production"}, {"month": 11},
    {"employees": []}, {"period": {"start_date": "2026-10-01", "end_exclusive": "2026-10-05"}},
])
def test_configuration_rejects_uncontrolled_scope(change):
    with pytest.raises(ValidationError):
        StagingConfiguration.model_validate({**configuration(), **change})


def test_configuration_requires_all_dates_and_unique_people():
    data = configuration()
    data["employees"][0]["working_days"].pop("2026-10-02")
    with pytest.raises(ValidationError):
        StagingConfiguration.model_validate(data)
    data = configuration()
    data["employees"] *= 2
    with pytest.raises(ValidationError):
        StagingConfiguration.model_validate(data)


@pytest.mark.parametrize("environment", ["production", "development"])
def test_staging_source_cannot_be_enabled_outside_qa(monkeypatch, environment):
    monkeypatch.setenv("RRHH_STAGING_CONFIG", "does-not-exist.json")
    with patch("app.core.config.get_settings", return_value=SimpleNamespace(app_env=environment)):
        with pytest.raises(HTTPException) as error:
            get_attendance_source()
    assert error.value.detail["code"] == "staging_configuration_forbidden"


def test_default_source_and_bad_file_are_controlled(monkeypatch):
    monkeypatch.delenv("RRHH_STAGING_CONFIG", raising=False)
    assert isinstance(get_attendance_source(), PendingAttendanceSource)
    monkeypatch.setenv("RRHH_STAGING_CONFIG", "does-not-exist.json")
    with patch("app.core.config.get_settings", return_value=SimpleNamespace(app_env="qa")):
        with pytest.raises(HTTPException) as error:
            get_attendance_source()
    assert error.value.detail["code"] == "staging_configuration_invalid"


def test_database_and_period_must_match_exactly():
    source = StagingAttendanceSource(StagingConfiguration.model_validate(configuration()))
    db = SimpleNamespace(get_bind=lambda: SimpleNamespace(url=SimpleNamespace(database="other_staging")))
    with pytest.raises(HTTPException) as error:
        source.contracts(db)
    assert error.value.detail["code"] == "staging_database_mismatch"
    db = SimpleNamespace(get_bind=lambda: SimpleNamespace(url=SimpleNamespace(database="rrhh_staging")))
    with pytest.raises(HTTPException) as error:
        source.resolve_period(db, None, 2026, 11)
    assert error.value.status_code == 422
    assert source.contracts(db).items[0].name.startswith("[PRUEBA STAGING]")


def test_preflight_only_calls_health_and_device():
    calls = []

    class Client:
        def health(self):
            calls.append("health")
            return {"status": "ok"}

        def get_device(self):
            calls.append("get_device")
            return {"connected": True, "device_name": "uFace", "serial_number": "synthetic",
                    "platform": "ZK", "firmware_version": "1", "transport": "https"}

        def get_users(self):
            raise AssertionError("preflight must not list users")

        def download_attendance(self, **_kwargs):
            raise AssertionError("preflight must not download attendance")

    @contextmanager
    def device_lock(engine):
        calls.append("lock")
        try:
            yield
        finally:
            calls.append("unlock")

    service = SimpleNamespace(client=Client(), device_lock=device_lock,
                              config=SimpleNamespace(device_id="test-clock",
                                                     url="https://biometric.example.test"))
    result = preflight(service, None)
    assert result["read_only"] is True
    assert result["api_available"] is True and result["device_connected"] is True
    assert result["model"] == "uFace" and result["serial"] == "synthetic"
    assert calls == ["lock", "health", "get_device", "unlock"]
