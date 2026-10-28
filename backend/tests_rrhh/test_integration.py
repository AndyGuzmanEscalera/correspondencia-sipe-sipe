import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime
from types import SimpleNamespace
from unittest.mock import Mock, patch

import pytest
from fastapi import HTTPException
from pydantic import ValidationError
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee
from app.modules.rrhh.biometric_service import BiometricService
from app.modules.rrhh.models import ContractPolicy, Device, EmployeeLink, Record, Sync
from app.modules.rrhh.periods import period_for
from app.modules.rrhh.reader.config import Config
from app.modules.rrhh.reader.connection import DeviceError
from app.modules.rrhh.reader.records import attendance_record
from app.modules.rrhh.schemas import DateRange, NormalizedRecord
from app.modules.rrhh.storage import employee_lookup, persist_records
from app.modules.rrhh.worker import run_once
from .conftest import test_engine


def auth(db, permissions=("rrhh.read", "rrhh.manage")):
    user = User(id=uuid.uuid4(), username=uuid.uuid4().hex, password_hash="unused", is_active=True)
    db.add(user)
    role = Role(id=uuid.uuid4(), code=uuid.uuid4().hex, name="Test", is_active=True)
    db.add(role)
    db.flush()
    db.add(UserRole(user_id=user.id, role_id=role.id))
    for code in permissions:
        permission = db.scalar(select(Permission).where(Permission.code == code))
        if permission is None:
            permission = Permission(id=uuid.uuid4(), code=code)
            db.add(permission)
            db.flush()
        db.add(RolePermission(role_id=role.id, permission_id=permission.id))
    db.commit()
    token, _ = create_access_token(user.id)
    return {"Authorization": "Bearer " + token}


def device(db):
    db.add(Device(device_id="test-clock", ip="127.0.0.1", port=4370))
    db.commit()


def row(user="007", stamp="2026-10-01T08:00:00", status=4, punch=9):
    return attendance_record(SimpleNamespace(user_id=user, timestamp=datetime.fromisoformat(stamp),
                                             status=status, punch=punch, uid=23), "test-clock")


def fake_service(rows=None, error=None):
    reader = Mock(config=Config("127.0.0.1", device_id="test-clock"))
    reader.attendance.return_value = [row()] if rows is None else rows
    if error:
        reader.attendance.side_effect = error
    return BiometricService(reader)


def worker(service):
    return run_once(lambda: Session(test_engine, expire_on_commit=False), test_engine, lambda: service)


def test_dedup_across_sources_and_transactions(db):
    device(db)
    assert persist_records(db, "test-clock", [row(), row()], "SOURCE_API") == 1
    db.commit()
    assert persist_records(db, "test-clock", [row()], "SOURCE_FILE") == 0
    db.commit()
    stored = db.scalar(select(Record))
    assert stored.record_id == row()["record_id"]
    assert stored.status == 4 and stored.punch == 9 and stored.timestamp.tzinfo is None


def test_mapping_is_explicit_and_unknown_records_survive(db):
    device(db)
    employee = Employee(first_name="Test", last_name="Employee", document_number="007")
    db.add(employee)
    db.flush()
    persist_records(db, "test-clock", [row()], "SOURCE_API")
    db.commit()
    assert db.scalar(select(Record)).funcionario_id is None
    db.add(EmployeeLink(device_id="test-clock", user_id="unknown", funcionario_id=employee.id))
    db.flush()
    persist_records(db, "test-clock", [row("unknown"), row("unmatched")], "SOURCE_API")
    db.commit()
    assert db.scalar(select(Record).where(Record.user_id == "unknown")).funcionario_id == employee.id
    assert db.scalar(select(Record).where(Record.user_id == "unmatched")).funcionario_id is None


