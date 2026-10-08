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
    return {'Authorization': 'Bearer ' + create_access_token(user.id)[0]}
