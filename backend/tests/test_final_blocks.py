from tests.visibility_helpers import (
    set_position_scope,
    set_unit_scope,
    grant_operational_permissions,
)
import csv
import io
import uuid
from datetime import datetime, timezone
import pytest
from sqlalchemy import select
from app.core.security import create_access_token
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.notifications.notification import Notification
from app.modules.notifications.service import notify_movement
from app.modules.identity.user import User
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from tests.test_correspondence import _create_payload


def headers(user):
    return {"Authorization": "Bearer " + create_access_token(user.id)[0]}


def reader(db, unit):
    pos = Position(
        id=uuid.uuid4(),
        code="QA_" + uuid.uuid4().hex[:8],
        name="Cargo QA",
        is_active=True,
        can_view_unit_correspondence=True,
    )
    db.add(pos)
    db.flush()
    employee = Employee(
        id=uuid.uuid4(),
        first_name="Lector QA",
        last_name="Ficticio",
        document_number=uuid.uuid4().hex[:20],
        unit_id=unit.id,
        position_id=pos.id,
        is_active=True,
    )
    db.add(employee)
    db.flush()
    user = User(
        id=uuid.uuid4(),
        employee_id=employee.id,
        username="qa_" + uuid.uuid4().hex,
        password_hash="unused",
        is_active=True,
    )
    db.add(user)
    db.commit()
    grant_operational_permissions(db, user)
    set_unit_scope(db, user, True)
    return user, employee, pos


def grant(db, user):
    permission = db.scalar(select(Permission).where(Permission.code == "reports.view"))
    assert permission is not None
    role = Role(
        id=uuid.uuid4(),
        code="CUSTOM_" + uuid.uuid4().hex[:8],
        name="Rol personalizado QA",
        is_active=True,
    )
    db.add(role)
    db.flush()
    db.add(RolePermission(role_id=role.id, permission_id=permission.id))
    db.add(UserRole(user_id=user.id, role_id=role.id, assigned_by=user.id))
    db.commit()
    return role


@pytest.fixture
def document(client, auth_headers, document_type, second_org_unit, second_user):
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Final QA visible",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
        ),
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_dashboard_personal_and_unit_isolation(
    client, db, document, user, second_user, second_org_unit
):
    mine = client.get("/dashboard", headers=headers(second_user)).json()
    assert mine["mine"] == 1 and mine["total"] == 1 and mine["unit"] is None
    assert mine["activity"][0]["type"] == "RECEIVED"
    sent = client.get("/dashboard", headers=headers(user)).json()
    assert sent["mine"] == 0 and sent["sent"] == 1 and sent["total"] == 1
    unit_user, _, _ = reader(db, second_org_unit)
    result = client.get("/dashboard", headers=headers(unit_user)).json()
    assert result["unit"] == 1 and result["mine"] == 0 and result["can_view_unit"]
    alien = client.get(
        "/dashboard", headers=headers(reader(db, second_org_unit)[0])
    ).json()
    assert alien["total"] == 1


def test_dashboard_conclusion_and_empty_scope(
    client, db, document, second_user, org_unit
):
    path = "/correspondences/" + document["id"]
    assert (
        client.post(
            path + "/conclude", headers=headers(second_user), json={}
        ).status_code
        == 200
    )
    data = client.get("/dashboard", headers=headers(second_user)).json()
    assert (
        data["mine"] == 0
        and data["concluded"] == 1
        and data["activity"][0]["type"] == "CONCLUDED"
    )
    outsider, _, _ = reader(db, org_unit)
    empty = client.get("/dashboard", headers=headers(outsider)).json()
    assert empty["total"] == 0 and empty["activity"] == []


def test_direct_notification_and_idempotence(client, db, document, user, second_user):
    rows = client.get("/notifications", headers=headers(second_user)).json()
    assert rows["unread"] == 1 and rows["items"][0]["type"] == "ASSIGNED"
    assert (
        client.get("/notifications/unread-count", headers=headers(user)).json()[
            "unread"
        ]
        == 0
    )
    movement = db.scalar(
        select(CorrespondenceMovement).where(
            CorrespondenceMovement.correspondence_id == uuid.UUID(document["id"]),
            CorrespondenceMovement.sequence_number == 2,
        )
    )
    notify_movement(db, db.get(Correspondence, uuid.UUID(document["id"])), movement)
    db.commit()
    assert (
        client.get("/notifications/unread-count", headers=headers(second_user)).json()[
            "unread"
        ]
        == 1
    )


