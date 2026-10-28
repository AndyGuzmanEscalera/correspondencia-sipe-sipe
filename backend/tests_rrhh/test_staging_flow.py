import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from sqlalchemy import func, select, text

from app.core.database import get_db
from app.main import app
from app.modules.organization.employee import Employee
from app.modules.rrhh.models import ContractPolicy, EmployeeLink, Parameters, Record, Sync
from app.modules.rrhh.storage import persist_records
from app.modules.rrhh.staging_check import inspect_stored
from app.modules.rrhh.staging_source import StagingAttendanceSource, StagingConfiguration
from tests_evaluation.test_engine import params
from .test_integration import auth, device


def test_real_qa_source_through_existing_authenticated_endpoints(client, db, monkeypatch, tmp_path):
    data = json.loads((Path(__file__).resolve().parents[1] / "staging/attendance.example.json").read_text(encoding="utf-8"))
    data["database_name"] = db.get_bind().url.database
    data["device_id"] = "test-clock"
    data["employees"][0]["biometric_user_id"] = "007"
    config = StagingConfiguration.model_validate(data)
    person = config.employees[0]
    headers = auth(db)
    device(db)
    db.add_all([Employee(id=person.employee_id, first_name="Synthetic", last_name="QA"),
                Parameters(id=1, **params().model_dump())])
    db.commit()
    path = tmp_path / "attendance.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    monkeypatch.setenv("RRHH_STAGING_CONFIG", str(path))
    # Transactional optional legacy schema is restricted to the disposable test DB.
    try:
        db.execute(text("CREATE TABLE work_shifts (id uuid PRIMARY KEY, name varchar(200), is_active boolean)"))
        db.execute(text("CREATE TABLE work_shift_segments (work_shift_id uuid, sequence integer, start_time time, end_time time, ends_next_day boolean)"))
        db.execute(text("ALTER TABLE employees ADD COLUMN work_shift_id uuid"))
        db.execute(text("INSERT INTO work_shifts VALUES (:id,'Synthetic existing shift',true)"), {"id": person.shift_id})
        db.execute(text("INSERT INTO work_shift_segments VALUES (:id,1,'08:00','12:00',false),(:id,2,'14:00','18:00',false)"), {"id": person.shift_id})
        db.execute(text("UPDATE employees SET work_shift_id=:s WHERE id=:e"), {"s": person.shift_id, "e": person.employee_id})
        def session():
            yield db
        app.dependency_overrides[get_db] = session
        with patch("app.core.config.get_settings", return_value=SimpleNamespace(app_env="qa")), patch(
                "app.modules.rrhh.router.BiometricService") as hardware:
            assert client.get("/rrhh/attendance/contracts").status_code == 401
            catalog = client.get("/rrhh/attendance/contracts", headers=headers).json()
            assert catalog["items"][0]["name"].startswith("[PRUEBA STAGING]")
            payload = {"contract_type_id": str(config.contract_type_id), "year": config.year, "month": config.month}
            generation = client.post("/rrhh/attendance/generate", headers=headers, json=payload)
            response = client.get(f"/rrhh/attendance/employees/{person.employee_id}/report", headers=headers, params=payload)
            assert generation.status_code == response.status_code == 200
            report = response.json()
            assert not report["ready"] and report["period_confirmed"]
            assert "biometric_employee_link" in report["pending_configuration"]
            assert generation.json()["employees"][0]["summary"] == report["summary"]
            assert len(report["days"]) == len(report["calendar"]) == 2
            assert report["biometric_coverage"] == "unknown"
            assert report["days"][0]["absence_minutes"] is None
            diagnostic = inspect_stored(db, StagingAttendanceSource(config))
            assert diagnostic["employees"][0]["link_status"] == "unlinked"
            assert len(diagnostic["employees"][0]["days_without_stored_marks"]) == 2
            assert diagnostic["employees"][0]["report"] == report
            # Raw evidence is visible even before linking. Endpoints and the
            # diagnostic must never invent employee ownership or coverage.
            persist_records(db, "test-clock", [{"user_id": "007", "timestamp": "2026-10-01T08:10:00",
                "status": 89, "punch": 42, "uid": 1}], "SOURCE_API")
            db.add(Sync(device_id="test-clock", requested_start_date=config.period.start_date,
                requested_end_date=config.period.start_date, status="completed", downloaded_records=2, new_records=1))
            db.flush()
            unlinked = inspect_stored(db, StagingAttendanceSource(config))
            assert unlinked["latest_sync"]["duplicates_ignored"] == 1
            assert unlinked["employees"][0]["stored_records_for_identifier"][0]["punch"] == 42
            assert unlinked["employees"][0]["daily_counts"] == {"2026-10-01": 1, "2026-10-02": 0}
            assert len(unlinked["employees"][0]["record_link_mismatches"]) == 1
            db.add(EmployeeLink(device_id="test-clock", user_id="007", funcionario_id=person.employee_id))
            record = db.scalar(select(Record))
            record.funcionario_id = person.employee_id
            db.flush()
            linked = inspect_stored(db, StagingAttendanceSource(config))
            assert linked["employees"][0]["link_status"] == "linked"
            assert linked["employees"][0]["record_link_mismatches"] == []
            assert linked["employees"][0]["report"]["summary"]["total_records"] == 1
            assert linked["employees"][0]["report"]["ready"]
            assert linked["employees"][0]["report"]["biometric_coverage"] == "unknown"
            hardware.assert_not_called()
            db.execute(text("UPDATE work_shifts SET is_active=false"))
            missing = client.post("/rrhh/attendance/generate", headers=headers, json=payload).json()
            assert not missing["ready"] and "employee_shift_source" in missing["pending_configuration"]
            assert db.scalar(select(func.count()).select_from(ContractPolicy)) == 0
    finally:
        db.rollback()


def test_inspect_cli_reads_without_device_access_or_sql_changes(db, tmp_path):
    import os
    import subprocess
    import sys
    data = json.loads((Path(__file__).resolve().parents[1] / "staging/attendance.example.json").read_text(encoding="utf-8"))
    data["database_name"] = db.get_bind().url.database
    config = StagingConfiguration.model_validate(data)
    db.add(Employee(id=config.employees[0].employee_id, first_name="Synthetic", last_name="CLI"))
    db.commit()
    path = tmp_path / "attendance.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    environment = {**os.environ, "APP_ENV": "qa", "RRHH_STAGING_CONFIG": str(path),
        "DATABASE_URL": db.get_bind().url.render_as_string(hide_password=False), "PYTHONIOENCODING": "utf-8"}
    process = subprocess.run([sys.executable, "-m", "app.modules.rrhh.staging_check", "inspect"],
        env=environment, capture_output=True, text=True, encoding="utf-8", timeout=30)
    assert process.returncode == 0, process.stderr
    diagnostic = json.loads(process.stdout)
    assert diagnostic["employees"][0]["link_status"] == "unlinked"
    assert not diagnostic["employees"][0]["report"]["ready"]
    assert diagnostic["device_stored_range"]["total"] == 0
    assert db.scalar(select(func.count()).select_from(Parameters)) == 0
    assert db.scalar(select(func.count()).select_from(ContractPolicy)) == 0
