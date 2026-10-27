"""Public HTTP contracts for phase 2, plus independent historical fixtures."""

import copy
import importlib.util
import uuid
from io import BytesIO
from pathlib import Path
import pytest
from pypdf import PdfReader
from sqlalchemy import select, func
from app.core.security import create_access_token
from app.modules.identity.user import User
from app.modules.identity.user_permission import UserPermission
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.user_role import UserRole
from app.modules.identity.rbac_service import RbacService
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.organization.position_hierarchy import PositionHierarchy
from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.document_type_profiles import OPERATIONAL_DOCUMENTS
from tests.historical_documents import seed_historical_document
from tests.test_correspondence import _create_payload


def headers(actor):
    return {"Authorization": "Bearer " + create_access_token(actor.id)[0]}


def actor(db, unit, rank="FUNCIONARIO", permissions=None):
    hierarchy = (
        db.scalar(select(PositionHierarchy).where(PositionHierarchy.code == rank))
        if rank
        else None
    )
    position = Position(
        code="P2_" + uuid.uuid4().hex[:12],
        name="Cargo sin nombre jerárquico",
        hierarchy_id=hierarchy.id if hierarchy else None,
        is_active=True,
    )
    db.add(position)
    db.flush()
    employee = Employee(
        first_name="Actor",
        last_name=uuid.uuid4().hex[:8],
        position_id=position.id,
        unit_id=unit.id,
        is_active=True,
    )
    db.add(employee)
    db.flush()
    user = User(
        username="phase2_" + uuid.uuid4().hex,
        employee_id=employee.id,
        password_hash="not-for-login",
        is_active=True,
    )
    db.add(user)
    db.flush()
    codes = (
        permissions
        if permissions is not None
        else [spec[2] for spec in OPERATIONAL_DOCUMENTS.values()]
    )
    codes = set(codes) | {
        "correspondence.read.own",
        "correspondence.derive",
        "correspondence.conclude",
        "correspondence.reopen",
        "correspondence.attachments.manage",
    }
    for code in codes:
        permission = db.scalar(select(Permission).where(Permission.code == code))
        assert permission is not None
        db.add(UserPermission(user_id=user.id, permission_id=permission.id))
    db.commit()
    return user, employee, position


def kind(db, code):
    return db.scalar(select(DocumentType).where(DocumentType.code == code))


def body(db, code, origin, unit):
    return dict(
        correspondence_type="INTERNAL",
        document_type_id=str(kind(db, code).id),
        subject="Asunto institucional",
        reference="REF-2026",
        description="Contenido <seguro> & completo.",
        origin_employee_id=str(origin.id),
        initial_to_unit_id=str(unit.id),
        priority="MEDIUM",
    )


@pytest.mark.parametrize(
    "rank,level",
    [
        ("FUNCIONARIO", 1),
        ("RESPONSABLE", 2),
        ("JEFE", 3),
        ("DIRECTOR", 4),
        ("SECRETARIO", 5),
        ("ALCALDE", 6),
    ],
)
@pytest.mark.parametrize(
    "code,minimum",
    [("COMUNICADO_INTERNO", 0), ("INFORME", 0), ("MEMORANDUM", 3), ("CIRCULAR", 4)],
)
def test_rank_permission_matrix_http(
    client, db, org_unit, second_org_unit, rank, level, code, minimum
):
    user, employee, _ = actor(db, org_unit, rank)
    before = db.scalar(select(func.count()).select_from(Correspondence))
    response = client.post(
        "/correspondences",
        headers=headers(user),
        json=body(db, code, employee, second_org_unit),
    )
    assert response.status_code == (201 if level >= minimum else 403), response.text
    if level < minimum:
        assert db.scalar(select(func.count()).select_from(Correspondence)) == before
        return
    result = response.json()
    assert result["has_document_pdf"] is True
    movements = client.get(
        "/correspondences/" + result["id"] + "/movements", headers=headers(user)
    ).json()
    assert [m["movement_type"] for m in movements] == ["CREATED", "DERIVED"]
    assert result["current_unit_id"] == str(second_org_unit.id)
    assert result["current_user_id"] is None


