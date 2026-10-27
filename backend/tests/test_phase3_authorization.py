"""Scopes AND mutation permissions AND institutional ownership; real HTTP contracts."""

import json
import subprocess
import sys
import uuid
from io import BytesIO
import pytest
from pypdf import PdfReader
from sqlalchemy import select, func, text, delete
from app.core.database import SessionLocal
from app.core.security import create_access_token
from app.modules.identity.user import User
from app.modules.identity.role import Role
from app.modules.identity.user_role import UserRole
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user_permission import UserPermission
from app.modules.identity.permission import Permission
from app.modules.identity.rbac_service import RbacService
from app.modules.identity.role_transition import (
    plan_role_transition,
    plan_sha256,
    apply_role_transition,
)
from app.modules.correspondence.authorization import *
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.notifications.notification import Notification
from app.modules.organization.position import Position
from tests.test_phase2_operational_documents import actor as make_actor, body
from tests.visibility_helpers import set_unit_scope

CREATE = "correspondence.create.circular"
ALL_OPS = {DERIVE, CONCLUDE, REOPEN, ATTACHMENTS_MANAGE}


def headers(user):
    return {"Authorization": "Bearer " + create_access_token(user.id)[0]}


def grants(db, user, codes):
    db.execute(delete(UserPermission).where(UserPermission.user_id == user.id))
    for code in codes:
        p = db.scalar(select(Permission).where(Permission.code == code))
        assert p is not None, code
        db.add(UserPermission(user_id=user.id, permission_id=p.id))
    db.commit()


def account(db, unit, codes, rank="DIRECTOR"):
    user, employee, position = make_actor(db, unit, rank)
    grants(db, user, codes)
    return user, employee, position


def create(client, db, creator, employee, unit, target=None, subject=None):
    payload = body(db, "CIRCULAR", employee, unit)
    if target:
        payload["initial_to_user_id"] = str(target.id)
    if subject:
        payload["subject"] = subject
    response = client.post("/correspondences", headers=headers(creator), json=payload)
    assert response.status_code == 201, response.text
    return response.json()


@pytest.fixture
def documents(client, db, org_unit, second_org_unit):
    creator, origin, _ = account(db, org_unit, {CREATE, READ_OWN, *ALL_OPS})
    reader, reader_employee, position = account(db, org_unit, {READ_OWN})
    peer, _, _ = account(db, org_unit, {READ_OWN, *ALL_OPS})
    marker = "SCOPE3_" + uuid.uuid4().hex
    values = {
        "own": create(client, db, creator, origin, org_unit, reader, marker),
        "peer": create(client, db, creator, origin, org_unit, peer, marker),
        "unit": create(client, db, creator, origin, org_unit, None, marker),
        "other": create(client, db, creator, origin, second_org_unit, None, marker),
    }
    grants(db, reader, {CREATE, READ_OWN})
    values["created"] = create(
        client, db, reader, reader_employee, second_org_unit, None, marker
    )
    grants(db, reader, {READ_OWN})
    return reader, position, values, marker


@pytest.mark.parametrize(
    "scope,expected",
    [
        (READ_OWN, {"own", "created"}),
        (READ_UNIT, {"own", "peer", "unit"}),
        (READ_ALL, {"own", "peer", "unit", "other", "created"}),
        (None, set()),
    ],
)
@pytest.mark.parametrize("kind", ["own", "peer", "unit", "other", "created"])
def test_scope_matrix_all_document_reads(client, db, documents, scope, expected, kind):
    reader, _, values, _ = documents
    grants(db, reader, {scope} if scope else set())
    path = "/correspondences/" + values[kind]["id"]
    for suffix in ["", "/movements", "/attachments", "/document.pdf"]:
        result = client.get(path + suffix, headers=headers(reader))
        assert result.status_code == (200 if kind in expected else 404), (
            kind,
            suffix,
            result.text,
        )