def test_document_matching_opt_in_exact_and_unambiguous():
    a = SimpleNamespace(id=uuid.uuid4(), document_number="007")
    b = SimpleNamespace(id=uuid.uuid4(), document_number="007")
    assert employee_lookup([a], []) == {}
    assert employee_lookup([a], [], True) == {"007": a.id}
    assert employee_lookup([a, b], [], True) == {}
    assert "7" not in employee_lookup([a], [], True)


@pytest.mark.parametrize("path,method,body", [
    ("/biometric/status", "get", None), ("/biometric/users", "get", None),
    ("/biometric/sync", "post", {"start_date": "2026-10-01", "end_date": "2026-10-02"}),
    ("/attendance/parameters", "get", None), ("/attendance/parameters", "put", {}),
    ("/attendance/generate", "post", {"contract_type_id": str(uuid.uuid4()), "year": 2026, "month": 10}),
    ("/biometric/import", "post", {"device_id": "test-clock", "records": []}),
    ("/biometric/syncs/" + str(uuid.uuid4()), "get", None),
    ("/biometric/records/summary?device_id=x&start_date=2026-10-01&end_date=2026-10-02", "get", None),
    ("/attendance/employees/" + str(uuid.uuid4()) + "/records?start_date=2026-10-01&end_date=2026-10-02", "get", None),
    ("/biometric/devices/x/links/y", "put", {"funcionario_id": str(uuid.uuid4())}),
])
def test_endpoints_require_real_authentication(client, path, method, body):
    with patch("app.modules.rrhh.router.BiometricService") as service:
        response = client.request(method, "/rrhh" + path, **({"json": body} if body is not None else {}))
        assert response.status_code == 401
        service.assert_not_called()


def test_authorized_reader_cannot_manage(client, db):
    headers = auth(db, ("rrhh.read",))
    assert client.get("/rrhh/attendance/parameters", headers=headers).status_code == 200
    assert client.post("/rrhh/biometric/sync", headers=headers,
                       json={"start_date": "2026-10-01", "end_date": "2026-10-02"}).status_code == 403


def test_authenticated_user_without_rrhh_permission_is_denied(client, db):
    headers = auth(db, ())
    with patch("app.modules.rrhh.router.BiometricService") as service:
        assert client.get("/rrhh/biometric/status", headers=headers).status_code == 403
        assert client.get("/rrhh/attendance/parameters", headers=headers).status_code == 403
        service.assert_not_called()


def test_invalid_configuration_never_uses_reader_defaults(monkeypatch):
    monkeypatch.setenv("BIOMETRIC_IP", "")
    with patch("app.modules.rrhh.biometric_service.Reader") as reader:
        with pytest.raises(HTTPException) as error:
            BiometricService()
        assert error.value.detail["code"] == "biometric_invalid_configuration"
        reader.assert_not_called()


@pytest.mark.parametrize("payload", [{}, {"start_date": "2026-10-01"},
    {"start_date": "2026-10-03", "end_date": "2026-10-01"},
    {"start_date": "2020-01-01", "end_date": "2026-10-01"}])
def test_sync_date_validation(client, db, payload):
    headers = auth(db)
    with patch("app.modules.rrhh.router.BiometricService") as service:
        assert client.post("/rrhh/biometric/sync", headers=headers, json=payload).status_code == 422
        service.assert_not_called()


def test_queue_repeat_sync_full_history_and_status(client, db):
    headers = auth(db)
    payload = {"start_date": "2026-10-01", "end_date": "2026-10-02"}
    response = client.post("/rrhh/biometric/sync", headers=headers, json=payload)
    assert response.status_code == 202
    job_id = response.json()["id"]
    repeat = client.post("/rrhh/biometric/sync", headers=headers, json=payload)
    assert repeat.status_code == 409 and repeat.json()["detail"]["sync_id"] == job_id
    service = fake_service([row(), row(stamp="2025-01-01T09:00:00")])
    assert worker(service)
    status = client.get("/rrhh/biometric/syncs/" + job_id, headers=headers).json()
    assert status["status"] == "completed" and status["new_records"] == 2
    assert db.scalar(select(func.count()).select_from(Record)) == 2  # Not only requested dates.
    assert client.post("/rrhh/biometric/sync", headers=headers, json=payload).status_code == 202
    assert worker(service)
    assert db.scalar(select(func.count()).select_from(Record)) == 2