@pytest.mark.parametrize("code", list(OPERATIONAL_DOCUMENTS))
def test_specific_permission_required_no_legacy_runtime_bypass(
    client, db, org_unit, second_org_unit, code
):
    user, employee, _ = actor(
        db, org_unit, "DIRECTOR", permissions=["correspondence.create"]
    )
    response = client.post(
        "/correspondences",
        headers=headers(user),
        json=body(db, code, employee, second_org_unit),
    )
    assert response.status_code == 403
    assert (
        client.get("/document-types/available-for-create", headers=headers(user)).json()
        == []
    )


@pytest.mark.parametrize(
    "code,expected",
    [
        ("COMUNICADO_INTERNO", 201),
        ("INFORME", 201),
        ("MEMORANDUM", 403),
        ("CIRCULAR", 403),
    ],
)
def test_null_hierarchy_only_unrestricted_types(
    client, db, org_unit, second_org_unit, code, expected
):
    user, employee, _ = actor(db, org_unit, None)
    assert (
        client.post(
            "/correspondences",
            headers=headers(user),
            json=body(db, code, employee, second_org_unit),
        ).status_code
        == expected
    )


@pytest.mark.parametrize(
    "invalid", ["employee", "position", "unit", "hierarchy", "no_employee"]
)
def test_inactive_context_denied_and_hidden(
    client, db, org_unit, second_org_unit, invalid
):
    user, employee, position = actor(db, org_unit, "DIRECTOR")
    hierarchy = db.get(PositionHierarchy, position.hierarchy_id)
    target = {
        "employee": employee,
        "position": position,
        "unit": org_unit,
        "hierarchy": hierarchy,
    }.get(invalid)
    try:
        if target:
            target.is_active = False
        else:
            user.employee_id = None
        db.commit()
        response = client.post(
            "/correspondences",
            headers=headers(user),
            json=body(db, "CIRCULAR", employee, second_org_unit),
        )
        assert response.status_code in {403, 422}, response.text
        available = client.get(
            "/document-types/available-for-create", headers=headers(user)
        )
        assert available.status_code == 200 and available.json() == []
    finally:
        if target:
            target.is_active = True
        else:
            user.employee_id = employee.id
        db.commit()


@pytest.mark.parametrize(
    "rank,expected",
    [
        ("FUNCIONARIO", {"COMUNICADO_INTERNO", "INFORME"}),
        ("JEFE", {"COMUNICADO_INTERNO", "INFORME", "MEMORANDUM"}),
        ("DIRECTOR", set(OPERATIONAL_DOCUMENTS)),
    ],
)
def test_available_catalog_and_session_hierarchy(client, db, org_unit, rank, expected):
    user, _, _ = actor(db, org_unit, rank)
    available = client.get(
        "/document-types/available-for-create", headers=headers(user)
    )
    assert available.status_code == 200
    assert {item["code"] for item in available.json()} == expected
    assert all(
        item["is_operational"] and item["profile"] != "GENERIC"
        for item in available.json()
    )
    me = client.get("/auth/me", headers=headers(user))
    assert me.status_code == 200, me.text
    assert me.json()["employee"]["position"]["hierarchy"]["code"] == rank
    # A direct permission change takes effect on the very next catalog request.
    db.query(UserPermission).filter_by(user_id=user.id).delete()
    db.commit()
    assert (
        client.get("/document-types/available-for-create", headers=headers(user)).json()
        == []
    )


@pytest.mark.parametrize(
    "rank,code,expected",
    [
        ("FUNCIONARIO", "CIRCULAR", 403),
        ("FUNCIONARIO", "MEMORANDUM", 403),
        ("JEFE", "MEMORANDUM", 201),
    ],
)
def test_selected_director_does_not_authorize_actor(
    client, db, org_unit, second_org_unit, rank, code, expected
):
    user, _, _ = actor(db, org_unit, rank)
    _, director, _ = actor(db, org_unit, "DIRECTOR")
    response = client.post(
        "/correspondences",
        headers=headers(user),
        json=body(db, code, director, second_org_unit),
    )
    assert response.status_code == expected, response.text