@pytest.mark.parametrize(
    "scope,expected",
    [
        (READ_OWN, {"own", "created"}),
        (READ_UNIT, {"own", "peer", "unit"}),
        (READ_ALL, {"own", "peer", "unit", "other", "created"}),
        (None, set()),
    ],
)
def test_reports_dashboard_exports_use_identical_read_scope(
    client, db, documents, scope, expected
):
    reader, _, values, marker = documents
    grants(db, reader, ({"reports.view", scope} if scope else {"reports.view"}))
    report = client.get("/reports", headers=headers(reader), params={"search": marker})
    assert report.status_code == 200, report.text
    assert {r["id"] for r in report.json()["items"]} == {
        values[k]["id"] for k in expected
    }
    dashboard = client.get("/dashboard", headers=headers(reader)).json()
    if scope != READ_ALL:
        assert dashboard["total"] == len(expected)
    else:
        assert dashboard["total"] >= len(expected)
    for extension, magic in [("csv", None), ("xlsx", b"PK"), ("pdf", b"%PDF")]:
        response = client.get(
            "/reports/export." + extension,
            headers=headers(reader),
            params={"search": marker},
        )
        assert response.status_code == 200
        if magic:
            assert response.content.startswith(magic)
        else:
            content = response.content.decode("utf-8-sig")
            for key, value in values.items():
                assert (value["route_number"] in content) == (key in expected)
    # The module permission by itself must not imply global reads.
    grants(db, reader, ({scope} if scope else set()))
    assert client.get("/reports", headers=headers(reader)).status_code == 403


@pytest.mark.parametrize(
    "operation,permission",
    [
        ("derive", DERIVE),
        ("conclude", CONCLUDE),
        ("reopen", REOPEN),
        ("attachments", ATTACHMENTS_MANAGE),
    ],
)
@pytest.mark.parametrize(
    "case",
    ["direct", "without_permission", "unit_only", "peer", "outside", "inactive_owner"],
)
def test_mutation_permission_ownership_matrix(
    client, db, org_unit, second_org_unit, operation, permission, case
):
    creator, origin, _ = account(db, org_unit, {CREATE, READ_OWN})
    reader, _, _ = account(db, org_unit, {READ_OWN, permission})
    peer, _, _ = account(db, org_unit, {READ_OWN})
    target = (
        reader
        if case in {"direct", "without_permission", "outside"}
        else peer if case in {"peer", "inactive_owner"} else None
    )
    value = create(client, db, creator, origin, org_unit, target)
    if case == "without_permission":
        grants(db, reader, {READ_OWN})
    if case in {"unit_only", "peer", "inactive_owner"}:
        grants(db, reader, {READ_UNIT, permission})
    if case == "inactive_owner":
        peer.is_active = False
        db.commit()
    if case == "outside":
        from app.modules.organization.employee import Employee

        db.get(Employee, reader.employee_id).unit_id = second_org_unit.id
        db.commit()
        grants(db, reader, {READ_ALL, permission})
    if operation == "reopen":
        db.get(Correspondence, uuid.UUID(value["id"])).status = "CONCLUDED"
        db.commit()
    path = "/correspondences/" + value["id"]
    if operation == "attachments":
        result = client.post(
            path + "/attachments",
            headers=headers(reader),
            files={"file": ("qa.pdf", b"%PDF fixture", "application/pdf")},
        )
    else:
        payload = (
            {"to_unit_id": str(second_org_unit.id)} if operation == "derive" else {}
        )
        result = client.post(
            path + "/" + operation, headers=headers(reader), json=payload
        )
    allowed = case in {"direct", "unit_only", "inactive_owner"} or (
        case == "peer" and operation == "derive"
    )
    assert result.status_code == (
        201 if operation == "attachments" and allowed else 200 if allowed else 403
    ), result.text
    if operation == "derive" and allowed:
        moves = list(
            db.scalars(
                select(CorrespondenceMovement).where(
                    CorrespondenceMovement.correspondence_id == uuid.UUID(value["id"])
                )
            )
        )
        assert len(moves) == 3
        assert sum(m.movement_type == "DERIVED" for m in moves) == 2


def test_attachment_delete_requires_permission_and_download_remains_visible(
    client, db, org_unit, second_org_unit
):
    user, employee, _ = account(db, org_unit, {CREATE, READ_OWN, ATTACHMENTS_MANAGE})
    item = create(client, db, user, employee, org_unit, user)
    path = "/correspondences/" + item["id"]
    upload = client.post(
        path + "/attachments",
        headers=headers(user),
        files={"file": ("qa.pdf", b"%PDF fixture", "application/pdf")},
    )
    assert upload.status_code == 201
    aid = upload.json()["id"]
    grants(db, user, {READ_OWN})
    assert (
        client.get(
            path + "/attachments/" + aid + "/download", headers=headers(user)
        ).status_code
        == 200
    )
    assert (
        client.delete(path + "/attachments/" + aid, headers=headers(user)).status_code
        == 403
    )
    grants(db, user, {READ_OWN, ATTACHMENTS_MANAGE})
    assert (
        client.delete(path + "/attachments/" + aid, headers=headers(user)).status_code
        == 200
    )


