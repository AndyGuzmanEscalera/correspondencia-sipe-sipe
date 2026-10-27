import importlib.util
from pathlib import Path
import uuid

import pytest
from fastapi import HTTPException
from sqlalchemy import select, update
from app.core.security import create_access_token
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.identity.user_permission import UserPermission
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.rbac_service import RbacService
from app.modules.identity.user_admin_service import UserAdminService
from app.modules.identity.administrative_continuity import CRITICAL_PERMISSIONS
from app.modules.organization.position import Position
from app.modules.organization.position_hierarchy import PositionHierarchy
from tests.test_administrative_continuity import admin_db


def headers(user):
    return {"Authorization": "Bearer " + create_access_token(user.id)[0]}


def account(db, role_code=None):
    user = User(
        username="phase1_" + uuid.uuid4().hex, password_hash="unused", is_active=True
    )
    db.add(user)
    db.flush()
    if role_code:
        role = db.scalar(select(Role).where(Role.code == role_code))
        if role is None:
            role = Role(code=role_code, name=role_code, is_active=True)
            db.add(role)
            db.flush()
        db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()
    return user


def permission(db, code=None):
    code = code or "phase1." + uuid.uuid4().hex
    p = db.scalar(select(Permission).where(Permission.code == code))
    if p is None:
        p = Permission(code=code)
        db.add(p)
        db.commit()
    return p


def grant(db, user, codes):
    for code in codes:
        p = permission(db, code)
        db.merge(UserPermission(user_id=user.id, permission_id=p.id))
    db.commit()


@pytest.fixture
def superadmin(db):
    user = account(db, "SUPERADMIN")
    yield user
    # Do not leave a synthetic operative administrator for unrelated tests.
    user.is_active = False
    db.commit()


def test_effective_union_deduplicates_and_never_grants_without_assignment(db):
    u = account(db)
    other = account(db)
    p = permission(db)
    role = Role(code="UNION_" + uuid.uuid4().hex, name="Union", is_active=True)
    db.add(role)
    db.flush()
    db.add_all(
        [
            UserRole(user_id=u.id, role_id=role.id),
            RolePermission(role_id=role.id, permission_id=p.id),
            UserPermission(user_id=u.id, permission_id=p.id),
        ]
    )
    db.commit()
    rbac = RbacService(db)
    assert rbac.get_effective_permission_codes(u.id) == [p.code]
    assert rbac.get_effective_permission_codes(other.id) == []
    role.is_active = False
    db.commit()
    assert rbac.has_permission(u.id, p.code)  # direct grant remains
    u.is_active = False
    db.commit()
    assert rbac.get_effective_permission_codes(u.id) == []


def test_superadmin_catalog_is_dynamic_and_context_is_not_fabricated(
    client, db, superadmin, document_type
):
    rbac = RbacService(db)
    p = permission(db)
    assert rbac.has_permission(superadmin.id, p.code)
    me = client.get("/auth/me", headers=headers(superadmin))
    assert me.status_code == 200
    assert me.json()["roles"] == ["SUPERADMIN"]
    assert me.json()["employee"] is None
    assert set(me.json()["permissions"]) == set(db.scalars(select(Permission.code)))
    assert (
        client.get("/admin/positions", headers=headers(superadmin)).status_code == 200
    )
    create = client.post(
        "/correspondences",
        headers=headers(superadmin),
        json={
            "correspondence_type": "INTERNAL",
            "document_type_id": str(document_type.id),
            "subject": "No fictitious actor",
            "priority": "LOW",
        },
    )
    assert create.status_code == 422
    superadmin.is_active = False
    db.commit()
    assert rbac.get_effective_permission_codes(superadmin.id) == []
    assert (
        client.get("/admin/positions", headers=headers(superadmin)).status_code == 401
    )


