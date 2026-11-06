"""Independent token sessions: persisted delivery, reads and lifecycle events."""
import uuid
from sqlalchemy import select
from app.modules.notifications.notification import Notification
from tests.test_correspondence import _create_payload
from tests.test_final_blocks import headers, reader


def test_two_sessions_delivery_and_lifecycle(client, db, user, second_user,
        auth_headers, org_unit, second_org_unit, document_type):
    a_headers, b_headers = auth_headers, headers(second_user)
    assert a_headers['Authorization'] != b_headers['Authorization']
    observer, _, _ = reader(db, second_org_unit)
    baseline = client.get('/notifications/unread-count', headers=b_headers).json()['unread']
    created = client.post('/correspondences', headers=a_headers, json=_create_payload(
        document_type, 'Two sessions synthetic case', unit_id=org_unit.id, user_id=user.id))
    assert created.status_code == 201, created.text
    document = created.json()
    path = '/correspondences/' + document['id']
    derived = client.post(path + '/derive', headers=a_headers,
        json={'to_unit_id': str(second_org_unit.id), 'to_user_id': str(second_user.id)})
    assert derived.status_code == 200, derived.text
    polled = client.get('/notifications', headers=b_headers).json()
    assert polled['unread'] == baseline + 1
    notification = next(n for n in polled['items'] if n['correspondence_id'] == document['id'])
    assert notification['type'] == 'DERIVED' and not notification['is_read']
    # Repeated polls do not create delivery records.
    client.get('/notifications', headers=b_headers)
    rows = db.scalars(select(Notification).where(Notification.user_id == second_user.id,
        Notification.correspondence_id == uuid.UUID(document['id']))).all()
    assert len(rows) == 1
    assert client.post('/notifications/' + notification['id'] + '/read', headers=b_headers).json()['unread'] == baseline
    assert next(n for n in client.get('/notifications', headers=b_headers).json()['items']
        if n['id'] == notification['id'])['is_read']
    for operation, kind in [('conclude', 'CONCLUDED'), ('reopen', 'REOPENED')]:
        response = client.post(path + '/' + operation, headers=b_headers, json={})
        assert response.status_code == 200, response.text
        assert any(n['type'] == kind for n in client.get('/notifications', headers=headers(observer)).json()['items'])


def test_initial_assignment_is_persisted_for_destination(client, db, auth_headers,
        second_user, second_org_unit, document_type):
    created = client.post('/correspondences', headers=auth_headers,
        json=_create_payload(document_type, 'Initial delivery synthetic case',
            unit_id=second_org_unit.id, user_id=second_user.id))
    assert created.status_code == 201, created.text
    rows = db.scalars(select(Notification).where(Notification.user_id == second_user.id,
        Notification.correspondence_id == uuid.UUID(created.json()['id']))).all()
    assert len(rows) == 1 and rows[0].type == 'ASSIGNED'