def test_legacy_flag_never_grants_read_or_mutations(
    client, db, documents, org_unit, second_org_unit
):
    user, position, values, _ = documents
    position.can_view_unit_correspondence = True
    db.commit()
    path = "/correspondences/" + values["peer"]["id"]
    assert client.get(path, headers=headers(user)).status_code == 404
    grants(db, user, {READ_OWN, DERIVE})
    assert (
        client.post(
            path + "/derive",
            headers=headers(user),
            json={"to_unit_id": str(second_org_unit.id)},
        ).status_code
        == 403
    )
    grants(db, user, {READ_UNIT, DERIVE})
    position.can_view_unit_correspondence = False
    db.commit()
    assert client.get(path, headers=headers(user)).status_code == 200
    assert (
        client.post(
            path + "/derive",
            headers=headers(user),
            json={"to_unit_id": str(second_org_unit.id)},
        ).status_code
        == 200
    )


@pytest.mark.parametrize("linked", [False, True])
def test_superadmin_global_read_does_not_replace_institutional_ownership(
    client, db, org_unit, second_org_unit, linked
):
    owner, employee, _ = account(db, org_unit, {CREATE, READ_OWN})
    value = create(client, db, owner, employee, org_unit, owner)
    superuser, super_employee, _ = account(
        db, second_org_unit, set(), rank="FUNCIONARIO"
    )
    if not linked:
        superuser.employee_id = None
    role = db.scalar(select(Role).where(Role.code == "SUPERADMIN"))
    db.add(UserRole(user_id=superuser.id, role_id=role.id))
    db.commit()
    h = headers(superuser)
    path = "/correspondences/" + value["id"]
    assert client.get(path, headers=h).status_code == 200
    assert client.get(path + "/document.pdf", headers=h).status_code == 200
    assert client.get("/admin/users", headers=h).status_code == 200
    assert client.get("/reports", headers=h).status_code == 200
    for operation in ["derive", "conclude", "reopen"]:
        payload = (
            {"to_unit_id": str(second_org_unit.id)} if operation == "derive" else {}
        )
        assert (
            client.post(path + "/" + operation, headers=h, json=payload).status_code
            == 403
        )
    creation = client.post(
        "/correspondences",
        headers=h,
        json=body(db, "CIRCULAR", super_employee, org_unit),
    )
    assert creation.status_code == (403 if linked else 422)
    superuser.is_active = False
    db.commit()


def test_detail_capabilities_match_permissions_and_state(client, db, org_unit):
    user, employee, _ = account(db, org_unit, {CREATE, READ_OWN})
    value = create(client, db, user, employee, org_unit, user)
    path = "/correspondences/" + value["id"]
    data = client.get(path, headers=headers(user)).json()
    assert data["can_operate"] is True
    assert not any(
        data[k]
        for k in ["can_derive", "can_conclude", "can_reopen", "can_manage_attachments"]
    )
    grants(db, user, {READ_OWN, *ALL_OPS})
    data = client.get(path, headers=headers(user)).json()
    assert (
        data["can_derive"]
        and data["can_conclude"]
        and data["can_manage_attachments"]
        and not data["can_reopen"]
    )
    assert (
        client.post(path + "/conclude", headers=headers(user), json={}).status_code
        == 200
    )
    data = client.get(path, headers=headers(user)).json()
    assert data["can_reopen"] and not any(
        data[k] for k in ["can_derive", "can_conclude", "can_manage_attachments"]
    )