def test_superadmin_functional_permissions_do_not_invent_institutional_context(
    client, db, org_unit, second_org_unit
):
    user, employee, _ = actor(db, org_unit, "FUNCIONARIO", permissions=[])
    role = db.scalar(select(Role).where(Role.code == "SUPERADMIN"))
    assert role
    db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()
    assert set(spec[2] for spec in OPERATIONAL_DOCUMENTS.values()) <= set(
        RbacService(db).get_effective_permission_codes(user.id)
    )
    assert (
        client.post(
            "/correspondences",
            headers=headers(user),
            json=body(db, "CIRCULAR", employee, second_org_unit),
        ).status_code
        == 403
    )
    user.employee_id = None
    db.commit()
    assert (
        client.post(
            "/correspondences",
            headers=headers(user),
            json=body(db, "COMUNICADO_INTERNO", employee, second_org_unit),
        ).status_code
        == 422
    )
    user.is_active = False
    db.commit()


@pytest.mark.parametrize("code", list(OPERATIONAL_DOCUMENTS))
def test_pdf_snapshot_immutable_after_master_changes(
    client, db, org_unit, second_org_unit, code
):
    user, employee, position = actor(db, org_unit, "DIRECTOR")
    response = client.post(
        "/correspondences",
        headers=headers(user),
        json=body(db, code, employee, second_org_unit),
    )
    assert response.status_code == 201, response.text
    path = "/correspondences/" + response.json()["id"]
    row = db.get(Correspondence, uuid.UUID(response.json()["id"]))
    snapshot = copy.deepcopy(row.document_snapshot)
    assert snapshot["actor"]["hierarchy"]["code"] == "DIRECTOR"
    pdf = client.get(path + "/document.pdf", headers=headers(user))
    assert pdf.status_code == 200, pdf.text
    text = "\n".join(
        page.extract_text() for page in PdfReader(BytesIO(pdf.content)).pages
    )
    assert snapshot["name"].upper() in text and snapshot["content"] in text
    employee.first_name = "Nombre futuro"
    position.name = "Cargo futuro"
    org_unit.name = "Unidad futura"
    db.commit()
    again = client.get(path + "/document.pdf", headers=headers(user))
    assert again.status_code == 200
    assert (
        "\n".join(
            page.extract_text() for page in PdfReader(BytesIO(again.content)).pages
        )
        == text
    )
    db.expire(row)
    assert row.document_snapshot == snapshot
    # Used for visual QA, only in the isolated container temporary directory.
    Path("/tmp/phase2-" + code + ".pdf").write_bytes(again.content)


def test_pdf_long_content_flows_across_pages(client, db, org_unit, second_org_unit):
    user, employee, _ = actor(db, org_unit, "DIRECTOR")
    payload = body(db, "CIRCULAR", employee, second_org_unit)
    payload["description"] = "\n".join(
        f"Párrafo {i}: revisión institucional con acentos y contenido extenso. " * 2
        for i in range(60)
    )
    response = client.post("/correspondences", headers=headers(user), json=payload)
    assert response.status_code == 201, response.text
    pdf = client.get(
        "/correspondences/" + response.json()["id"] + "/document.pdf",
        headers=headers(user),
    )
    assert pdf.status_code == 200
    reader = PdfReader(BytesIO(pdf.content))
    assert len(reader.pages) >= 3
    assert "Párrafo 59" in "".join(p.extract_text() for p in reader.pages)
    Path("/tmp/phase2-long.pdf").write_bytes(pdf.content)