def test_direct_permission_endpoint_is_idempotent_and_audited(client, db, superadmin):
    target = account(db, "OPERADOR")
    p = permission(db)
    for _ in range(2):
        response = client.put(
            f"/admin/users/{target.id}/permissions",
            headers=headers(superadmin),
            json={"permission_ids": [str(p.id), str(p.id)]},
        )
        assert response.status_code == 200, response.text
        assert response.json()["direct_permissions"] == [p.code]
        assert response.json()["effective_permissions"] == [p.code]
    grants = db.scalars(
        select(UserPermission).where(UserPermission.user_id == target.id)
    ).all()
    assert len(grants) == 1 and grants[0].granted_by_user_id == superadmin.id
    assert (
        client.put(
            f"/admin/users/{target.id}/permissions",
            headers=headers(superadmin),
            json={"permission_ids": []},
        ).status_code
        == 200
    )
    assert not RbacService(db).has_permission(target.id, p.code)


def test_permission_escalation_is_rejected(client, db, superadmin, employee):
    actor = account(db, "OPERADOR")
    target = account(db)
    p = permission(db, "system.settings.manage")
    path = f"/admin/users/{actor.id}/permissions"
    assert (
        client.put(
            path, headers=headers(actor), json={"permission_ids": [str(p.id)]}
        ).status_code
        == 403
    )
    grant(db, actor, ["master_data.users.manage", "master_data.roles.assign"])
    assert (
        client.put(
            path, headers=headers(actor), json={"permission_ids": [str(p.id)]}
        ).status_code
        == 403
    )
    role = db.scalar(select(Role).where(Role.code == "SUPERADMIN"))
    result = client.post(
        "/admin/users",
        headers=headers(actor),
        json={
            "username": "forbidden_" + uuid.uuid4().hex,
            "employee_id": str(employee.id),
            "initial_password": "TestPass123!",
            "role_ids": [str(role.id)],
        },
    )
    assert result.status_code == 403
    assert RbacService(db).get_direct_permission_codes(actor.id) == sorted(
        ["master_data.users.manage", "master_data.roles.assign"]
    )
    unknown = client.put(
        f"/admin/users/{target.id}/permissions",
        headers=headers(superadmin),
        json={"permission_ids": [str(uuid.uuid4())]},
    )
    assert unknown.status_code == 422


def test_administration_accepts_direct_grants_without_role(client, db):
    u = account(db)
    grant(db, u, ["master_data.positions.read"])
    assert client.get("/admin/positions", headers=headers(u)).status_code == 200
    assert (
        client.post(
            "/admin/positions",
            headers=headers(u),
            json={"code": "NO", "name": "Denied"},
        ).status_code
        == 403
    )


def test_continuity_counts_direct_permissions_and_prevents_last_revoke(admin_db):
    db = admin_db
    u = account(db)
    other = account(db)
    grant(db, u, CRITICAL_PERMISSIONS)
    grant(db, other, ["master_data.users.manage", "master_data.roles.assign"])
    with pytest.raises(HTTPException) as error:
        UserAdminService(db).set_direct_permissions(other, u.id, [])
    assert error.value.status_code == 409
    assert CRITICAL_PERMISSIONS <= set(
        RbacService(db).get_effective_permission_codes(u.id)
    )


def test_continuity_counts_superadmin_without_employee(admin_db):
    db = admin_db
    u = account(db, "SUPERADMIN")
    actor = account(db)
    grant(db, actor, ["master_data.users.manage", "master_data.roles.assign"])
    with pytest.raises(HTTPException) as error:
        UserAdminService(db).set_active(actor, u.id, is_active=False)
    assert error.value.status_code == 409


@pytest.mark.parametrize("rank", [0, -1, 1.5, True])
def test_hierarchy_rejects_invalid_rank(client, superadmin, rank):
    r = client.post(
        "/admin/positions/hierarchies",
        headers=headers(superadmin),
        json={"code": "INVALID", "name": "Invalid", "rank": rank},
    )
    assert r.status_code == 422


