import uuid
from datetime import time

import pytest

from app.modules.rrhh.evaluation_models import EventKind, ShiftDefinition, ShiftSegment
from app.modules.rrhh.shift_source import schedule_from_shift
from .test_engine import DAY


def shift(overnight=False):
    return ShiftDefinition(id=uuid.uuid4(), name="Synthetic existing shift", active=True, segments=(
        ShiftSegment(sequence=1, start_time=time(8), end_time=time(12), ends_next_day=overnight),
        ShiftSegment(sequence=2, start_time=time(14), end_time=time(18), ends_next_day=False)))


def windows():
    return {EventKind.MORNING_ENTRY: (time(6), time(10)), EventKind.MORNING_EXIT: (time(11), time(13)),
            EventKind.AFTERNOON_ENTRY: (time(13), time(16)), EventKind.FINAL_EXIT: (time(17), time(23))}


def sessions():
    return ((EventKind.MORNING_ENTRY, EventKind.MORNING_EXIT), (EventKind.AFTERNOON_ENTRY, EventKind.FINAL_EXIT))


def test_existing_segment_fields_become_expected_events_only_with_explicit_policy():
    original = shift()
    plan = schedule_from_shift(DAY, original, sessions(), windows())
    assert plan.shift_id == str(original.id)
    assert plan.events[0].expected_at.time() == original.segments[0].start_time
    assert plan.events[-1].expected_at.time() == original.segments[-1].end_time
    assert original.assignment_scope == "current_unversioned"


def test_association_windows_are_required_not_guessed():
    with pytest.raises(KeyError):
        schedule_from_shift(DAY, shift(), sessions(), {})


def test_existing_overnight_flag_is_preserved_and_requires_future_policy():
    original = shift(True)
    with pytest.raises(ValueError, match="Overnight"):
        schedule_from_shift(DAY, original, sessions(), windows())
    assert original.segments[0].ends_next_day


def test_inactive_shift_does_not_silently_evaluate_as_a_workday():
    with pytest.raises(ValueError):
        schedule_from_shift(DAY, shift().model_copy(update={"active": False}), sessions(), windows())
