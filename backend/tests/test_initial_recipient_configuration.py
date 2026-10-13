import uuid
import pytest
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.organization.organizational_unit import OrganizationalUnit
from tests.test_system_settings import _grant_system_settings

@pytest.mark.parametrize('inactive',['employee','position','unit','user'])
def test_rejects_inactive_receiver_before_saving(client,db,admin_user,admin_headers,mayor_user,inactive):
    _grant_system_settings(db,admin_user)
    employee=db.get(Employee,mayor_user.employee_id)
    row={'employee':employee,'position':db.get(Position,employee.position_id),
         'unit':db.get(OrganizationalUnit,employee.unit_id),'user':mayor_user}[inactive]
    previous=row.is_active;row.is_active=False;db.commit()
    try:
        response=client.put('/admin/system-settings/institutional',headers=admin_headers,
            json={'initial_recipient_employee_ids':[str(employee.id)]})
        assert response.status_code==422,response.text
    finally:
        row.is_active=previous;db.commit()

def test_save_two_receivers_and_catalog(client,db,admin_user,admin_headers,mayor_user,second_user):
    _grant_system_settings(db,admin_user)
    ids=[str(mayor_user.employee_id),str(second_user.employee_id)]
    response=client.put('/admin/system-settings/institutional',headers=admin_headers,
        json={'initial_recipient_employee_ids':ids})
    assert response.status_code==200,response.text
    assert response.json()['initial_recipient_employee_ids']==ids
    response=client.get('/edie-first-recipients',headers=admin_headers)
    assert response.status_code==200
    assert {x['employee_id'] for x in response.json()}==set(ids)