@pytest.mark.parametrize(
    "field,value",
    [
        ("code", "CARTA"),
        ("profile", "GENERIC"),
        ("creation_permission", "correspondence.create"),
        ("minimum_hierarchy_id", None),
        ("is_operational", False),
    ],
)
def test_structural_metadata_not_editable(client, db, admin_headers, field, value):
    row = kind(db, "CIRCULAR")
    response = client.put(
        "/admin/document-types/" + str(row.id),
        headers=admin_headers,
        json={"name": row.name, field: value},
    )
    assert response.status_code == 422, response.text


@pytest.mark.parametrize(
    "code", ["EDIE", "NOTA", "CARTA", "SOLICITUD", "CERTIFICACION"]
)
def test_public_endpoint_never_creates_legacy(
    client, db, org_unit, second_org_unit, code
):
    user, employee, _ = actor(db, org_unit, "DIRECTOR")
    row = kind(db, code)
    if row is None:
        row = DocumentType(code=code, name=code, is_active=False)
        db.add(row)
        db.commit()
    payload = body(db, code, employee, second_org_unit)
    assert (
        client.post("/correspondences", headers=headers(user), json=payload).status_code
        == 422
    )
    # Even accidentally reactivating a legacy catalog item cannot reopen CREATE.
    old = row.is_active
    try:
        row.is_active = True
        db.commit()
        assert (
            client.post(
                "/correspondences", headers=headers(user), json=payload
            ).status_code
            == 422
        )
    finally:
        row.is_active = old
        db.commit()


def test_operational_inactive_type_hidden_and_denied(
    client, db, org_unit, second_org_unit
):
    user, employee, _ = actor(db, org_unit, "DIRECTOR")
    row = kind(db, "CIRCULAR")
    try:
        row.is_active = False
        db.commit()
        assert (
            client.post(
                "/correspondences",
                headers=headers(user),
                json=body(db, "CIRCULAR", employee, second_org_unit),
            ).status_code
            == 422
        )
        assert "CIRCULAR" not in {
            x["code"]
            for x in client.get(
                "/document-types/available-for-create", headers=headers(user)
            ).json()
        }
    finally:
        row.is_active = True
        db.commit()


def test_seed_idempotent_preserves_existing_ids_and_document_references(
    db, document_type, user, org_unit, client, auth_headers
):
    file = Path("alembic/versions/j1b2c3d4e5f6_operational_document_types.py")
    spec = importlib.util.spec_from_file_location("phase2_migration", file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    ids = {row.code: row.id for row in db.scalars(select(DocumentType)).all()}
    # Reuse an actual existing document so foreign keys and snapshots are observed.
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type, "Semilla estable", unit_id=org_unit.id, user_id=user.id
        ),
    )
    assert response.status_code == 201, response.text
    row = db.get(Correspondence, uuid.UUID(response.json()["id"]))
    snapshot = copy.deepcopy(row.document_snapshot)
    module.seed_operational_types(db)
    module.seed_operational_types(db)
    db.commit()
    db.expire_all()
    assert all(db.get(DocumentType, id).code == code for code, id in ids.items())
    assert (
        row.document_type_id == document_type.id and row.document_snapshot == snapshot
    )
    assert (
        len(
            db.scalars(
                select(DocumentType).where(DocumentType.is_operational.is_(True))
            ).all()
        )
        == 4
    )


@pytest.mark.parametrize("code", list(OPERATIONAL_DOCUMENTS))
def test_other_specific_permission_cannot_create_requested_type(
    client, db, org_unit, second_org_unit, code
):
    other = (
        "correspondence.create.report"
        if code != "INFORME"
        else "correspondence.create.circular"
    )
    user, employee, _ = actor(db, org_unit, "DIRECTOR", permissions=[other])
    assert (
        client.post(
            "/correspondences",
            headers=headers(user),
            json=body(db, code, employee, second_org_unit),
        ).status_code
        == 403
    )


