"""HTTP tracking and disclosure regression tests; disposable test DB only."""
import hashlib
import hmac
import uuid

import pytest
from fastapi import HTTPException
from sqlalchemy import select

from app.core.config import get_settings
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.public_tracking_router import limiter
from app.modules.correspondence.public_tracking_service import (
    NOT_FOUND, TrackingRateLimiter, document_digest, normalize_document,
)
from tests.test_phase2_operational_documents import actor, body, headers


def route_actor(db, unit):
    return actor(db, unit, permissions=['correspondence.create'])


def route_body(db, employee, unit):
    payload = body(db, 'HOJA_RUTA', employee, unit)
    # Compatible with the committed issuance contract and the pending automatic PDF form.
    payload.update(emission_date='2026-11-06', emission_time='10:00:00', page_count=1)
    return payload

URL = '/public/correspondence/track'
SECRET = 'synthetic-public-tracking-test-key-32-plus'


@pytest.fixture(autouse=True)
def tracking_configuration(monkeypatch):
    monkeypatch.setattr(get_settings(), 'public_tracking_hmac_secret', SECRET)
    limiter.clients.clear()


@pytest.fixture()
def sheet(client, db, org_unit, second_org_unit):
    user, employee, _ = route_actor(db, org_unit)
    payload = route_body(db, employee, second_org_unit)
    payload.pop('origin_employee_id')
    payload.update(correspondence_type='EXTERNAL', sender_name='Juan Pérez Demo',
                   sender_document='12.345.678 CBBA', enable_public_tracking=True,
                   initial_instruction='PRIVATE instruction', description='PRIVATE content')
    response = client.post('/correspondences', headers=headers(user), json=payload)
    assert response.status_code == 201, response.text
    row = db.get(Correspondence, uuid.UUID(response.json()['id']))
    db.commit()  # End the fixture's earlier transaction before synthetic events.
    return row, user, payload


def track(client, number, document='12345678'):
    return client.post(URL, json=dict(route_sheet_number=number, document_number=document))


def test_public_success_without_jwt_and_safe_allowlist(client, db, sheet):
    row, _, _ = sheet
    response = track(client, row.route_number)
    assert response.status_code == 200
    value = response.json()
    assert value['found'] and value['route_sheet_number'] == row.route_number
    assert set(value) <= {'found', 'route_sheet_number', 'status', 'status_label', 'reference',
                          'received_at', 'current_unit', 'last_updated_at', 'movements'}
    assert [m['label'] for m in value['movements']] == ['Recibido', 'Derivado']
    for movement in value['movements']:
        assert set(movement) <= {'date', 'status', 'label', 'unit'}
    assert 'PRIVATE' not in response.text and '12345678' not in response.text
    assert str(row.id) not in response.text
    assert row.origin_external_document_hash == document_digest('12345678', SECRET)
    assert row.origin_external_document_last4 == '5678'
    assert response.headers['cache-control'] == 'no-store'


@pytest.mark.parametrize('document', ['12.345.678 CBBA', ' 12345678 ', '12-345-678'])
def test_document_normalization(client, sheet, document):
    assert track(client, ' ' + sheet[0].route_number.lower() + ' ', document).json()['found']


@pytest.mark.parametrize('number,document', [
    ('HR-1900-999999', '12345678'), ('existing', '87654321'),
    ('existing', ''), ('existing', "' OR 1=1 --"), ('%' * 15, '12345678'),
    ('existing', '1' * 100), ('x' * 100, '12345678'),
])
def test_failures_indistinguishable_and_inputs_never_echoed(client, sheet, number, document):
    response = track(client, sheet[0].route_number if number == 'existing' else number, document)
    assert response.status_code == 200
    assert response.json() == NOT_FOUND


@pytest.mark.parametrize('change', ['legacy', 'internal', 'other_behavior', 'deleted'])
def test_tracking_requires_eligible_external_route(client, db, sheet, change):
    row, _, _ = sheet
    if change == 'legacy': row.origin_external_document_hash = None
    if change == 'internal': row.correspondence_type = 'INTERNAL'
    if change == 'other_behavior': row.document_snapshot = {'behavior': 'MEMORANDUM'}
    if change == 'deleted': row.is_active = False
    db.commit()
    assert track(client, row.route_number).json() == NOT_FOUND


@pytest.mark.parametrize('event,label', [('CONCLUDED', 'Concluido'), ('REOPENED', 'Reabierto')])
def test_public_lifecycle_and_hidden_events(client, db, sheet, event, label):
    row, user, _ = sheet
    db.add(CorrespondenceMovement(correspondence_id=row.id, sequence_number=100,
        movement_type=event, created_by_user_id=user.id, observation='PRIVATE', instruction='PRIVATE'))
    db.add(CorrespondenceMovement(correspondence_id=row.id, sequence_number=101,
        movement_type='ATTACHMENT_ADDED', created_by_user_id=user.id, observation='PRIVATE URL'))
    db.commit()
    value = track(client, row.route_number).json()
    assert value['status_label'] == label
    assert value['movements'][-1]['label'] == label
    assert 'PRIVATE' not in str(value)


def test_cancelled_derivation_not_in_public_timeline(client, db, sheet):
    from datetime import datetime, timezone
    row, _, _ = sheet
    event = db.scalar(select(CorrespondenceMovement).where(CorrespondenceMovement.correspondence_id == row.id,
        CorrespondenceMovement.movement_type == 'DERIVED'))
    event.cancelled_at = datetime.now(timezone.utc)
    db.commit()
    assert [m['label'] for m in track(client, row.route_number).json()['movements']] == ['Recibido']


def test_hmac_is_keyed_and_normalization():
    assert normalize_document('12.345.678 CBBA') == '12345678'
    assert document_digest('12345678', SECRET) == hmac.new(SECRET.encode(), b'12345678', hashlib.sha256).hexdigest()
    assert document_digest('12345678', SECRET) != hashlib.sha256(b'12345678').hexdigest()


def test_rate_limit_http(client):
    for _ in range(10): assert track(client, 'HR-1900-999999').status_code == 200
    assert track(client, 'HR-1900-999999').status_code == 429


def test_limiter_window_ip_isolation():
    clock = [0]
    rate = TrackingRateLimiter(limit=1, clock=lambda: clock[0])
    rate.check('a'); rate.check('b')
    with pytest.raises(HTTPException): rate.check('a')
    clock[0] = 61
    rate.check('a')


def test_missing_secret_fails_closed(client, monkeypatch):
    monkeypatch.setattr(get_settings(), 'public_tracking_hmac_secret', '')
    assert track(client, 'HR-1900-999999').status_code == 503


def test_distinct_sheets_cannot_share_identity_accidentally(client, db, sheet):
    row, user, payload = sheet
    payload['sender_document'] = '87654321'
    response = client.post('/correspondences', headers=headers(user), json=payload)
    assert response.status_code == 201, response.text
    assert track(client, response.json()['route_number']).json() == NOT_FOUND
    assert track(client, row.route_number).json()['found']


@pytest.mark.parametrize('document', ['', '---', 'a'])
def test_opt_in_requires_valid_document(client, sheet, document):
    _, user, payload = sheet
    payload['sender_document'] = document
    response = client.post('/correspondences', headers=headers(user), json=payload)
    assert response.status_code == 422


def test_internal_route_cannot_enable_public_tracking(client, db, org_unit, second_org_unit):
    user, employee, _ = route_actor(db, org_unit)
    payload = route_body(db, employee, second_org_unit)
    payload.update(sender_document='12345678', enable_public_tracking=True)
    assert client.post('/correspondences', headers=headers(user), json=payload).status_code == 422
