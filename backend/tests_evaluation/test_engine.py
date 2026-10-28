import uuid
from datetime import date, datetime, timedelta
from itertools import product

import pytest
from pydantic import ValidationError

from app.modules.rrhh.evaluation import (_optimal_candidates, calendar_days, evaluate_day,
                                         evaluate_period, period_summary)
from app.modules.rrhh.evaluation_models import (
    DaySchedule, DayStatus, EvaluationParameters, EvaluationPeriod, EventKind, ExpectedEvent,
    IncidentType, RawMark,
)

EMPLOYEE = uuid.UUID("10000000-0000-4000-8000-000000000001")
DAY = date(2026, 10, 1)


def stamp(value, day=DAY):
    return datetime.fromisoformat(f"{day.isoformat()}T{value}")


def plan(day=DAY):
    # All times/windows are explicitly synthetic test inputs, never engine defaults.
    specs = [(EventKind.MORNING_ENTRY, "08:00:00", "06:00:00", "09:30:00"),
             (EventKind.MORNING_EXIT, "12:00:00", "11:30:00", "12:39:59"),
             (EventKind.AFTERNOON_ENTRY, "14:00:00", "12:40:00", "15:30:00"),
             (EventKind.FINAL_EXIT, "18:00:00", "17:30:00", "23:59:59")]
    return DaySchedule(day=day, shift_id="synthetic", name="Synthetic test schedule", events=tuple(
        ExpectedEvent(kind=kind, expected_at=stamp(expected, day), window_start=stamp(start, day), window_end=stamp(end, day))
        for kind, expected, start, end in specs))


def params(**changes):
    return EvaluationParameters(**{**dict(morning_entry_tolerance=300, morning_exit_tolerance=0,
        afternoon_entry_tolerance=300, afternoon_exit_tolerance=0, minimum_return_interval=1800,
        duplicate_window=300), **changes})


def marks(*times, day=DAY, employee=EMPLOYEE):
    return tuple(RawMark(record_id=f"record-{i}", device_id="synthetic", user_id="007",
        funcionario_id=employee, timestamp=stamp(value, day), status=89, punch=42, uid=i, source="SOURCE_API")
        for i, value in enumerate(times))


def evaluate(times, parameters=None, schedule=None, coverage=True):
    return evaluate_day(EMPLOYEE, DAY, schedule or plan(), parameters or params(), marks(*times), coverage)


@pytest.mark.parametrize("entry,late", [("07:50:00", 0), ("08:00:00", 0), ("08:05:00", 0),
                                      ("08:06:00", 60), ("08:10:00", 300), ("08:05:01", 1)])
def test_entry_is_directional_and_late_begins_after_tolerance(entry, late):
    day = evaluate([entry, "12:05:00", "13:55:00", "18:10:00"])
    assert day.late_seconds == late
    assert day.status == (DayStatus.NORMAL if late == 0 else DayStatus.OBSERVATION)
    assert day.late_minutes == late / 60


@pytest.mark.parametrize("departure,early", [("17:50:00", 600), ("18:00:00", 0), ("18:20:00", 0)])
def test_exit_never_penalizes_staying_later(departure, early):
    day = evaluate(["07:55:00", "12:05:00", "13:55:00", departure])
    assert day.early_exit_seconds == early
    assert day.gross_early_exit_seconds == early
    assert (IncidentType.EARLY_EXIT in {i.type for i in day.incidents}) == (early > 0)
    assert day.overtime_minutes is None


def test_exit_tolerance_policy_remains_pending_as_requested():
    day = evaluate(["07:55:00", "12:05:00", "13:55:00", "17:50:00"], params(afternoon_exit_tolerance=300))
    assert day.gross_early_exit_minutes == 10
    assert day.early_exit_minutes is None
    assert "exit_tolerance_semantics" in day.pending_configuration
    assert day.events[-1].exit_tolerance_policy_pending


@pytest.mark.parametrize("return_time,late", [("13:45:00", 0), ("14:05:00", 0), ("14:10:00", 300)])
def test_second_entry_uses_its_own_tolerance(return_time, late):
    day = evaluate(["07:55:00", "12:05:00", return_time, "18:10:00"])
    assert day.events[2].late_seconds == late
    assert (IncidentType.LATE_RETURN in {i.type for i in day.incidents}) == (late > 0)


def test_four_mark_day_preserves_originals_and_is_normal():
    original = marks("07:55:00", "12:05:00", "13:55:00", "18:10:00")
    snapshot = tuple(mark.model_dump_json() for mark in original)
    day = evaluate_day(EMPLOYEE, DAY, plan(), params(), tuple(reversed(original)), True)
    assert day.status == DayStatus.NORMAL and day.reconstruction_complete
    assert day.original_records == original
    assert tuple(mark.model_dump_json() for mark in original) == snapshot
    assert day.final_exit == stamp("18:10:00")
    with pytest.raises(ValidationError):
        original[0].timestamp = stamp("08:00:00")


