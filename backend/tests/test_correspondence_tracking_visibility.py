"""Seguimiento personal permanece tras derivar, sin otorgar control operativo."""
import uuid

import pytest
from sqlalchemy import func, select

from app.core.security import create_access_token
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_attachment import CorrespondenceAttachment
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from tests.test_correspondence import _create_payload
from tests.visibility_helpers import unit_reader_headers


@pytest.mark.parametrize('flag', [False, True])
@pytest.mark.parametrize('relation', ['creator', 'deriver'])
def test_tracking_survives_transfer_without_granting_mutations(
        client, db, auth_headers, user, position, org_unit,
        second_org_unit, second_user, encadenamiento_document_type, flag, relation):
    position.can_view_unit_correspondence = flag
    db.commit()
    creator_headers = {'Authorization': 'Bearer ' + create_access_token(second_user.id)[0]}
    created = client.post('/correspondences',
        headers=auth_headers if relation == 'creator' else creator_headers,
        json=_create_payload(encadenamiento_document_type, 'Seguimiento A a B',
                             unit_id=org_unit.id, user_id=user.id))
    assert created.status_code == 201, created.text
    path = '/correspondences/' + created.json()['id']
    uploaded = client.post(path + '/attachments', headers=auth_headers,
        files={'file': ('tracking.pdf', b'%PDF-1.4 tracking', 'application/pdf')})
    assert uploaded.status_code == 201, uploaded.text
    attachment_id = uploaded.json()['id']
    transfer = client.post(path + '/derive', headers=auth_headers,
        json={'to_unit_id': str(second_org_unit.id), 'to_user_id': str(second_user.id)})
    assert transfer.status_code == 200, transfer.text

    mine = client.get('/correspondences/inbox', headers=auth_headers,
                      params={'scope': 'mine'}).json()
    assert created.json()['id'] not in {item['id'] for item in mine['items']}
    unit = client.get('/correspondences/inbox', headers=auth_headers,
                      params={'scope': 'unit'})
    assert unit.status_code == (200 if flag else 403)
    if flag:
        assert created.json()['id'] not in {item['id'] for item in unit.json()['items']}
    counts = client.get('/correspondences/inbox/counts', headers=auth_headers).json()
    assert counts['mine'] == counts['unit'] == 0
    assert created.json()['id'] not in {item['id'] for item in
        client.get('/correspondences', headers=auth_headers).json()['items']}
    sent = client.get('/correspondences/sent', headers=auth_headers).json()
    assert sent['total'] == 1
    assert sent['items'][0]['id'] == created.json()['id']
    assert client.get('/correspondences/sent/count', headers=auth_headers).json()['total'] == 1
    detail = client.get(path, headers=auth_headers)
    assert detail.status_code == 200
    assert detail.json()['current_unit_id'] == str(second_org_unit.id)
    assert detail.json()['current_user_id'] == str(second_user.id)
    history = client.get(path + '/movements', headers=auth_headers)
    assert history.status_code == 200
    assert history.json()[-1]['movement_type'] == 'DERIVED'
    pdf = client.get(path + '/encadenamiento.pdf', headers=auth_headers)
    assert pdf.status_code == 200 and pdf.content.startswith(b'%PDF')
    assert client.get(path + '/attachments', headers=auth_headers).status_code == 200
    download = path + '/attachments/' + attachment_id + '/download'
    downloaded = client.get(download, headers=auth_headers)
    assert downloaded.status_code == 200 and downloaded.content == b'%PDF-1.4 tracking'

    # Un compañero, incluso con el mismo flag true, no hereda nuestra relación.
    bystander_employee = Employee(first_name='Sin', last_name='Relacion',
        unit_id=org_unit.id, position_id=position.id, is_active=True)
    db.add(bystander_employee)
    db.flush()
    bystander = User(username='tracking_' + uuid.uuid4().hex, employee_id=bystander_employee.id,
                     password_hash='not-a-login-account', is_active=True)
    db.add(bystander)
    db.commit()
    unrelated_headers = {'Authorization': 'Bearer ' + create_access_token(bystander.id)[0]}
    for suffix in ['', '/movements', '/encadenamiento.pdf', '/attachments',
                   '/attachments/' + attachment_id + '/download']:
        assert client.get(path + suffix, headers=unrelated_headers).status_code == 404
    assert client.get('/correspondences/sent', headers=unrelated_headers).json()['total'] == 0

    for action, body in [('derive', {'to_unit_id': str(org_unit.id), 'to_user_id': str(user.id)}),
                         ('conclude', {})]:
        assert client.post(path + '/' + action, headers=auth_headers, json=body).status_code == 403
    assert client.post(path + '/attachments', headers=auth_headers,
        files={'file': ('forbidden.pdf', b'%PDF forbidden', 'application/pdf')}).status_code == 403
    assert client.delete(path + '/attachments/' + attachment_id, headers=auth_headers).status_code == 403
    receiver_headers = {'Authorization': 'Bearer ' + create_access_token(second_user.id)[0]}
    assert client.post(path + '/conclude', headers=receiver_headers, json={}).status_code == 200
    assert client.post(path + '/reopen', headers=auth_headers, json={}).status_code == 403
    assert client.get(path, headers=auth_headers).status_code == 200
    db.expire_all()
    row = db.get(Correspondence, uuid.UUID(created.json()['id']))
    assert row.current_unit_id == second_org_unit.id and row.current_user_id == second_user.id
    assert row.status == 'CONCLUDED'
    assert db.get(CorrespondenceAttachment, uuid.UUID(attachment_id)).is_active
    assert db.scalar(select(func.count()).select_from(CorrespondenceMovement).where(
        CorrespondenceMovement.correspondence_id == row.id)) == len(history.json()) + 1


@pytest.mark.parametrize('flag', [False, True])
def test_former_recipient_or_unit_does_not_grant_personal_tracking(
        client, db, auth_headers, user, position, org_unit, second_org_unit,
        second_user, document_type, flag):
    position.can_view_unit_correspondence = flag
    db.commit()
    sender_headers = unit_reader_headers(db, org_unit.id)
    created = client.post('/correspondences', headers=sender_headers,
        json=_create_payload(document_type, 'Recibido sin autoría',
                             unit_id=org_unit.id, user_id=user.id))
    assert created.status_code == 201, created.text
    path = '/correspondences/' + created.json()['id']
    assert client.get(path, headers=auth_headers).status_code == 200
    transfer = client.post(path + '/derive', headers=sender_headers,
        json={'to_unit_id': str(second_org_unit.id), 'to_user_id': str(second_user.id)})
    assert transfer.status_code == 200, transfer.text
    for suffix in ['', '/movements', '/attachments']:
        assert client.get(path + suffix, headers=auth_headers).status_code == 404
    assert client.get('/correspondences/sent', headers=auth_headers).json()['total'] == 0