def test_revoked_read_scope_hides_persisted_notifications_and_prevents_duplicates(
    client, db, org_unit
):
    creator, employee, _ = account(db, org_unit, {CREATE, READ_OWN})
    reader, _, _ = account(db, org_unit, {READ_UNIT})
    unprivileged, _, position = account(db, org_unit, set())
    position.can_view_unit_correspondence = True
    db.commit()
    value = create(client, db, creator, employee, org_unit)
    notifications = client.get("/notifications", headers=headers(reader)).json()
    assert notifications["total"] == 1
    assert (
        client.get("/notifications", headers=headers(unprivileged)).json()["total"] == 0
    )
    from app.modules.notifications.service import notify_movement

    movement = db.scalar(
        select(CorrespondenceMovement).where(
            CorrespondenceMovement.correspondence_id == uuid.UUID(value["id"]),
            CorrespondenceMovement.sequence_number == 2,
        )
    )
    notify_movement(db, db.get(Correspondence, uuid.UUID(value["id"])), movement)
    db.commit()
    assert client.get("/notifications", headers=headers(reader)).json()["total"] == 1
    grants(db, reader, set())
    assert client.get("/notifications", headers=headers(reader)).json()["total"] == 0
    assert (
        client.get("/notifications/unread-count", headers=headers(reader)).json()[
            "unread"
        ]
        == 0
    )
    nid = notifications["items"][0]["id"]
    assert (
        client.post(
            "/notifications/" + nid + "/read", headers=headers(reader)
        ).status_code
        == 404
    )


def legacy_account(db, unit, role_code):
    user, _, _ = account(db, unit, {"reports.view"})
    role = db.scalar(select(Role).where(Role.code == role_code))
    db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()
    return user


def test_legacy_dry_run_is_read_only_and_lossless_apply_is_audited(db, org_unit):
    manager = legacy_account(db, org_unit, "MANAGER")
    operator = legacy_account(db, org_unit, "OPERATOR")
    admin = legacy_account(db, org_unit, "ADMIN")
    inactive = legacy_account(db, org_unit, "OPERATOR")
    inactive.is_active = False
    db.commit()
    before = {
        u.id: RbacService(db).get_effective_permission_codes(
            u.id, include_inactive=True
        )
        for u in [manager, operator, admin, inactive]
    }
    counts = tuple(
        db.scalar(text("select count(*) from " + table))
        for table in [
            "user_roles",
            "user_permissions",
            "authorization_migration_audits",
        ]
    )
    process = subprocess.run(
        [sys.executable, "scripts/migrate_authorization_roles.py", "--dry-run"],
        capture_output=True,
        text=True,
        check=True,
    )
    payload = json.loads(process.stdout)
    assert payload["dry_run"] is True
    assert any(
        u["user_id"] == str(admin.id) and u["action"] == "SKIP_ADMIN_APPROVAL"
        for u in payload["users"]
    )
    assert counts == tuple(
        db.scalar(text("select count(*) from " + table))
        for table in [
            "user_roles",
            "user_permissions",
            "authorization_migration_audits",
        ]
    )
    with SessionLocal() as isolated:
        result = apply_role_transition(isolated, expected_sha256=payload["plan_sha256"])
        isolated.commit()
    db.expire_all()
    for u in [manager, operator, inactive]:
        assert RbacService(db).get_user_role_codes(u.id) == ["OPERADOR"]
        assert (
            RbacService(db).get_effective_permission_codes(u.id, include_inactive=True)
            == before[u.id]
        )
    assert "ADMIN" in RbacService(db).get_user_role_codes(admin.id)
    assert not RbacService(db).is_superadmin(admin.id)
    assert (
        db.scalar(
            text(
                "select count(*) from authorization_migration_audits where batch_id=:id"
            ),
            {"id": uuid.UUID(result["batch_id"])},
        )
        >= 3
    )


def test_role_plan_refuses_drift_without_partial_changes(db, org_unit):
    user = legacy_account(db, org_unit, "MANAGER")
    with SessionLocal() as isolated:
        with pytest.raises(ValueError, match="plan cambió"):
            apply_role_transition(isolated, expected_sha256="invalid")
        isolated.rollback()
    assert RbacService(db).get_user_role_codes(user.id) == ["MANAGER"]