def test_duplicate_marks_are_only_suggested_not_removed_or_assigned():
    day = evaluate(["07:55:00", "12:05:00", "13:55:00", "18:10:00", "18:12:00", "18:15:00"])
    duplicate = next(i for i in day.incidents if i.type == IncidentType.POSSIBLE_DUPLICATE)
    assert len(duplicate.record_ids) == 3
    assert len(day.original_records) == 6
    assert day.final_exit is None and day.events[-1].record_id is None
    assert day.events[-1].association == "POSSIBLE_DUPLICATE"
    assert duplicate.suggestion.suggested_record_id == "record-3"
    assert day.status == DayStatus.OBSERVATION
    assert day.early_exit_seconds == 0  # All three candidates are safely later.


def test_duplicate_window_does_not_chain_indefinitely():
    day = evaluate(["07:55:00", "12:05:00", "13:55:00", "18:10:00", "18:14:00", "18:18:00"])
    groups = [i.record_ids for i in day.incidents if i.type == IncidentType.POSSIBLE_DUPLICATE]
    assert groups == [("record-3", "record-4")]
    assert day.final_exit is None
    assert day.status == DayStatus.ANOMALY


def test_raw_codes_are_not_interpreted_and_different_codes_do_not_imply_duplicates():
    original = marks("07:55:00", "12:05:00", "13:55:00", "18:10:00")
    changed = tuple(mark.model_copy(update={"punch": i * 87, "status": 255 - i}) for i, mark in enumerate(original))
    assert evaluate_day(EMPLOYEE, DAY, plan(), params(), changed).status == DayStatus.NORMAL
    original = marks("07:55:00", "12:05:00", "13:55:00", "18:10:00", "18:12:00")
    changed = original[:-1] + (original[-1].model_copy(update={"punch": 99}),)
    day = evaluate_day(EMPLOYEE, DAY, plan(), params(), changed)
    assert not any(i.type == IncidentType.POSSIBLE_DUPLICATE for i in day.incidents)
    assert day.final_exit is None  # Still ambiguous; code doesn't force a direction.


def test_one_extra_mark_is_informational_not_automatically_an_error():
    day = evaluate(["07:55:00", "10:30:00", "12:05:00", "13:55:00", "18:10:00"])
    assert day.status == DayStatus.NORMAL
    assert [i.type for i in day.incidents] == [IncidentType.EXTRA_MARK]
    assert len(day.original_records) == 5


def test_six_marks_can_describe_a_possible_intermediate_interval():
    day = evaluate(["07:55:00", "10:00:00", "11:00:00", "12:05:00", "13:55:00", "18:10:00"])
    assert day.status == DayStatus.ANOMALY
    assert day.intermediate_intervals[0].duration_seconds == 3600
    assert day.intermediate_intervals[0].requires_review
    assert day.absence_minutes is None
    assert len(day.original_records) == 6


def test_intermediate_exit_example_has_no_invented_cause_or_midday_marks():
    day = evaluate(["07:55:00", "11:03:00", "17:05:00", "18:02:00"])
    interval = day.intermediate_intervals[0]
    assert interval.duration_seconds == (6 * 60 + 2) * 60
    assert day.morning_exit is None and day.afternoon_entry is None
    assert day.status == DayStatus.ANOMALY
    assert sum(i.type == IncidentType.MISSING_MARK for i in day.incidents) == 2


@pytest.mark.parametrize("return_time,violation", [("12:40:00", True), ("12:55:00", True), ("13:00:00", False)])
def test_minimum_break_is_distinct_from_duplicates(return_time, violation):
    day = evaluate(["07:55:00", "12:30:00", return_time, "18:10:00"], params(duplicate_window=1800))
    assert (IncidentType.MINIMUM_BREAK_VIOLATION in {i.type for i in day.incidents}) == violation
    assert not any(i.type == IncidentType.POSSIBLE_DUPLICATE for i in day.incidents)


def test_missing_marks_do_not_turn_two_punches_into_a_complete_day():
    day = evaluate(["07:55:00", "18:10:00"])
    assert day.status == DayStatus.ANOMALY
    assert sum(i.type == IncidentType.MISSING_MARK for i in day.incidents) == 2
    assert day.late_minutes is None and day.absence_minutes is None


def test_irregular_four_marks_are_not_force_assigned_by_position():
    day = evaluate(["07:55:00", "10:00:00", "17:00:00", "18:03:00"])
    assert day.status == DayStatus.ANOMALY
    assert day.morning_exit is None and day.afternoon_entry is None
    assert sum(i.type == IncidentType.MISSING_MARK for i in day.incidents) == 2


def test_incoherent_unassignable_sequence_is_flagged():
    day = evaluate(["09:50:00", "10:00:00", "10:30:00"])
    assert day.status == DayStatus.ANOMALY
    assert IncidentType.INCONSISTENT_SEQUENCE in {i.type for i in day.incidents}
    assert all(event.record_id is None for event in day.events)