@pytest.mark.parametrize("code", ["EDIE", "NOTA", *OPERATIONAL_DOCUMENTS])
def test_reports_exports_detail_and_attachments_preserve_types(
    client, db, org_unit, code
):
    user, employee, _ = actor(
        db,
        org_unit,
        "DIRECTOR",
        permissions=[
            *[spec[2] for spec in OPERATIONAL_DOCUMENTS.values()],
            "reports.view",
        ],
    )
    row = kind(db, code)
    if row is None:
        row = DocumentType(code=code, name=code, is_active=False)
        db.add(row)
        db.commit()
    payload = body(db, code, employee, org_unit)
    payload["initial_to_user_id"] = str(user.id)
    create = (
        client.post("/correspondences", headers=headers(user), json=payload)
        if code in OPERATIONAL_DOCUMENTS
        else seed_historical_document(client, headers=headers(user), json=payload)
    )
    assert create.status_code == 201, create.text
    path = "/correspondences/" + create.json()["id"]
    if code not in OPERATIONAL_DOCUMENTS:
        row.is_active = False
        db.commit()
    detail = client.get(path, headers=headers(user))
    assert detail.status_code == 200 and detail.json()["document_type_code"] == code
    assert len(client.get(path + "/movements", headers=headers(user)).json()) == 2
    uploaded = client.post(
        path + "/attachments",
        headers=headers(user),
        files={"file": ("historia.pdf", b"%PDF kept", "application/pdf")},
    )
    assert uploaded.status_code == 201, uploaded.text
    download = client.get(
        path + "/attachments/" + uploaded.json()["id"] + "/download",
        headers=headers(user),
    )
    assert download.status_code == 200 and download.content == b"%PDF kept"
    options = client.get("/reports/options", headers=headers(user))
    assert options.status_code == 200, options.text
    assert str(row.id) in {item["id"] for item in options.json()["types"]}
    query = {"document_type_id": str(row.id), "kind": "registered"}
    report = client.get("/reports", headers=headers(user), params=query)
    assert report.status_code == 200 and report.json()["total"] >= 1, report.text
    assert any(item["id"] == create.json()["id"] for item in report.json()["items"])
    for extension, prefix in [("csv", None), ("xlsx", b"PK"), ("pdf", b"%PDF")]:
        exported = client.get(
            "/reports/export." + extension, headers=headers(user), params=query
        )
        assert exported.status_code == 200, exported.text
        if prefix:
            assert exported.content.startswith(prefix)
        else:
            assert row.name in exported.content.decode("utf-8-sig")
    if code == "EDIE":
        assert client.get(
            path + "/encadenamiento.pdf", headers=headers(user)
        ).content.startswith(b"%PDF")
    if code not in OPERATIONAL_DOCUMENTS:
        # Reads and operations do not reactivate obsolete CREATE.
        assert (
            client.post(
                "/correspondences", headers=headers(user), json=payload
            ).status_code
            == 422
        )


@pytest.mark.parametrize("code", list(OPERATIONAL_DOCUMENTS))
def test_operational_profiles_reject_external_origin_in_direct_api(
    client, db, org_unit, second_org_unit, code
):
    user, employee, _ = actor(db, org_unit, "DIRECTOR")
    payload = body(db, code, employee, second_org_unit)
    payload.update(correspondence_type="EXTERNAL", sender_name="Remitente externo")
    assert (
        client.post("/correspondences", headers=headers(user), json=payload).status_code
        == 422
    )


def test_generated_pdf_does_not_bypass_document_visibility(
    client, db, org_unit, second_org_unit
):
    owner, employee, _ = actor(db, org_unit, "DIRECTOR")
    outsider, _, _ = actor(db, second_org_unit, "DIRECTOR")
    response = client.post(
        "/correspondences",
        headers=headers(owner),
        json=body(db, "CIRCULAR", employee, org_unit),
    )
    assert response.status_code == 201, response.text
    path = "/correspondences/" + response.json()["id"] + "/document.pdf"
    assert client.get(path, headers=headers(owner)).status_code == 200
    assert client.get(path, headers=headers(outsider)).status_code == 404
    assert client.get(path).status_code == 401
