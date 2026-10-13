"""La baja de cargos no debe leer columnas ajenas a sus dependencias."""
import uuid
from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.common import master_data_deletion
from app.common.master_data_deletion import validate_deletion
from app.modules.correspondence import creation_policy


@pytest.fixture(autouse=True)
def seed_institutional_mayor():
    # Esta regresión usa SQLite aislado; no necesita el seed PostgreSQL global.
    pass


@pytest.mark.parametrize('configured,active,authority', [
    (False, False, False), (True, False, False), (False, True, False), (False, False, True),
])
def test_position_delete_without_optional_employee_columns(monkeypatch, configured, active, authority):
    employee_id, position_id, unit_id = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    monkeypatch.setattr(creation_policy, 'configured_creation_ids',
                        lambda db: (None, [employee_id] if configured else []))
    monkeypatch.setattr(master_data_deletion, '_configured_employee',
                        lambda db: employee_id if authority else None)
    engine = create_engine('sqlite://')
    try:
        with engine.begin() as connection:
            connection.execute(text('CREATE TABLE employees (id TEXT PRIMARY KEY, '
                                    'unit_id TEXT, position_id TEXT, is_active BOOLEAN)'))
            connection.execute(text('INSERT INTO employees VALUES (:id, :unit, :position, :active)'),
                               dict(id=employee_id.hex, unit=unit_id.hex,
                                    position=position_id.hex, active=active))
        with Session(engine) as session:
            row = SimpleNamespace(id=position_id)
            if configured or active or authority:
                with pytest.raises(HTTPException) as error:
                    validate_deletion(session, 'positions', row)
                assert error.value.status_code == 409
                expected = 'receptor inicial' if configured else ('autoridad institucional' if authority else 'funcionarios activos')
                assert expected in error.value.detail
            else:
                validate_deletion(session, 'positions', row)
    finally:
        engine.dispose()
