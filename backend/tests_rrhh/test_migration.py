import runpy
import uuid
from pathlib import Path

from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import inspect, text
from .conftest import test_engine


def test_frozen_migration_upgrade_downgrade_and_admin_grants():
    migration_path = Path(__file__).resolve().parents[1] / "alembic/versions/h1b2c3d4e5f6_rrhh_biometric.py"
    migration = runpy.run_path(str(migration_path))
    # Separate transactional schema: never collide with ORM-created suite tables.
    schema = "rrhh_migration_" + uuid.uuid4().hex
    with test_engine.connect() as connection:
        transaction = connection.begin()
        try:
            connection.execute(text(f'CREATE SCHEMA "{schema}"'))
            connection.execute(text(f'SET LOCAL search_path TO "{schema}"'))
            for ddl in (
                "CREATE TABLE employees (id uuid PRIMARY KEY)",
                "CREATE TABLE users (id uuid PRIMARY KEY)",
                "CREATE TABLE permissions (id uuid PRIMARY KEY, code text UNIQUE, description text)",
                "CREATE TABLE roles (id uuid PRIMARY KEY, code text UNIQUE, is_active boolean)",
                "CREATE TABLE role_permissions (role_id uuid, permission_id uuid, PRIMARY KEY(role_id,permission_id))",
            ):
                connection.execute(text(ddl))
            connection.execute(text("INSERT INTO roles VALUES (:id,'ADMIN',true)"), {"id": uuid.uuid4()})
            with Operations.context(MigrationContext.configure(connection)):
                migration["upgrade"]()
                tables = inspect(connection).get_table_names(schema=schema)
                assert "biometric_records" in tables and "attendance_contract_policies" in tables
                assert connection.scalar(text("SELECT count(*) FROM role_permissions")) == 2
                assert connection.scalar(text("SELECT count(*) FROM attendance_contract_policies")) == 0
                column = next(c for c in inspect(connection).get_columns("biometric_records", schema=schema)
                              if c["name"] == "timestamp")
                assert column["type"].timezone is False
                migration["downgrade"]()
                assert "biometric_records" not in inspect(connection).get_table_names(schema=schema)
        finally:
            transaction.rollback()
