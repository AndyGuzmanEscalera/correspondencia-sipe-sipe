"""Additional pre-demo HTTP checks; run only against a disposable database."""

from io import BytesIO
import secrets
import uuid

import pytest
from pypdf import PdfReader
from sqlalchemy import delete, select

from app.modules.identity.permission import Permission
from app.modules.identity.user_permission import UserPermission
from app.modules.identity.role import Role
from app.modules.identity.user_role import UserRole
from app.modules.correspondence.document_type import DocumentType
from tests.test_phase1_authorization import superadmin
from tests.test_phase2_operational_documents import actor, body, headers


@pytest.fixture(autouse=True)
def restore_operational_catalog_for_smoke(db):
    # Other suites deliberately deactivate structural types and preserve that state.
    # This smoke models a fresh active catalog, restoring previous values afterward.
    rows = list(db.scalars(select(DocumentType).where(DocumentType.is_operational.is_(True))))
    previous = [(row, row.is_active) for row in rows]
    for row, _ in previous:
        row.is_active = True
    db.commit()
    try:
        yield
    finally:
        for row, active in previous:
            row.is_active = active
        db.commit()


def test_password_login_change_and_omitted_password_preserves_hash(
    client, admin_headers, org_unit, position
):
    employee = client.post('/admin/employees', headers=admin_headers, json={
        'first_name': 'Demo', 'last_name': 'Temporal',
        'document_number': 'DOC' + uuid.uuid4().hex[:8],
        'unit_id': str(org_unit.id), 'position_id': str(position.id),
    })
    assert employee.status_code == 201, employee.text
    initial, replacement = secrets.token_urlsafe(20), secrets.token_urlsafe(20)
    username = 'demo_' + uuid.uuid4().hex[:15]
    request = {'username': username, 'employee_id': employee.json()['id']}
    created = client.post('/admin/users', headers=admin_headers,
                          json={**request, 'initial_password': initial})
    assert created.status_code == 201
    path = '/admin/users/' + created.json()['id']
    assert client.post('/auth/login', json={
        'username': username, 'password': initial}).status_code == 200
    changed = client.put(path, headers=admin_headers,
                         json={**request, 'new_password': replacement})
    assert changed.status_code == 200
    assert not {'password', 'password_hash', 'new_password'} & changed.json().keys()
    assert client.post('/auth/login', json={
        'username': username, 'password': initial}).status_code == 401
    assert client.post('/auth/login', json={
        'username': username, 'password': replacement}).status_code == 200
    assert client.put(path, headers=admin_headers, json=request).status_code == 200
    assert client.post('/auth/login', json={
        'username': username, 'password': replacement}).status_code == 200


def test_operator_direct_permissions_persist_and_me_has_no_extra_grants(
    client, db, superadmin, org_unit
):
    user, _, _ = actor(db, org_unit, permissions=[])
    db.execute(delete(UserPermission).where(UserPermission.user_id == user.id))
    role = db.scalar(select(Role).where(Role.code == 'OPERADOR'))
    assert role is not None
    db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()
    assert client.get('/auth/me', headers=headers(user)).json()['permissions'] == []
    assert client.get('/reports', headers=headers(user)).status_code == 403
    assert client.get('/admin/users', headers=headers(user)).status_code == 403
    codes = {'correspondence.read.unit', 'reports.view', 'correspondence.derive'}
    ids = list(db.scalars(select(Permission.id).where(Permission.code.in_(codes))))
    assert len(ids) == len(codes)
    response = client.put('/admin/users/' + str(user.id) + '/permissions',
                          headers=headers(superadmin),
                          json={'permission_ids': [str(value) for value in ids]})
    assert response.status_code == 200
    assert set(client.get('/auth/me', headers=headers(user)).json()['permissions']) == codes
    assert len(list(db.scalars(select(UserPermission).where(
        UserPermission.user_id == user.id)))) == 3
    assert client.get('/reports', headers=headers(user)).status_code == 200
    assert client.get('/admin/users', headers=headers(user)).status_code == 403


@pytest.mark.parametrize('code', [
    'HOJA_RUTA', 'COMUNICADO_INTERNO', 'INFORME', 'MEMORANDUM', 'CIRCULAR'
])
def test_five_real_pdf_files(client, db, org_unit, second_org_unit, code, tmp_path):
    permissions = [
        'correspondence.create', 'correspondence.create.internal_communication',
        'correspondence.create.report', 'correspondence.create.memorandum',
        'correspondence.create.circular',
    ]
    user, employee, _ = actor(db, org_unit, 'DIRECTOR', permissions=permissions)
    payload = body(db, code, employee, second_org_unit)
    if code == 'HOJA_RUTA':
        payload.update(emission_date='2026-11-05', emission_time='10:20:30', page_count=2)
    response = client.post('/correspondences', headers=headers(user), json=payload)
    assert response.status_code == 201, response.text
    document = response.json()
    pdf = client.get('/correspondences/' + document['id'] + '/document.pdf',
                     headers=headers(user))
    assert pdf.status_code == 200
    assert pdf.headers['content-type'].startswith('application/pdf')
    assert len(pdf.content) > 1000 and pdf.content.startswith(b'%PDF-')
    text = '\n'.join(page.extract_text() for page in PdfReader(BytesIO(pdf.content)).pages)
    assert payload['reference'] in text and 'Contenido' in text
    artifact = tmp_path / (code + '.pdf')
    artifact.write_bytes(pdf.content)
    assert artifact.stat().st_size == len(pdf.content)


@pytest.mark.parametrize('field', [
    'cite', 'route_number', 'subject', 'reference', 'description',
    'origin_employee', 'destination_user', 'origin_unit', 'destination_unit'
])
def test_real_search_fields_and_unrelated_reader_isolation(
    client, db, org_unit, second_org_unit, field
):
    from app.modules.correspondence.correspondence import Correspondence
    creator, employee, _ = actor(db, org_unit, permissions=['correspondence.create.report'])
    receiver, recipient, _ = actor(db, second_org_unit, permissions=[])
    outsider, _, _ = actor(db, second_org_unit, permissions=[])
    payload = body(db, 'INFORME', employee, second_org_unit)
    payload['initial_to_user_id'] = str(receiver.id)
    marker = 'demo' + uuid.uuid4().hex
    if field in {'subject', 'reference', 'description', 'cite'}:
        payload[field] = marker
    elif field == 'origin_employee':
        employee.first_name = marker
    elif field == 'destination_user':
        recipient.first_name = marker
    elif field == 'origin_unit':
        org_unit.name = marker
    elif field == 'destination_unit':
        second_org_unit.name = marker
    db.commit()
    response = client.post('/correspondences', headers=headers(creator), json=payload)
    assert response.status_code == 201
    document = response.json()
    if field == 'cite':
        # CITE is historical persisted data, not an editable operational create field.
        db.get(Correspondence, uuid.UUID(document['id'])).cite = marker
        db.commit()
    if field == 'route_number':
        marker = document[field]
        assert marker
    for endpoint, viewer, params in [
        ('/correspondences/sent', creator, {}),
        ('/correspondences/inbox', receiver, {'scope': 'mine'}),
    ]:
        found = client.get(endpoint, headers=headers(viewer), params={**params, 'search': marker})
        assert found.status_code == 200
        assert document['id'] in {item['id'] for item in found.json()['items']}
    hidden = client.get('/correspondences/inbox', headers=headers(outsider),
                        params={'scope': 'mine', 'search': marker})
    assert hidden.status_code == 200
    assert document['id'] not in {item['id'] for item in hidden.json()['items']}