def test_concurrent_enqueues_only_one_wins(client, db):
    headers = auth(db)
    def enqueue(_):
        return client.post("/rrhh/biometric/sync", headers=headers,
                           json={"start_date": "2026-10-01", "end_date": "2026-10-02"}).status_code
    with ThreadPoolExecutor(max_workers=2) as pool:
        assert sorted(pool.map(enqueue, range(2))) == [202, 409]


def test_device_lock_blocks_second_process_style_connection():
    service = fake_service()
    with service.device_lock(test_engine):
        with pytest.raises(HTTPException) as error:
            with service.device_lock(test_engine):
                pass
        assert error.value.status_code == 409
    with service.device_lock(test_engine):
        pass


def test_failed_download_is_controlled_and_atomic(client, db):
    headers = auth(db)
    result = client.post("/rrhh/biometric/sync", headers=headers,
                         json={"start_date": "2026-10-01", "end_date": "2026-10-02"})
    assert worker(fake_service(error=DeviceError("timeout password=secret")))
    status = client.get("/rrhh/biometric/syncs/" + result.json()["id"], headers=headers).json()
    assert status["status"] == "failed" and status["error_code"] == "biometric_timeout"
    assert "secret" not in str(status)
    assert db.scalar(select(func.count()).select_from(Record)) == 0


def test_malformed_batch_rolls_back_all_records(client, db):
    headers = auth(db)
    client.post("/rrhh/biometric/sync", headers=headers,
                json={"start_date": "2026-10-01", "end_date": "2026-10-02"})
    records = [row(str(i)) for i in range(1001)] + [{"timestamp": "bad"}]
    assert worker(fake_service(records))
    assert db.scalar(select(func.count()).select_from(Record)) == 0
    assert db.scalar(select(Sync)).status == "failed"


def test_orphaned_running_job_recovered_without_redownload(db):
    device(db)
    db.add(Sync(device_id="test-clock", requested_start_date=date(2026, 10, 1),
                requested_end_date=date(2026, 10, 2), status="running"))
    db.commit()
    service = fake_service()
    assert worker(service)
    service.reader.attendance.assert_not_called()
    db.expire_all()
    assert db.scalar(select(Sync)).error_code == "biometric_interrupted"


def test_employee_query_links_and_unknown_summary(client, db):
    headers = auth(db)
    device(db)
    employee = Employee(first_name="Test", last_name="Employee")
    db.add(employee)
    db.commit()
    persist_records(db, "test-clock", [row(stamp="2026-10-02T23:59:59"), row(),
                     row(stamp="2026-10-03T00:00:00"), row("unknown")], "SOURCE_API")
    db.commit()
    result = client.put("/rrhh/biometric/devices/test-clock/links/007", headers=headers,
                        json={"funcionario_id": str(employee.id)})
    assert result.status_code == 200 and result.json()["updated_records"] == 3
    params = "?start_date=2026-10-01&end_date=2026-10-02"
    with patch("app.modules.rrhh.router.BiometricService") as service:
        result = client.get(f"/rrhh/attendance/employees/{employee.id}/records" + params, headers=headers)
        records = result.json()["records"]
        assert len(records) == 2 and records[0]["timestamp"] < records[1]["timestamp"]
        summary = client.get("/rrhh/biometric/records/summary" + params + "&device_id=test-clock", headers=headers).json()
        assert summary["linked"] == 2 and summary["unlinked"] == 1
        assert summary["unknown_users"] == [{"user_id": "unknown", "records": 1}]
        service.assert_not_called()
    assert client.get(f"/rrhh/attendance/employees/{employee.id}/records?start_date=2026-10-03&end_date=2026-10-01",
                      headers=headers).status_code == 422


