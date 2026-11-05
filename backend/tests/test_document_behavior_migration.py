"""Migrations are exercised in newly created disposable databases, never the source DB."""

import json
import os
import subprocess
import sys
import uuid
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from app.core.config import get_settings

TARGET = "l1b2c3d4e5f6"


def upgrade(url, revision):
    env = {**os.environ, "DATABASE_URL": url.render_as_string(hide_password=False)}
    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", revision],
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )


def rows(connection, table):
    return (
        connection.execute(text("SELECT to_jsonb(t) FROM " + table + " t ORDER BY id"))
        .scalars()
        .all()
    )


@pytest.mark.parametrize("source", ["fresh", "k1", "history"])
def test_document_behavior_migration_in_disposable_database(source):
    source_url = make_url(get_settings().effective_database_url)
    isolated_name = "test_document_behavior_" + uuid.uuid4().hex
    # The only write to the connected server is CREATE DATABASE with a generated
    # test-only identifier. All migrations and fixture writes target that new DB.
    admin = create_engine(source_url, isolation_level="AUTOCOMMIT")
    with admin.connect() as connection:
        connection.execute(text('CREATE DATABASE "' + isolated_name + '"'))
    admin.dispose()
    url = source_url.set(database=isolated_name)
    engine = create_engine(url)
    historical = {}
    type_ids = {}
    if source != "fresh":
        upgrade(url, "k1b2c3d4e5f6")
    if source == "history":
        with engine.begin() as connection:
            user_id = uuid.uuid4()
            connection.execute(
                text(
                    """INSERT INTO users(id,username,password_hash,is_active)
                VALUES (:id,'synthetic_history','not-a-login',true)"""
                ),
                {"id": user_id},
            )
            for sequence, code in enumerate(["EDIE", "NOTA", "HOJA_RUTA", "CUSTOM"], 1):
                type_id = connection.scalar(
                    text("SELECT id FROM document_types WHERE code=:code"),
                    {"code": code},
                )
                document_id = uuid.uuid4()
                if type_id is None:
                    type_id = uuid.uuid4()
                    connection.execute(
                        text(
                            """INSERT INTO document_types(id,code,name,is_active,profile)
                        VALUES (:id,:code,:name,false,'GENERIC')"""
                        ),
                        {
                            "id": type_id,
                            "code": code,
                            "name": "Nombre histórico " + code,
                        },
                    )
                else:
                    connection.execute(
                        text(
                            "UPDATE document_types SET profile='GENERIC' WHERE id=:id"
                        ),
                        {"id": type_id},
                    )
                type_ids[code] = str(type_id)
                connection.execute(
                    text(
                        """INSERT INTO correspondences
                    (id,route_number,route_sequence,route_year,correspondence_type,
                     document_type_id,subject,priority,status,created_by_user_id,is_active,
                     institutional_authority_snapshot)
                    VALUES (:id,:route,:sequence,2020,'EXTERNAL',:kind,'Referencia histórica',
                            'LOW','ACTIVE',:actor,true,CAST(:snapshot AS jsonb))"""
                    ),
                    {
                        "id": document_id,
                        "route": "HR-2020-" + str(sequence),
                        "sequence": sequence,
                        "kind": type_id,
                        "actor": user_id,
                        "snapshot": json.dumps(
                            {"para_label": "Autoridad histórica", "version": 1}
                        ),
                    },
                )
                connection.execute(
                    text(
                        """INSERT INTO correspondence_movements
                    (id,correspondence_id,sequence_number,movement_type,created_by_user_id)
                    VALUES (:id,:document,1,'CREATED',:actor)"""
                    ),
                    {"id": uuid.uuid4(), "document": document_id, "actor": user_id},
                )
                connection.execute(
                    text(
                        """INSERT INTO correspondence_attachments
                    (id,correspondence_id,original_filename,is_active,created_by_user_id)
                    VALUES (:id,:document,'historico.pdf',true,:actor)"""
                    ),
                    {"id": uuid.uuid4(), "document": document_id, "actor": user_id},
                )
            for table in [
                "correspondences",
                "correspondence_movements",
                "correspondence_attachments",
                "users",
                "permissions",
            ]:
                historical[table] = rows(connection, table)
    upgrade(url, TARGET)
    with engine.connect() as connection:
        assert (
            connection.scalar(text("SELECT version_num FROM alembic_version")) == TARGET
        )
        assert not connection.scalar(text("SELECT to_regclass('biometric_devices')"))
        assert not connection.scalar(text("SELECT to_regclass('work_shifts')"))
        assert (
            connection.scalar(
                text("SELECT profile FROM document_types WHERE code='HOJA_RUTA'")
            )
            == "ROUTE_SHEET"
        )
        if source == "history":
            for table, before in historical.items():
                after = rows(connection, table)
                if table == "correspondences":
                    for row in after:
                        for field in ["emission_date", "emission_time", "page_count"]:
                            assert row.pop(field) is None
                assert after == before, table
            mapping = {
                row.code: (str(row.id), row.profile)
                for row in connection.execute(
                    text("SELECT id,code,profile FROM document_types")
                )
            }
            for code, expected in {
                "EDIE": "LEGACY_CHAINING",
                "NOTA": "LEGACY_INTERNAL_NOTE",
                "HOJA_RUTA": "ROUTE_SHEET",
                "CUSTOM": "GENERIC",
            }.items():
                assert mapping[code] == (type_ids[code], expected)
    engine.dispose()
