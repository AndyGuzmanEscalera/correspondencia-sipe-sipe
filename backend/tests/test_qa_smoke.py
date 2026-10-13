"""Smoke integrado del núcleo: configuración, permisos y ownership reales."""
import uuid
from sqlalchemy import select
from app.core.security import create_access_token
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position
from app.modules.correspondence.correspondence import Correspondence
from app.modules.system.system_setting import SystemSetting
from tests.test_system_settings import _grant_system_settings
from tests.test_correspondence import _create_payload


def token(user):
    return {"Authorization":"Bearer "+create_access_token(user.id)[0]}


def test_complete_correspondence_smoke(client,db,user,auth_headers,employee,position,org_unit,second_user,second_org_unit,document_type,encadenamiento_document_type,mayor_user,admin_headers):
    login=client.post('/auth/login',json={'username':user.username,'password':'TestPass123!'})
    assert login.status_code==200,login.text
    session_headers={'Authorization':'Bearer '+login.json()['access_token']}
    assert client.get('/auth/me',headers=session_headers).status_code==200
    assert client.post('/auth/refresh').status_code==200
    policy=client.get('/correspondence-creation-policy',headers=session_headers)
    assert policy.status_code==200 and policy.json()['is_intake'] is False
    created=client.post('/correspondences',headers=session_headers,json=_create_payload(encadenamiento_document_type,'QA: <revisión> & "mañana" – Ñ',unit_id=second_org_unit.id))
    assert created.status_code==201,created.text
    path='/correspondences/'+created.json()['id'];owner=token(mayor_user)
    assert [m['movement_type'] for m in client.get(path+'/movements',headers=owner).json()]==['CREATED','DERIVED']
    assert client.get(path,headers=session_headers).json()['can_operate'] is False
    assert created.json()['id'] in {d['id'] for d in client.get('/correspondences/inbox',headers=owner,params={'scope':'mine'}).json()['items']}
    assert client.get(path,headers=token(second_user)).status_code==404
    assert client.post(path+'/conclude',headers=session_headers,json={}).status_code==403
    upload=client.post(path+'/attachments',headers=owner,files={'file':('revisión.pdf',b'%PDF smoke','application/pdf')})
    assert upload.status_code==201,upload.text
    attachment=upload.json()['id']
    transfer=client.post(path+'/derive',headers=owner,json={'to_unit_id':str(second_org_unit.id),'to_user_id':str(second_user.id)})
    assert transfer.status_code==200,transfer.text
    current=token(second_user)
    assert client.get(path,headers=current).json()['can_operate'] is True
    assert client.get(path,headers=owner).json()['can_operate'] is False
    assert created.json()['id'] in {d['id'] for d in client.get('/correspondences/sent',headers=session_headers).json()['items']}
    assert client.post(path+'/derive',headers=session_headers,json={'to_unit_id':str(org_unit.id)}).status_code==403
    assert client.post(path+'/attachments',headers=session_headers,files={'file':('no.pdf',b'%PDF','application/pdf')}).status_code==403
    assert client.delete(path+'/attachments/'+attachment,headers=owner).status_code==403
    pdf=client.get(path+'/encadenamiento.pdf',headers=session_headers)
    assert pdf.status_code==200 and pdf.content.startswith(b'%PDF')
    assert client.get(path+'/attachments/'+attachment+'/download',headers=session_headers).content==b'%PDF smoke'
    assert client.post(path+'/conclude',headers=current,json={}).status_code==200
    assert client.post(path+'/attachments',headers=current,files={'file':('closed.pdf',b'%PDF','application/pdf')}).status_code==422
    assert client.delete(path+'/attachments/'+attachment,headers=current).status_code==422
    assert client.post(path+'/reopen',headers=session_headers,json={}).status_code==403
    assert client.post(path+'/reopen',headers=current,json={}).status_code==200
    assert [m['movement_type'] for m in client.get(path+'/movements',headers=current).json()]==['CREATED','DERIVED','DERIVED','CONCLUDED','REOPENED']
    _grant_system_settings(db,user)
    row=db.get(Correspondence,uuid.UUID(created.json()['id']));snapshot=dict(row.institutional_authority_snapshot)
    assert client.put('/admin/system-settings/institutional',headers=session_headers,json={'mayor_display_name':'Autoridad QA futura'}).status_code==200
    db.expire(row);assert row.institutional_authority_snapshot==snapshot
    assert client.get(path+'/encadenamiento.pdf',headers=session_headers).content.startswith(b'%PDF')
    # Baja/restauración segura y bloqueo por dependencia, sin datos destructivos.
    unit=client.post('/admin/organizational-units',headers=admin_headers,json={'code':'QA_'+uuid.uuid4().hex[:12],'name':'Unidad QA temporal'})
    assert unit.status_code==201,unit.text
    unit_path='/admin/organizational-units/'+unit.json()['id']
    assert client.patch(unit_path+'/active',headers=admin_headers,json={'is_active':False}).status_code==200
    assert client.patch(unit_path+'/active',headers=admin_headers,json={'is_active':True}).status_code==200
    assert client.patch('/admin/organizational-units/'+str(second_org_unit.id)+'/active',headers=admin_headers,json={'is_active':False}).status_code==409
    assert client.patch('/admin/organizational-units/'+db.get(SystemSetting,'institutional.intake_unit_id').value+'/active',headers=admin_headers,json={'is_active':False}).status_code==409
    assert client.post('/auth/logout').status_code in (200,204)


def test_unit_only_and_specific_derivations_are_real_single_movements(client,db,user,auth_headers,org_unit,second_user,second_org_unit,position,document_type):
    result=client.post('/correspondences',headers=auth_headers,json=_create_payload(document_type,'Unidad y funcionario',unit_id=org_unit.id,user_id=user.id))
    assert result.status_code==201,result.text
    path='/correspondences/'+result.json()['id']
    assert client.post(path+'/derive',headers=auth_headers,json={'to_unit_id':str(second_org_unit.id)}).json()['current_user_id'] is None
    position.can_view_unit_correspondence=True;db.commit()
    receiver=token(second_user)
    assert client.get(path,headers=receiver).json()['can_operate'] is True
    derived=client.post(path+'/derive',headers=receiver,json={'to_unit_id':str(second_org_unit.id),'to_user_id':str(second_user.id)})
    assert derived.status_code==200,derived.text
    assert [m['movement_type'] for m in client.get(path+'/movements',headers=receiver).json()]==['CREATED','DERIVED','DERIVED','DERIVED']


def test_creation_permission_denies_unprivileged_actor_without_partial_records(client,db,document_type,org_unit,position):
    from sqlalchemy import func
    actor_employee=Employee(first_name='Sin',last_name='Permiso',unit_id=org_unit.id,position_id=position.id,is_active=True)
    db.add(actor_employee);db.flush()
    actor=User(username='qa_no_create_'+uuid.uuid4().hex,employee_id=actor_employee.id,password_hash='not-a-login-account',is_active=True)
    db.add(actor);db.commit()
    before=db.scalar(select(func.count()).select_from(Correspondence))
    assert client.post('/correspondences',headers=token(actor),json=_create_payload(document_type,'Prohibido',unit_id=org_unit.id)).status_code==403
    assert client.get('/correspondence-creation-policy',headers=token(actor)).status_code==403
    assert db.scalar(select(func.count()).select_from(Correspondence))==before
