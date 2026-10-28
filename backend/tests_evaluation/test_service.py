import uuid
from datetime import timedelta
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.modules.rrhh.attendance_service import AttendanceService
from app.modules.rrhh.attendance_source import PendingAttendanceSource, WorkforceData
from app.modules.rrhh.evaluation_models import EmployeeHeader, EvaluationPeriod
from .test_engine import DAY, EMPLOYEE, marks, params, plan

CONTRACT = uuid.UUID("20000000-0000-4000-8000-000000000001")


class Repository:
    def __init__(self, parameters=None):
        self.configuration = params() if parameters is None else parameters
        self.records_calls = []
        self.header = EmployeeHeader(id=EMPLOYEE, full_name="Synthetic Employee", document_number="007",
                                     unit_name="Synthetic Department", position_code="POST-1")

    def policy(self, contract_type_id):
        return SimpleNamespace(id=contract_type_id, cutoff_day=25)

    def parameters(self):
        return self.configuration, None

    def employees(self, ids):
        return {EMPLOYEE: self.header} if EMPLOYEE in ids else {}

    def current_shifts(self, ids):
        return {}

    def records(self, ids, period):
        self.records_calls.append((ids, period))
        return {EMPLOYEE: marks("08:10:00", "12:05:00", "13:55:00", "18:10:00")} if EMPLOYEE in ids else {}


class ConfirmedSource:
    def resolve_period(self, db, policy, year, month):
        return EvaluationPeriod(start_date=DAY, end_exclusive=DAY + timedelta(days=1))

    def load(self, db, contract_type_id, period):
        return WorkforceData(employee_ids=(EMPLOYEE,), contracts={EMPLOYEE: (CONTRACT, "Synthetic confirmed contract")},
            schedules={EMPLOYEE: {DAY: plan()}}, coverage={EMPLOYEE: {DAY: True}})


def test_default_source_is_controlled_and_never_queries_provisional_dates():
    repository = Repository()
    service = AttendanceService(None, PendingAttendanceSource(), repository)
    result = service.generate(CONTRACT, 2026, 10)
    assert not result.ready and not result.period_confirmed
    assert result.period.start_date.isoformat() == "2026-09-26"  # Legacy preview only.
    assert "confirmed_contract_period_semantics" in result.pending_configuration
    assert result.total_employees is None and not result.employees
    assert repository.records_calls == []
    report = service.report(EMPLOYEE, CONTRACT, 2026, 10)
    assert not report.ready and report.employee.document_number == "007"
    assert report.employee.item_code is None and report.employee.contract_type_name is None
    assert report.days == () and report.calendar == () and repository.records_calls == []


def test_confirmed_adapter_drives_generation_and_individual_report_consistently():
    repository = Repository()
    service = AttendanceService(None, ConfirmedSource(), repository)
    generation = service.generate(CONTRACT, 2026, 10)
    report = service.report(EMPLOYEE, CONTRACT, 2026, 10)
    assert generation.ready and report.ready and report.period_confirmed
    assert generation.employees[0].summary == report.summary
    assert generation.employees[0].employee == report.employee
    assert report.summary.total_late_minutes == 5 and report.calendar[0].status.value == "OBSERVATION"
    assert report.shifts[0].id == "synthetic" and report.biometric_coverage == "confirmed"
    assert report.employee.contract_type_name == "Synthetic confirmed contract"
    assert report.pending_policies == ("absence_policy", "overtime_policy", "exit_tolerance_semantics")
    assert len(report.days[0].original_records) == 4
    assert len(repository.records_calls) == 2


def test_source_cannot_mix_contracts():
    class BadSource(ConfirmedSource):
        def load(self, *args):
            return WorkforceData(employee_ids=(EMPLOYEE,), contracts={EMPLOYEE: (uuid.uuid4(), "Invalid")})
    with pytest.raises(HTTPException) as exc:
        AttendanceService(None, BadSource(), Repository()).generate(CONTRACT, 2026, 10)
    assert exc.value.detail["code"] == "attendance_source_invalid"


def test_employee_outside_confirmed_contract_is_rejected():
    class EmptySource(ConfirmedSource):
        def load(self, *args):
            return WorkforceData(employee_ids=())
    with pytest.raises(HTTPException) as exc:
        AttendanceService(None, EmptySource(), Repository()).report(EMPLOYEE, CONTRACT, 2026, 10)
    assert exc.value.status_code == 422


def test_confirmed_empty_population_differs_from_missing_source():
    class EmptySource(ConfirmedSource):
        def load(self, *args):
            return WorkforceData(employee_ids=())
    result = AttendanceService(None, EmptySource(), Repository()).generate(CONTRACT, 2026, 10)
    assert result.ready and result.total_employees == 0 and result.employees == ()


def test_missing_shift_keeps_records_in_calendar_and_marks_dependency():
    class MissingShift(ConfirmedSource):
        def load(self, *args):
            return WorkforceData(employee_ids=(EMPLOYEE,), contracts={EMPLOYEE: (CONTRACT, "Synthetic")})
    result = AttendanceService(None, MissingShift(), Repository()).report(EMPLOYEE, CONTRACT, 2026, 10)
    assert not result.ready and result.days[0].status.value == "NO_DATA"
    assert result.calendar[0].total_records == 4
    assert result.pending_configuration == ("employee_shift_source",)


def test_missing_parameters_are_pending_and_do_not_invent_values():
    repository = Repository()
    repository.configuration = None
    report = AttendanceService(None, ConfirmedSource(), repository).report(EMPLOYEE, CONTRACT, 2026, 10)
    assert not report.ready and report.parameters is None
    assert "attendance_parameters" in report.pending_configuration
    assert report.days[0].late_minutes is None
