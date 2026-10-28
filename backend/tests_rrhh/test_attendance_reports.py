import uuid
from datetime import date, datetime, timedelta

from sqlalchemy import select, text
from unittest.mock import patch

from app.modules.rrhh.attendance_source import WorkforceData, get_attendance_source
from app.modules.rrhh.evaluation_models import DaySchedule, EvaluationPeriod
from app.modules.rrhh.models import ContractPolicy, EmployeeLink, Parameters, Record
from app.modules.organization.employee import Employee
from app.modules.rrhh.shift_source import ExistingShiftReader
from app.modules.rrhh.storage import persist_records
from tests_evaluation.test_engine import DAY, EMPLOYEE, params, plan
from .test_integration import auth, device

CONTRACT = uuid.UUID("20000000-0000-4000-8000-000000000001")


def setup_report(db, entry="07:55:00"):
    headers = auth(db)
    device(db)
    employee = Employee(id=EMPLOYEE, first_name="Synthetic", last_name="Employee", document_number="007")
    other = Employee(first_name="Other", last_name="Employee", document_number="888")
    db.add_all([employee, other, ContractPolicy(id=CONTRACT, name="Synthetic confirmed policy", cutoff_day=25),
                Parameters(id=1, **params().model_dump())])
    db.flush()
    db.add_all([EmployeeLink(device_id="test-clock", user_id="007", funcionario_id=employee.id),
                EmployeeLink(device_id="test-clock", user_id="888", funcionario_id=other.id)])
    db.flush()
    records = [{"user_id": "007", "timestamp": f"2026-10-01T{value}", "status": 89, "punch": 42, "uid": i}
               for i, value in enumerate((entry, "12:05:00", "13:55:00", "18:10:00"))]
    records.extend([{"user_id": "888", "timestamp": "2026-10-01T08:10:00", "status": 89, "punch": 42},
                    {"user_id": "007", "timestamp": "2026-10-03T08:10:00", "status": 89, "punch": 42}])
    persist_records(db, "test-clock", records, "SOURCE_API")
    db.commit()
    return headers


class ConfirmedSource:
    def resolve_period(self, db, policy, year, month):
        return EvaluationPeriod(start_date=DAY, end_exclusive=DAY + timedelta(days=2))

    def load(self, db, contract_type_id, period):
        tomorrow = DAY + timedelta(days=1)
        return WorkforceData(employee_ids=(EMPLOYEE,), contracts={EMPLOYEE: (CONTRACT, "Synthetic confirmed contract")},
            schedules={EMPLOYEE: {DAY: plan(), tomorrow: DaySchedule(day=tomorrow, shift_id="rest", name="Confirmed rest")}},
            coverage={EMPLOYEE: {DAY: True, tomorrow: True}})


def report_path(employee_id=EMPLOYEE):
    return f"/rrhh/attendance/employees/{employee_id}/report?year=2026&month=10&contract_type_id={CONTRACT}"


def snapshot(db):
    return db.execute(select(Record.record_id, Record.timestamp, Record.status, Record.punch, Record.uid,
                             Record.source, Record.funcionario_id).order_by(Record.record_id)).all()


def test_individual_report_is_protected(client):
    assert client.get(report_path()).status_code == 401


def test_default_source_reports_missing_dependencies_and_real_employee_header(client, db):
    headers = setup_report(db)
    result = client.get(report_path(), headers=headers)
    assert result.status_code == 200
    body = result.json()
    assert body["ready"] is False and body["period_confirmed"] is False
    assert body["employee"]["document_number"] == "007" and body["employee"]["item_code"] is None
    assert body["days"] == [] and body["summary"] is None
    assert "confirmed_contract_period_semantics" in body["pending_configuration"]


