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


def test_preflight_only_requests_basic_metadata_and_sizes():
    calls = []
    class Connection:
        users = 2
        def __getattr__(self, name):
            # Fails if clock, users, attendance, disable/enable or write requested.
            assert name in {"get_device_name", "get_serialnumber", "get_platform", "get_firmware_version", "read_sizes"}
            def call():
                calls.append(name)
                return "synthetic metadata"
            return call
    class Reader:
        last_transport = "TCP"
        @contextmanager
        def session(self):
            calls.append("connect")
            try:
                yield Connection()
            finally:
                calls.append("disconnect")
    @contextmanager
    def device_lock(engine):
        calls.append("lock")
        try:
            yield
        finally:
            calls.append("unlock")
    service = SimpleNamespace(reader=Reader(), device_lock=device_lock,
        config=SimpleNamespace(device_id="test-clock"))
    result = preflight(service, None)
    assert result["read_only"] and result["users_count"] == 2
    assert calls == ["lock", "connect", "get_device_name", "get_serialnumber", "get_platform",
                     "get_firmware_version", "read_sizes", "disconnect", "unlock"]