def test_ambiguous_entry_does_not_silently_choose_earliest_or_nearest():
    day = evaluate(["07:00:00", "08:20:00", "12:05:00", "13:55:00", "18:10:00"])
    assert day.morning_entry is None and day.events[0].association == "AMBIGUOUS"
    assert day.late_seconds is None and day.status == DayStatus.ANOMALY


def test_no_marks_and_missing_coverage_are_not_absence():
    day = evaluate([])
    assert day.status == DayStatus.NO_DATA and day.absence_minutes is None
    assert len(day.incidents) == 4
    day = evaluate(["07:55:00", "12:05:00", "13:55:00", "18:10:00"], coverage=False)
    assert day.status == DayStatus.NO_DATA and len(day.original_records) == 4
    assert day.late_minutes is None and day.reason == "outside_confirmed_coverage"


def test_missing_schedule_or_parameters_is_explicit():
    records = marks("07:55:00")
    missing_schedule = evaluate_day(EMPLOYEE, DAY, None, params(), records)
    assert missing_schedule.status == DayStatus.NO_DATA
    assert missing_schedule.pending_configuration == ("employee_shift_source",)
    missing_parameters = evaluate_day(EMPLOYEE, DAY, plan(), None, records)
    assert missing_parameters.pending_configuration == ("attendance_parameters",)


def test_different_parameters_change_late_without_changing_original_marks():
    times = ["08:10:00", "12:05:00", "14:10:00", "18:10:00"]
    assert evaluate(times).late_minutes == 10
    assert evaluate(times, params(morning_entry_tolerance=600, afternoon_entry_tolerance=600)).late_minutes == 0
    assert evaluate(times, params(morning_entry_tolerance=0, afternoon_entry_tolerance=0)).late_minutes == 20


def test_period_summary_calendar_and_explicit_non_working_day():
    tomorrow = DAY + timedelta(days=1)
    period = EvaluationPeriod(start_date=DAY, end_exclusive=tomorrow + timedelta(days=1))
    schedules = {DAY: plan(), tomorrow: DaySchedule(day=tomorrow, shift_id="rest", name="Confirmed non-working day")}
    days = evaluate_period(EMPLOYEE, period, schedules, params(),
        marks("08:10:00", "12:05:00", "13:55:00", "18:10:00"), {DAY: True})
    summary = period_summary(days)
    assert summary.days_evaluated == 1 and summary.observation_days == 1 and summary.no_data_days == 1
    assert summary.total_late_minutes == 5 and summary.total_records == 4 and summary.totals_complete
    calendar = calendar_days(days)
    assert calendar[0].incident_count == 1 and calendar[0].total_records == 4
    assert calendar[1].status == DayStatus.NO_DATA


def test_unknown_or_missing_days_do_not_become_zero_totals():
    days = evaluate_period(EMPLOYEE, EvaluationPeriod(start_date=DAY, end_exclusive=DAY + timedelta(days=2)),
        {DAY: plan()}, params(), marks("08:10:00", "12:05:00", "13:55:00", "18:10:00"))
    summary = period_summary(days)
    assert summary.total_late_minutes is None and summary.observed_late_seconds == 300
    assert not summary.totals_complete


def test_other_employee_or_day_records_are_rejected():
    with pytest.raises(ValueError):
        evaluate_day(uuid.uuid4(), DAY, plan(), params(), marks("07:55:00"))
    with pytest.raises(ValueError):
        evaluate_day(EMPLOYEE, DAY + timedelta(days=1), plan(), params(), marks("07:55:00"))


def test_overnight_or_incomplete_session_requires_a_confirmed_adapter():
    with pytest.raises(ValidationError):
        DaySchedule(day=DAY, shift_id="invalid", name="Invalid", events=plan().events[:1])
    with pytest.raises(ValidationError):
        DaySchedule(day=DAY + timedelta(days=1), shift_id="invalid", name="Invalid", events=plan().events)


def test_chronological_matching_agrees_with_all_small_exhaustive_assignments():
    events = plan().events[:2]
    for times in product(["07:00:00", "08:30:00", "10:30:00", "12:00:00"], repeat=3):
        records = sorted(marks(*times), key=lambda mark: (mark.timestamp, mark.record_id))
        units = [[mark] for mark in records]
        assignments = []
        for first, second in product([-1, 0, 1, 2], repeat=2):
            chosen = [index for index in (first, second) if index >= 0]
            if len(set(chosen)) != len(chosen) or chosen != sorted(chosen):
                continue
            if all(index < 0 or event.window_start <= records[index].timestamp <= event.window_end
                   for event, index in zip(events, (first, second))):
                assignments.append((first, second))
        maximum = max(sum(index >= 0 for index in candidate) for candidate in assignments)
        optimal = [candidate for candidate in assignments if sum(index >= 0 for index in candidate) == maximum]
        expected = [(sorted({candidate[i] for candidate in optimal if candidate[i] >= 0}),
                     any(candidate[i] < 0 for candidate in optimal)) for i in range(2)]
        assert _optimal_candidates(events, units) == expected