@pytest.mark.parametrize("inactive", [None, "user", "employee", "position", "unit"])
def test_unit_only_notifies_only_active_scoped_users(
    client,
    db,
    user,
    auth_headers,
    document_type,
    second_org_unit,
    second_user,
    inactive,
):
    scoped, employee, position = reader(db, second_org_unit)
    target = {
        "user": scoped,
        "employee": employee,
        "position": position,
        "unit": second_org_unit,
    }.get(inactive)
    # Destination validation forbids inactive units, so test recipient activity before activating destination.
    if inactive == "unit":
        second_org_unit.is_active = False
        db.commit()
        response = client.post(
            "/correspondences",
            headers=auth_headers,
            json=_create_payload(
                document_type, "Unit inactive", unit_id=second_org_unit.id
            ),
        )
        assert response.status_code == 422
        assert (
            client.get("/notifications/unread-count", headers=headers(scoped)).json()[
                "unread"
            ]
            == 0
        )
        return
    if target:
        target.is_active = False
        db.commit()
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(document_type, "Unit-only QA", unit_id=second_org_unit.id),
    )
    assert response.status_code == 201, response.text
    assert response.json()["current_user_id"] is None
    assert (
        db.scalar(select(Notification.id).where(Notification.user_id == second_user.id))
        is None
    )
    notifications = list(
        db.scalars(select(Notification).where(Notification.user_id == scoped.id))
    )
    assert len(notifications) == (1 if inactive is None else 0)


def test_notification_read_pagination_and_user_isolation(
    client, db, document, second_user, user
):
    own = client.get(
        "/notifications", headers=headers(second_user), params={"page_size": 1}
    ).json()
    assert own["total"] == 1 and len(own["items"]) == 1
    nid = own["items"][0]["id"]
    assert (
        client.post(
            "/notifications/" + nid + "/read", headers=headers(user)
        ).status_code
        == 404
    )
    assert (
        client.post(
            "/notifications/" + nid + "/read", headers=headers(second_user)
        ).json()["unread"]
        == 0
    )
    timestamp = client.get("/notifications", headers=headers(second_user)).json()[
        "items"
    ][0]["read_at"]
    assert (
        client.post(
            "/notifications/" + nid + "/read", headers=headers(second_user)
        ).status_code
        == 200
    )
    assert (
        client.get("/notifications", headers=headers(second_user)).json()["items"][0][
            "read_at"
        ]
        == timestamp
    )
    assert (
        client.post("/notifications/read-all", headers=headers(user)).json()["unread"]
        == 0
    )


def test_derive_reopen_notifications_do_not_grant_visibility(
    client, db, document, second_user, user, org_unit, second_org_unit
):
    scoped, _, _ = reader(db, second_org_unit)
    path = "/correspondences/" + document["id"]
    assert (
        client.post(
            path + "/conclude", headers=headers(second_user), json={}
        ).status_code
        == 200
    )
    assert (
        client.post(path + "/reopen", headers=headers(second_user), json={}).status_code
        == 200
    )
    assert (
        client.get("/notifications", headers=headers(scoped)).json()["items"][0]["type"]
        == "REOPENED"
    )
    assert (
        client.post(
            path + "/derive",
            headers=headers(second_user),
            json={"to_unit_id": str(org_unit.id), "to_user_id": str(user.id)},
        ).status_code
        == 200
    )
    assert (
        client.get("/notifications", headers=headers(user)).json()["items"][0]["type"]
        == "DERIVED"
    )
    assert client.get(path, headers=headers(scoped)).status_code == 404
    assert (
        client.post("/notifications/read-all", headers=headers(scoped)).json()["unread"]
        == 0
    )