def test_parameters_persist_and_validate(client, db):
    headers = auth(db)
    result = client.get("/rrhh/attendance/parameters", headers=headers).json()
    assert result["configured"] is False and result["duplicate_window"] is None
    values = {key: 30 for key in ("morning_entry_tolerance", "morning_exit_tolerance", "afternoon_entry_tolerance",
                                 "afternoon_exit_tolerance", "minimum_return_interval", "duplicate_window")}
    assert client.put("/rrhh/attendance/parameters", headers=headers, json=values).status_code == 200
    assert client.get("/rrhh/attendance/parameters", headers=headers).json()["duplicate_window"] == 30
    values["duplicate_window"] = -1
    assert client.put("/rrhh/attendance/parameters", headers=headers, json=values).status_code == 422


def test_normalized_file_import_uses_same_hash(client, db):
    headers = auth(db)
    device(db)
    raw = {k: v for k, v in row().items() if k in NormalizedRecord.model_fields}
    result = client.post("/rrhh/biometric/import", headers=headers,
                         json={"device_id": "test-clock", "records": [raw, raw]})
    assert result.status_code == 200 and result.json()["new_records"] == 1
    assert db.scalar(select(Record)).record_id == row()["record_id"]
    assert persist_records(db, "test-clock", [row()], "SOURCE_API") == 0


def test_status_safe_and_device_error_controlled(client, db):
    headers = auth(db)
    service = fake_service()
    service.reader.info.return_value = {"nombre_modelo": "uFace802 Plus", "serial": "synthetic", "transporte": "TCP"}
    with patch("app.modules.rrhh.router.BiometricService", return_value=service):
        result = client.get("/rrhh/biometric/status", headers=headers)
        assert result.status_code == 200 and result.json()["connected"] is True
        assert "password" not in result.text and "ip" not in result.json()
        service.reader.info.side_effect = DeviceError("Autenticación rechazada: secret")
        result = client.get("/rrhh/biometric/status", headers=headers)
        assert result.status_code == 503 and "secret" not in result.text
        assert result.json()["detail"]["connected"] is False


def test_device_users_have_minimal_fields_and_hide_secrets():
    service = fake_service()
    service.reader.users.return_value = [{"user_id": "007", "uid": 1, "name": "Test", "card": 123,
                                          "password": "secret", "privilege": 14, "template": "secret"}]
    assert service.users() == [{"user_id": "007", "uid": 1, "name": "Test"}]


def test_generation_reports_real_missing_configuration(client, db):
    headers = auth(db)
    payload = {"contract_type_id": str(uuid.uuid4()), "year": 2026, "month": 10}
    result = client.post("/rrhh/attendance/generate", headers=headers, json=payload).json()
    assert result["ready"] is False and result["period"] is None
    policy = ContractPolicy(id=uuid.UUID(payload["contract_type_id"]), name="Confirmed synthetic policy", cutoff_day=25)
    db.add(policy)
    db.commit()
    result = client.post("/rrhh/attendance/generate", headers=headers, json=payload).json()
    assert result["period"] == {"start_date": "2026-09-26", "end_exclusive": "2026-10-26"}
    assert result["biometric_coverage"] == "unknown"


@pytest.mark.parametrize("year,month", [(2024, 2), (2026, 12), (2026, 1)])
@pytest.mark.parametrize("cutoff", [1, 25, 30, 31])
def test_consecutive_periods_do_not_overlap(year, month, cutoff):
    start, end = period_for(year, month, cutoff)
    next_year, next_month = (year + 1, 1) if month == 12 else (year, month + 1)
    assert period_for(next_year, next_month, cutoff)[0] == end
    assert start < end


@pytest.mark.parametrize("timestamp", ["2026-10-01T08:00:00Z", "2026-10-01T08:00:00.123"])
def test_device_time_must_be_naive_seconds(timestamp):
    with pytest.raises(ValidationError):
        NormalizedRecord(user_id="007", timestamp=timestamp)
