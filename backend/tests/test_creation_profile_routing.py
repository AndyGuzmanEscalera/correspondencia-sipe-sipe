import json
import uuid
import pytest
from sqlalchemy import select,func
from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.creation_policy import INTAKE_UNIT_KEY,INITIAL_RECIPIENTS_KEY
from app.modules.system.system_setting import SystemSetting

@pytest.mark.parametrize('profile',['EDIE','INFORME','NOTA','GENERIC_QA'])
@pytest.mark.parametrize('intake',[True,False])
@pytest.mark.parametrize('receiver',['valid','missing','invalid','unconfigured','empty'])
def test_profile_intake_receiver_matrix(client,db,user,auth_headers,employee,org_unit,
        second_org_unit,second_user,mayor_user,profile,intake,receiver):
    keys=[INTAKE_UNIT_KEY,INITIAL_RECIPIENTS_KEY]
    rows=[db.get(SystemSetting,key) for key in keys]
    old=[row.value for row in rows]
    rows[0].value=str(org_unit.id if intake else second_org_unit.id)
    rows[1].value=json.dumps([] if receiver=='empty' else [str(mayor_user.employee_id)])
    kind=db.scalar(select(DocumentType).where(DocumentType.code==profile))
    if kind is None:
        kind=DocumentType(code=profile,name=profile,is_active=True);db.add(kind)
    db.commit()
    before=db.scalar(select(func.count()).select_from(Correspondence))
    try:
        payload=dict(correspondence_type='INTERNAL',document_type_id=str(kind.id),
            origin_employee_id=str(employee.id),subject='Matriz QA',description='Contenido',priority='LOW')
        if receiver in {'valid','invalid','unconfigured'}:
            payload['first_recipient_employee_id']=str(mayor_user.employee_id if receiver=='valid'
                else second_user.employee_id if receiver=='unconfigured' else uuid.uuid4())
        else:
            payload.update(initial_to_unit_id=str(second_org_unit.id),initial_to_user_id=str(second_user.id))
        response=client.post('/correspondences',headers=auth_headers,json=payload)
        accepted=receiver=='valid' or (not intake and receiver in {'missing','empty'})
        assert response.status_code==(201 if accepted else 422),response.text
        if accepted:
            value=response.json();doc_id=uuid.UUID(value['id'])
            moves=db.scalars(select(CorrespondenceMovement).where(CorrespondenceMovement.correspondence_id==doc_id)
                .order_by(CorrespondenceMovement.sequence_number)).all()
            assert [row.movement_type for row in moves]==['CREATED','DERIVED']
            assert value['current_unit_id']==str(moves[-1].to_unit_id)
            assert value['current_user_id']==str(moves[-1].to_user_id)
        else:
            assert db.scalar(select(func.count()).select_from(Correspondence))==before
            if receiver=='empty': assert 'No hay receptores iniciales activos configurados' in response.text
    finally:
        for row,value in zip(rows,old): row.value=value
        db.commit()