def test_report_permission_custom_role_and_scope(
    client, db, document, user, second_user, second_org_unit
):
    assert client.get("/reports", headers=headers(user)).status_code == 403
    assert client.get("/reports/export.csv", headers=headers(user)).status_code == 403
    grant(db, user)
    grant(db, second_user)
    result = client.get("/reports", headers=headers(user)).json()
    assert result["total"] == 1 and result["summary"]["pending"] == 1
    recipient = client.get(
        "/reports", headers=headers(second_user), params={"kind": "received"}
    ).json()
    assert recipient["total"] == 1 and recipient["summary"]["by_unit"] == []
    assert (
        client.get(
            "/reports",
            headers=headers(second_user),
            params={"kind": "received", "unit_id": str(second_org_unit.id)},
        ).status_code
        == 403
    )
    scoped, _, _ = reader(db, second_org_unit)
    grant(db, scoped)
    response = client.get(
        "/reports",
        headers=headers(scoped),
        params={"kind": "received", "unit_id": str(second_org_unit.id)},
    )
    assert response.status_code == 200 and response.json()["total"] == 1
    assert sum(x["total"] for x in response.json()["summary"]["by_unit"]) == 1


@pytest.mark.parametrize(
    "filter",
    ["dates", "type", "status", "search", "employee", "pagination", "unit-forbidden"],
)
def test_report_filters(
    client, db, document, user, second_user, org_unit, document_type, filter
):
    grant(db, user)
    params = {}
    if filter == "dates":
        params = {"date_from": "2000-01-01", "date_to": "2000-01-02"}
    if filter == "type":
        params = {"document_type_id": str(uuid.uuid4())}
    if filter == "status":
        params = {"status": "CONCLUDED"}
    if filter == "search":
        params = {"search": "inexistent_literal_%_"}
    if filter == "employee":
        params = {"employee_id": str(user.employee_id)}
    if filter == "pagination":
        params = {"page": 2, "page_size": 1}
    if filter == "unit-forbidden":
        params = {"unit_id": str(org_unit.id)}
    response = client.get("/reports", headers=headers(user), params=params)
    if filter == "unit-forbidden":
        assert response.status_code == 403
        return
    assert response.status_code == 200, response.text
    assert response.json()["items"] == []
    assert response.json()["total"] == (1 if filter == "pagination" else 0)


def test_report_dates_are_inclusive_bolivia_and_validation(client, db, document, user):
    grant(db, user)
    row = db.get(Correspondence, uuid.UUID(document["id"]))
    row.created_at = datetime(2026, 10, 15, 3, 59, tzinfo=timezone.utc)
    db.commit()
    result = client.get(
        "/reports",
        headers=headers(user),
        params={"date_from": "2026-10-14", "date_to": "2026-10-14"},
    )
    assert result.status_code == 200 and result.json()["total"] == 1
    assert (
        client.get(
            "/reports",
            headers=headers(user),
            params={"date_from": "2026-10-15", "date_to": "2026-10-14"},
        ).status_code
        == 422
    )
    assert (
        client.get(
            "/reports", headers=headers(user), params={"date_from": "invalid"}
        ).status_code
        == 422
    )


def test_reports_concluded_sent_options_and_csv(
    client, db, document, user, second_user
):
    grant(db, user)
    grant(db, second_user)
    row = db.get(Correspondence, uuid.UUID(document["id"]))
    row.subject = '=HYPERLINK("unsafe")'
    db.commit()
    assert (
        client.get("/reports/options", headers=headers(second_user)).json()["units"]
        == []
    )
    assert (
        client.get("/reports", headers=headers(user), params={"kind": "sent"}).json()[
            "total"
        ]
        == 1
    )
    assert (
        client.post(
            "/correspondences/" + document["id"] + "/conclude",
            headers=headers(second_user),
            json={},
        ).status_code
        == 200
    )
    report = client.get(
        "/reports", headers=headers(second_user), params={"kind": "concluded"}
    ).json()
    assert report["summary"]["concluded"] == 1 and report["summary"]["pending"] == 0
    exported = client.get(
        "/reports/export.csv",
        headers=headers(second_user),
        params={"kind": "concluded"},
    )
    assert exported.status_code == 200
    rows = list(csv.reader(io.StringIO(exported.content.decode("utf-8-sig"))))
    assert (
        len(rows) == 2
        and rows[1][0] == document["route_number"]
        and rows[1][3].startswith("'=")
    )
    assert "institutional_authority_snapshot" not in exported.text
    filtered = client.get(
        "/reports/export.csv",
        headers=headers(second_user),
        params={"kind": "concluded", "search": "missing"},
    )
    assert len(list(csv.reader(io.StringIO(filtered.content.decode("utf-8-sig"))))) == 1


