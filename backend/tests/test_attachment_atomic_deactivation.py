import uuid
import pytest
from fastapi import HTTPException
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.attachment_service import CorrespondenceAttachmentService
from tests.test_correspondence import _create_payload

@pytest.mark.parametrize('operation,status',[('derive',403),('conclude',422)])
def test_deactivation_refreshes_cached_assignment_and_status(client,db,user,auth_headers,
        org_unit,second_org_unit,second_user,document_type,operation,status):
    result=client.post('/correspondences',headers=auth_headers,json=_create_payload(document_type,
        'Adjunto atómico',unit_id=org_unit.id,user_id=user.id))
    assert result.status_code==201,result.text
    doc_id=uuid.UUID(result.json()['id']);path='/correspondences/'+str(doc_id)
    result=client.post(path+'/attachments',headers=auth_headers,files={'file':('qa.pdf',b'%PDF qa','application/pdf')})
    assert result.status_code==201,result.text
    attachment_id=uuid.UUID(result.json()['id'])
    cached=db.get(Correspondence,doc_id)
    assert cached.current_user_id==user.id and cached.status=='ACTIVE'
    body={'to_unit_id':str(second_org_unit.id),'to_user_id':str(second_user.id)} if operation=='derive' else {}
    assert client.post(path+'/'+operation,headers=auth_headers,json=body).status_code==200
    with pytest.raises(HTTPException) as error:
        CorrespondenceAttachmentService(db).deactivate_attachment(user,doc_id,attachment_id)
    assert error.value.status_code==status
    db.rollback()
    attachments=client.get(path+'/attachments',headers=auth_headers)
    assert attachments.status_code==200 and any(a['id']==str(attachment_id) for a in attachments.json())
