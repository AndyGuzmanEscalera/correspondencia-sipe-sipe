"""Actores explícitos para probar histórico con lectura autorizada de unidad."""
import uuid
from app.core.security import create_access_token
from app.modules.organization.position import Position
from app.modules.organization.employee import Employee
from app.modules.identity.user import User


def unit_reader_headers(db, unit_id):
    position=Position(code='READER_' + uuid.uuid4().hex[:8], name='Lector histórico',
                      can_view_unit_correspondence=True, is_active=True)
    db.add(position)
    db.flush()
    employee=Employee(first_name='Lector', last_name='Histórico', position_id=position.id,
                      unit_id=unit_id, is_active=True)
    db.add(employee)
    db.flush()
    user=User(username='reader_' + uuid.uuid4().hex, password_hash='not-a-login-account',
              employee_id=employee.id, is_active=True)
    db.add(user)
    db.commit()
    grant_creation_permission(db,user)
    return {'Authorization': 'Bearer ' + create_access_token(user.id)[0]}


def grant_creation_permission(db, user):
    from sqlalchemy import select
    from app.modules.identity.role import Role
    from app.modules.identity.permission import Permission
    from app.modules.identity.role_permission import RolePermission
    from app.modules.identity.user_role import UserRole
    permission=db.scalar(select(Permission).where(Permission.code=="correspondence.create"))
    if permission is None:
        permission=Permission(code="correspondence.create");db.add(permission);db.flush()
    role=Role(code="CREATE_TEST_"+uuid.uuid4().hex,name="Creación explícita de prueba",is_active=True)
    db.add(role);db.flush()
    db.add(RolePermission(role_id=role.id,permission_id=permission.id))
    db.add(UserRole(user_id=user.id,role_id=role.id));db.commit()


def route_to(client, created, unit_id, user_id):
    if created["current_unit_id"]==str(unit_id) and created["current_user_id"]==str(user_id):
        return created
    headers={"Authorization":"Bearer "+create_access_token(uuid.UUID(created["current_user_id"]))[0]}
    response=client.post("/correspondences/"+created["id"]+"/derive",headers=headers,
        json={"to_unit_id":str(unit_id),"to_user_id":str(user_id)})
    assert response.status_code==200,response.text
    return response.json()