def test_derived_unit_only_notifies_reader_not_normal_user(
    client, db, document, second_user, user, org_unit
):
    scoped, _, _ = reader(db, org_unit)
    response = client.post(
        "/correspondences/" + document["id"] + "/derive",
        headers=headers(second_user),
        json={"to_unit_id": str(org_unit.id)},
    )
    assert response.status_code == 200, response.text
    assert response.json()["current_user_id"] is None
    assert (
        client.get("/notifications", headers=headers(scoped)).json()["items"][0]["type"]
        == "DERIVED"
    )
    assert (
        client.get("/notifications/unread-count", headers=headers(user)).json()[
            "unread"
        ]
        == 0
    )


def test_notification_query_cannot_select_another_user(
    client, document, user, second_user
):
    result = client.get(
        "/notifications", headers=headers(user), params={"user_id": str(second_user.id)}
    ).json()
    assert result["total"] == 0 and result["unread"] == 0


def test_revoked_scope_does_not_get_access_from_notification(
    client, db, document, second_user, second_org_unit
):
    scoped, _, position = reader(db, second_org_unit)
    path = "/correspondences/" + document["id"]
    assert (
        client.post(
            path + "/conclude", headers=headers(second_user), json={}
        ).status_code
        == 200
    )
    assert (
        client.post(path + "/reopen", headers=headers(second_user), json={}).status_code
        == 200
    )
    assert client.get("/notifications", headers=headers(scoped)).json()["total"] == 1
    position.can_view_unit_correspondence = False
    set_position_scope(db, position, False)
    db.commit()
    assert client.get(path, headers=headers(scoped)).status_code == 404


def test_notification_and_document_creation_rollback_together(
    client,
    db,
    user,
    auth_headers,
    document_type,
    second_org_unit,
    second_user,
    monkeypatch,
):
    import app.modules.notifications.service as service

    original = service.notify_movement

    def fail_after_delivery(*args):
        original(*args)
        raise RuntimeError("controlled transaction test")

    monkeypatch.setattr(service, "notify_movement", fail_after_delivery)
    subject = "Rollback " + uuid.uuid4().hex
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type, subject, unit_id=second_org_unit.id, user_id=second_user.id
        ),
    )
    assert response.status_code == 500
    assert (
        db.scalar(select(Correspondence.id).where(Correspondence.subject == subject))
        is None
    )
    assert (
        db.scalar(select(Notification.id).where(Notification.user_id == second_user.id))
        is None
    )


def test_reports_inactive_role_and_employee_filters(
    client, db, document, second_user, user, second_org_unit
):
    role = grant(db, second_user)
    params = {"kind": "received", "employee_id": str(second_user.employee_id)}
    assert (
        client.get("/reports", headers=headers(second_user), params=params).json()[
            "total"
        ]
        == 1
    )
    assert (
        client.get(
            "/reports",
            headers=headers(second_user),
            params={"employee_id": str(user.employee_id)},
        ).status_code
        == 403
    )
    scoped, _, _ = reader(db, second_org_unit)
    grant(db, scoped)
    assert (
        client.get("/reports", headers=headers(scoped), params=params).json()["total"]
        == 1
    )
    role.is_active = False
    db.commit()
    assert client.get("/reports", headers=headers(second_user)).status_code == 403


def test_report_search_literal_wildcards_and_historical_type(
    client,
    db,
    document,
    user,
    auth_headers,
    document_type,
    second_org_unit,
    second_user,
):
    grant(db, user)
    row = db.get(Correspondence, uuid.UUID(document["id"]))
    row.subject = "100% literal"
    db.commit()
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "1000 literal",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
        ),
    )
    assert response.status_code == 201
    report = client.get(
        "/reports", headers=headers(user), params={"search": "%"}
    ).json()
    assert report["total"] == 1 and report["items"][0]["id"] == document["id"]
    document_type.is_active = False
    db.commit()
    options = client.get("/reports/options", headers=headers(user)).json()
    assert str(document_type.id) in {item["id"] for item in options["types"]}