def test_operator_cannot_self_grant_administration_or_superadmin(client, db, org_unit):
    user, _, _ = account(db, org_unit, {READ_OWN})
    role = db.scalar(select(Role).where(Role.code == "OPERADOR"))
    db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()
    permission = db.scalar(
        select(Permission).where(Permission.code == "master_data.users.manage")
    )
    assert (
        client.put(
            "/admin/users/" + str(user.id) + "/permissions",
            headers=headers(user),
            json={"permission_ids": [str(permission.id)]},
        ).status_code
        == 403
    )
    # Even delegated administrators cannot entrench role-derived admin grants on themselves.
    delegated = db.scalar(select(Role).where(Role.code == "ADMIN"))
    db.add(UserRole(user_id=user.id, role_id=delegated.id))
    db.commit()
    assert (
        client.put(
            "/admin/users/" + str(user.id) + "/permissions",
            headers=headers(user),
            json={"permission_ids": [str(permission.id)]},
        ).status_code
        == 403
    )
    superrole = db.scalar(select(Role).where(Role.code == "SUPERADMIN"))
    with pytest.raises(Exception) as rejected:
        RbacService(db).assert_can_assign_roles(
            user,
            [superrole.id],
            target_id=user.id,
            current_role_ids=[role.id, delegated.id],
        )
    assert rejected.value.status_code == 403


def test_admin_conversion_requires_explicit_username_and_never_promotes(db, org_unit):
    user = legacy_account(db, org_unit, "ADMIN")
    before = RbacService(db).get_effective_permission_codes(
        user.id, include_inactive=True
    )
    plan = plan_role_transition(db, approved_admins=[user.username])
    entry = next(row for row in plan if row["user_id"] == str(user.id))
    assert entry["action"] == "MIGRATE" and entry["target_roles"] == ["OPERADOR"]
    with SessionLocal() as isolated:
        apply_role_transition(
            isolated, expected_sha256=plan_sha256(plan), approved_admins=[user.username]
        )
        isolated.commit()
    db.expire_all()
    assert RbacService(db).get_user_role_codes(user.id) == ["OPERADOR"]
    assert (
        RbacService(db).get_effective_permission_codes(user.id, include_inactive=True)
        == before
    )
    assert not RbacService(db).is_superadmin(user.id)


def test_new_read_scope_grants_do_not_extend_issuer_hierarchy(
    client, db, org_unit, second_org_unit
):
    user, employee, _ = account(
        db, org_unit, {CREATE, READ_ALL, *ALL_OPS}, rank="FUNCIONARIO"
    )
    assert (
        client.post(
            "/correspondences",
            headers=headers(user),
            json=body(db, "CIRCULAR", employee, second_org_unit),
        ).status_code
        == 403
    )


def test_closed_document_rejects_mutations_even_with_permissions(
    client, db, org_unit, second_org_unit
):
    user, employee, _ = account(db, org_unit, {CREATE, READ_OWN, *ALL_OPS})
    value = create(client, db, user, employee, org_unit, user)
    path = "/correspondences/" + value["id"]
    assert (
        client.post(path + "/conclude", headers=headers(user), json={}).status_code
        == 200
    )
    assert (
        client.post(
            path + "/derive",
            headers=headers(user),
            json={"to_unit_id": str(second_org_unit.id)},
        ).status_code
        == 422
    )
    assert (
        client.post(path + "/conclude", headers=headers(user), json={}).status_code
        == 422
    )
    assert (
        client.post(
            path + "/attachments",
            headers=headers(user),
            files={"file": ("qa.pdf", b"%PDF fixture", "application/pdf")},
        ).status_code
        == 422
    )


def test_role_migration_blocks_target_role_permission_expansion(db, org_unit):
    user = legacy_account(db, org_unit, "MANAGER")
    operator = db.scalar(select(Role).where(Role.code == "OPERADOR"))
    permission = db.scalar(select(Permission).where(Permission.code == READ_ALL))
    db.add(RolePermission(role_id=operator.id, permission_id=permission.id))
    db.commit()
    try:
        plan = plan_role_transition(db)
        row = next(r for r in plan if r["user_id"] == str(user.id))
        assert (
            row["action"] == "BLOCKED_PERMISSION_DIFF"
            and READ_ALL in row["added_permissions"]
        )
        with SessionLocal() as isolated:
            with pytest.raises(ValueError, match="agregaría"):
                apply_role_transition(isolated, expected_sha256=plan_sha256(plan))
            isolated.rollback()
        assert RbacService(db).get_user_role_codes(user.id) == ["MANAGER"]
    finally:
        db.execute(
            delete(RolePermission).where(
                RolePermission.role_id == operator.id,
                RolePermission.permission_id == permission.id,
            )
        )
        db.commit()
