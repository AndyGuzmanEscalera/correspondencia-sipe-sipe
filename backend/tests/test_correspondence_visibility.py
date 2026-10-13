import uuid

import pytest
from sqlalchemy import select

from app.core.security import create_access_token
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.correspondence.correspondence import Correspondence
from tests.test_correspondence import _create_payload


@pytest.fixture()
def visibility_documents(client, db, user, employee, org_unit, second_org_unit,
                         second_user, document_type, auth_headers):
    position = db.get(Position, employee.position_id)
    position.can_view_unit_correspondence = False
    peer = db.get(Employee, second_user.employee_id)
    peer.unit_id = org_unit.id
    db.commit()
    creator_headers = {'Authorization': 'Bearer ' + create_access_token(second_user.id)[0]}
    def create(unit, target=None):
        response = client.post('/correspondences', headers=creator_headers, json=_create_payload(
            document_type, 'Visibilidad', unit_id=unit, user_id=target))
        assert response.status_code == 201, response.text
        return response.json()['id']
    documents = dict(own=create(org_unit.id, user.id), peer=create(org_unit.id, second_user.id),
                     unassigned=create(org_unit.id), other=create(second_org_unit.id))
    return position, documents


@pytest.mark.parametrize('flag', [False, True])
@pytest.mark.parametrize('kind', ['own', 'peer', 'unassigned', 'other'])
def test_read_scope_applies_to_direct_detail_and_history(
        client, db, auth_headers, visibility_documents, flag, kind):
    position, docs = visibility_documents
    position.can_view_unit_correspondence = flag
    # El nombre nunca autoriza: ambos extremos usan el mismo nombre arbitrario.
    position.name = 'Director Secretaria ADMIN'
    db.commit()
    permitted = kind == 'own' or (flag and kind in {'peer', 'unassigned'})
    for suffix in ['', '/movements', '/attachments']:
        result = client.get('/correspondences/' + docs[kind] + suffix, headers=auth_headers)
        assert result.status_code == (200 if permitted else 404), result.text
    if not permitted:
        assert client.get('/correspondences/' + docs[kind] + '/encadenamiento.pdf', headers=auth_headers).status_code == 404


@pytest.mark.parametrize('flag', [False, True])
def test_all_lists_sent_counts_and_unit_inbox_respect_scope(
        client, db, auth_headers, visibility_documents, flag):
    position, docs = visibility_documents
    position.can_view_unit_correspondence = flag
    db.commit()
    expected = {docs['own'], docs['peer'], docs['unassigned']} if flag else {docs['own']}
    for path in ['/correspondences']:
        result = client.get(path, headers=auth_headers)
        assert result.status_code == 200
        assert {item['id'] for item in result.json()['items']} == expected
    mine = client.get('/correspondences/inbox', headers=auth_headers, params={'scope':'mine'})
    assert {item['id'] for item in mine.json()['items']} == {docs['own']}
    unit = client.get('/correspondences/inbox', headers=auth_headers, params={'scope':'unit'})
    assert unit.status_code == (200 if flag else 403)
    if flag:
        assert {item['id'] for item in unit.json()['items']} == expected
    counts = client.get('/correspondences/inbox/counts', headers=auth_headers).json()
    assert counts['mine'] == 1
    assert counts['unit'] == (3 if flag else 0)
    assert counts['can_view_unit_correspondence'] is flag
    assert client.get('/correspondences/sent/count', headers=auth_headers).json()['total'] == 0
    assert client.get('/correspondences/sent', headers=auth_headers).json()['items'] == []


def test_attachment_download_and_revoke_flag_on_next_request(
        client, db, auth_headers, visibility_documents, second_user):
    position, docs = visibility_documents
    result = client.post('/correspondences/' + docs['peer'] + '/attachments', headers={'Authorization':'Bearer '+create_access_token(second_user.id)[0]},
        files={'file': ('scope.pdf', b'%PDF-1.4 scope test', 'application/pdf')})
    assert result.status_code == 201, result.text
    path = '/correspondences/' + docs['peer'] + '/attachments/' + result.json()['id'] + '/download'
    assert client.get(path, headers=auth_headers).status_code == 404
    position.can_view_unit_correspondence = True
    db.commit()
    assert client.get(path, headers=auth_headers).status_code == 200
    position.can_view_unit_correspondence = False
    db.commit()
    assert client.get(path, headers=auth_headers).status_code == 404


def test_change_position_changes_scope_without_changing_ownership(
        client, db, auth_headers, user, visibility_documents):
    original, docs = visibility_documents
    position = Position(code='SCOPE_' + uuid.uuid4().hex[:8], name='Cargo futuro',
                        can_view_unit_correspondence=True, is_active=True)
    db.add(position)
    db.flush()
    employee = db.get(Employee, user.employee_id)
    employee.position_id = position.id
    db.commit()
    assert client.get('/correspondences/' + docs['peer'], headers=auth_headers).status_code == 200
    employee.position_id = original.id
    db.commit()
    assert client.get('/correspondences/' + docs['peer'], headers=auth_headers).status_code == 404
    position.is_active = False
    employee.position_id = position.id
    db.commit()
    assert client.get('/correspondences/' + docs['own'], headers=auth_headers).status_code == 404


def test_position_crud_flag_defaults_false_and_update_omission_preserves_value(client, admin_headers):
    body={'code': 'SCOPE_' + uuid.uuid4().hex[:8], 'name': 'Director por nombre'}
    created=client.post('/admin/positions', headers=admin_headers, json=body)
    assert created.status_code == 201, created.text
    assert created.json()['can_view_unit_correspondence'] is False
    path='/admin/positions/' + created.json()['id']
    updated=client.put(path, headers=admin_headers, json={**body,'can_view_unit_correspondence':True})
    assert updated.json()['can_view_unit_correspondence'] is True
    assert client.put(path, headers=admin_headers, json=body).json()['can_view_unit_correspondence'] is True
    assert client.get(path, headers=admin_headers).json()['can_view_unit_correspondence'] is True
    assert client.put(path, headers=admin_headers, json={**body,'can_view_unit_correspondence':False}).json()['can_view_unit_correspondence'] is False


@pytest.mark.parametrize('flag',[False,True])
def test_reader_scope_does_not_authorize_mutating_another_active_owner(client,db,auth_headers,visibility_documents,flag,org_unit):
    position,docs=visibility_documents;position.can_view_unit_correspondence=flag;db.commit()
    path='/correspondences/'+docs['peer']
    assert client.post(path+'/derive',headers=auth_headers,json={'to_unit_id':str(org_unit.id)}).status_code==403
    assert client.post(path+'/conclude',headers=auth_headers,json={}).status_code==403
    assert client.post(path+'/attachments',headers=auth_headers,files={'file':('blocked.pdf',b'%PDF','application/pdf')}).status_code==403