def test_generate_and_report_share_daily_engine_without_changing_evidence(client, db):
    headers = setup_report(db)
    from app.main import app
    app.dependency_overrides[get_attendance_source] = lambda: ConfirmedSource()
    before = snapshot(db)
    with patch("app.modules.rrhh.router.BiometricService") as service:
        generation = client.post("/rrhh/attendance/generate", headers=headers,
            json={"contract_type_id": str(CONTRACT), "year": 2026, "month": 10})
        response = client.get(report_path(), headers=headers)
        service.assert_not_called()
    assert generation.status_code == response.status_code == 200
    report, summary = response.json(), generation.json()
    assert report["ready"] and report["period_confirmed"] and summary["ready"]
    assert report["summary"] == summary["employees"][0]["summary"]
    assert report["summary"]["total_records"] == 4  # Excludes other employee and end-exclusive date.
    assert report["days"][0]["status"] == "NORMAL" and report["calendar"][1]["status"] == "NO_DATA"
    assert report["shifts"][0]["id"] == "synthetic"
    assert report["days"][0]["original_records"][0]["punch"] == 42
    assert report["days"][0]["absence_minutes"] is None
    db.expire_all()
    assert snapshot(db) == before


def test_parameter_change_recalculates_without_persisting_analysis(client, db):
    headers = setup_report(db, entry="08:10:00")
    from app.main import app
    app.dependency_overrides[get_attendance_source] = lambda: ConfirmedSource()
    before = snapshot(db)
    first = client.get(report_path(), headers=headers).json()
    assert first["summary"]["total_late_minutes"] == 5
    result = client.put("/rrhh/attendance/parameters", headers=headers,
                       json=params(morning_entry_tolerance=600).model_dump())
    assert result.status_code == 200
    second = client.get(report_path(), headers=headers).json()
    assert second["summary"]["total_late_minutes"] == 0
    assert first["parameters"]["morning_entry_tolerance"] == 300
    assert second["parameters"]["morning_entry_tolerance"] == 600
    assert snapshot(db) == before


def test_report_handles_missing_employee_and_invalid_filters(client, db):
    headers = auth(db)
    assert client.get(report_path(uuid.uuid4()), headers=headers).status_code == 404
    assert client.get(report_path().replace("month=10", "month=13"), headers=headers).status_code == 422
    assert client.get(report_path().replace("year=2026", "year=9999"), headers=headers).status_code == 422


def test_report_requires_rrhh_permission(client, db):
    headers = auth(db, ())
    assert client.get(report_path(), headers=headers).status_code == 403


def test_existing_shift_reader_handles_optional_schema_absence(db):
    assert ExistingShiftReader(db).current_assignments((uuid.uuid4(),)) == {}


def test_existing_shift_reader_reuses_physical_tables_and_never_alters_them(db):
    # DDL and synthetic data remain inside this transaction and are rolled back.
    try:
        db.execute(text("CREATE TABLE work_shifts (id uuid PRIMARY KEY, name varchar(200), is_active boolean)"))
        db.execute(text("CREATE TABLE work_shift_segments (work_shift_id uuid, sequence integer, start_time time, end_time time, ends_next_day boolean)"))
        db.execute(text("ALTER TABLE employees ADD COLUMN work_shift_id uuid"))
        employee_id, shift_id = uuid.uuid4(), uuid.uuid4()
        db.add(Employee(id=employee_id, first_name="Synthetic", last_name="Shift"))
        db.flush()
        db.execute(text("INSERT INTO work_shifts VALUES (:id,'Synthetic existing shift',true)"), {"id": shift_id})
        db.execute(text("INSERT INTO work_shift_segments VALUES (:id,1,'22:00','06:00',true)"), {"id": shift_id})
        db.execute(text("UPDATE employees SET work_shift_id=:s WHERE id=:e"), {"s": shift_id, "e": employee_id})
        result = ExistingShiftReader(db).current_assignments((employee_id,))
        assert result[employee_id].id == shift_id
        assert result[employee_id].segments[0].ends_next_day
        assert result[employee_id].assignment_scope == "current_unversioned"
        assert db.execute(text("SELECT count(*) FROM work_shift_segments")).scalar() == 1
    finally:
        db.rollback()