def test_hierarchy_crud_and_position_transition(client, db, superadmin):
    h = headers(superadmin)
    base = "/admin/positions/hierarchies"
    result = client.post(
        base,
        headers=h,
        json={"code": " qa_" + uuid.uuid4().hex + " ", "name": " QA level ", "rank": 8},
    )
    assert result.status_code == 201, result.text
    hierarchy = result.json()
    id = hierarchy["id"]
    assert hierarchy["name"] == "QA level" and hierarchy["code"].startswith("QA_")
    duplicate = client.post(
        base,
        headers=h,
        json={"code": hierarchy["code"].lower(), "name": "Duplicate", "rank": 8},
    )
    assert duplicate.status_code == 409
    assert (
        client.put(
            f"{base}/{id}", headers=h, json={"name": "Edited", "rank": 9}
        ).json()["rank"]
        == 9
    )
    listed = client.get(base, headers=h, params={"search": hierarchy["code"]}).json()
    assert listed["total"] == 1
    payload = {
        "code": "P_" + uuid.uuid4().hex,
        "name": "Cargo",
        "hierarchy_id": id,
        "can_view_unit_correspondence": True,
    }
    pos = client.post("/admin/positions", headers=h, json=payload)
    assert pos.status_code == 201, pos.text
    assert pos.json()["hierarchy_code"] == hierarchy["code"]
    pid = pos.json()["id"]
    assert (
        client.patch(
            f"{base}/{id}/active", headers=h, json={"is_active": False}
        ).status_code
        == 409
    )
    updated = client.put(
        f"/admin/positions/{pid}",
        headers=h,
        json={"code": payload["code"], "name": "Other"},
    )
    assert (
        updated.json()["hierarchy_id"] == id
        and updated.json()["can_view_unit_correspondence"]
    )
    cleared = client.put(
        f"/admin/positions/{pid}", headers=h, json={**payload, "hierarchy_id": None}
    )
    assert cleared.json()["hierarchy_id"] is None
    assert (
        client.patch(
            f"{base}/{id}/active", headers=h, json={"is_active": False}
        ).status_code
        == 200
    )
    assert (
        client.post(
            "/admin/positions",
            headers=h,
            json={**payload, "code": "N_" + uuid.uuid4().hex},
        ).status_code
        == 422
    )
    assert (
        client.patch(
            f"{base}/{id}/active", headers=h, json={"is_active": True}
        ).status_code
        == 200
    )


def test_seed_is_idempotent_and_does_not_assign_users_or_positions(db):
    p = Path("alembic/versions/i1b2c3d4e5f6_authorization_hierarchies.py")
    spec = importlib.util.spec_from_file_location("phase1_migration", p)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    before = set(db.scalars(select(UserRole.user_id)))
    for _ in range(2):
        module.seed_base_data(db.connection())
    db.commit()
    assert set(db.scalars(select(UserRole.user_id))) == before
    assert (
        len(
            db.scalars(
                select(PositionHierarchy).where(
                    PositionHierarchy.code.in_(
                        [
                            "FUNCIONARIO",
                            "RESPONSABLE",
                            "JEFE",
                            "DIRECTOR",
                            "SECRETARIO",
                            "ALCALDE",
                        ]
                    )
                )
            ).all()
        )
        == 6
    )
    assert not db.scalars(
        select(RolePermission).join(Role).where(Role.code == "OPERADOR")
    ).all()


def test_concurrent_duplicate_grants_remain_single_and_successful(
    client, db, superadmin
):
    from concurrent.futures import ThreadPoolExecutor

    target = account(db, "OPERADOR")
    p = permission(db)

    def send(_):
        return client.put(
            f"/admin/users/{target.id}/permissions",
            headers=headers(superadmin),
            json={"permission_ids": [str(p.id)]},
        ).status_code

    with ThreadPoolExecutor(max_workers=3) as pool:
        assert list(pool.map(send, range(3))) == [200, 200, 200]
    assert (
        len(
            db.scalars(
                select(UserPermission).where(UserPermission.user_id == target.id)
            ).all()
        )
        == 1
    )


def test_inactive_superadmin_role_does_not_bypass(client, db):
    user = account(db)
    role = Role(
        code="SA_TEST_" + uuid.uuid4().hex, name="Not a reserved role", is_active=True
    )
    db.add(role)
    db.flush()
    db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()
    assert not RbacService(db).is_superadmin(user.id)
    assert client.get("/admin/positions", headers=headers(user)).status_code == 403
    reserved = db.scalar(select(Role).where(Role.code == "SUPERADMIN"))
    db.add(UserRole(user_id=user.id, role_id=reserved.id))
    db.commit()
    try:
        reserved.is_active = False
        db.commit()
        assert RbacService(db).get_effective_permission_codes(user.id) == []
        assert client.get("/admin/positions", headers=headers(user)).status_code == 403
    finally:
        reserved.is_active = True
        user.is_active = False
        db.commit()
