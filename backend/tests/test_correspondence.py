import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.document_type import DocumentType
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit


def _create_payload(
    document_type: DocumentType,
    subject: str,
    *,
    unit_id: uuid.UUID,
    user_id: uuid.UUID | None = None,
    correspondence_type: str = "EXTERNAL",
    **extra: object,
) -> dict:
    payload: dict = {
        "correspondence_type": correspondence_type,
        "document_type_id": str(document_type.id),
        "subject": subject,
        "priority": "LOW",
        "initial_to_unit_id": str(unit_id),
    }
    if correspondence_type == "EXTERNAL":
        payload["sender_name"] = "Remitente"
    if user_id is not None:
        payload["initial_to_user_id"] = str(user_id)
    payload.update(extra)
    return payload


def test_create_external_to_unit_only(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Solicitud externa a unidad",
            unit_id=second_org_unit.id,
        ),
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["correspondence_type"] == "EXTERNAL"
    assert body["origin_unit_id"] is None
    assert body["origin_user_id"] is None
    assert body["current_unit_id"] == str(second_org_unit.id)
    assert body["current_user_id"] is None
    assert body["route_number"].startswith("HR-")


def test_create_external_to_unit_and_user(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Solicitud externa a usuario",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
            priority="HIGH",
            sender_name="Ciudadano Prueba",
            sender_document="1234567",
            sender_contact="70000000",
        ),
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["current_unit_id"] == str(second_org_unit.id)
    assert body["current_user_id"] == str(second_user.id)


def test_create_internal_with_destination(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Memorándum interno",
            unit_id=second_org_unit.id,
            correspondence_type="INTERNAL",
            priority="MEDIUM",
        ),
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["correspondence_type"] == "INTERNAL"
    assert body["origin_employee_id"] is not None
    assert body["origin_unit_id"] is not None
    assert body["origin_user_id"] is None
    assert body["document_number"] is not None
    assert body["current_unit_id"] == str(second_org_unit.id)


def test_create_internal_without_employee_fails(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    from app.core.security import create_access_token

    user = User(
        id=uuid.uuid4(),
        employee_id=None,
        username=f"noemp_{uuid.uuid4().hex[:8]}",
        password_hash="x",
        is_active=True,
    )
    db.add(user)
    db.commit()
    token, _ = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    response = client.post(
        "/correspondences",
        headers=headers,
        json=_create_payload(
            document_type,
            "No debe crearse",
            unit_id=second_org_unit.id,
            correspondence_type="INTERNAL",
        ),
    )
    assert response.status_code == 422


def test_create_user_not_in_unit_fails(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    user: User,
) -> None:
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Usuario fuera de unidad",
            unit_id=second_org_unit.id,
            user_id=user.id,
        ),
    )
    assert response.status_code == 422
    assert "no pertenece" in response.json()["detail"]


def test_create_inactive_user_fails(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    second_user.is_active = False
    db.commit()

    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Usuario inactivo",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
        ),
    )
    assert response.status_code == 422
    assert "inactivo" in response.json()["detail"]


def test_correspondence_with_inactive_current_user_still_listed(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Responsable luego inactivo",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
        ),
    ).json()

    second_user.is_active = False
    db.commit()

    response = client.get("/correspondences", headers=auth_headers)
    assert response.status_code == 200
    listed = next(item for item in response.json()["items"] if item["id"] == created["id"])
    assert listed["current_unit_id"] == str(second_org_unit.id)
    assert listed["current_user_id"] == str(second_user.id)
    assert listed["current_user_is_active"] is False
    assert listed["current_user_name"] is not None


def test_movements_preserve_inactive_user_names(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Histórico usuario inactivo",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
        ),
    ).json()

    movements_before = client.get(
        f"/correspondences/{created['id']}/movements",
        headers=auth_headers,
    ).json()
    assert movements_before[-1]["to_user_name"] is not None

    second_user.is_active = False
    db.commit()

    movements_after = client.get(
        f"/correspondences/{created['id']}/movements",
        headers=auth_headers,
    ).json()
    assert movements_after[-1]["to_user_name"] == movements_before[-1]["to_user_name"]


def test_create_inactive_unit_fails(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
) -> None:
    inactive_unit = OrganizationalUnit(
        id=uuid.uuid4(),
        code=f"INACTIVA_{uuid.uuid4().hex[:6].upper()}",
        name="Unidad Inactiva",
        is_active=False,
    )
    db.add(inactive_unit)
    db.commit()

    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Unidad inactiva",
            unit_id=inactive_unit.id,
        ),
    )
    assert response.status_code == 422
    assert "no está activa" in response.json()["detail"]


def test_create_generates_created_and_derived_movements(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Movimientos iniciales",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
            initial_instruction="Atender con prioridad",
        ),
    ).json()

    movements = client.get(
        f"/correspondences/{created['id']}/movements",
        headers=auth_headers,
    ).json()
    assert len(movements) == 2
    assert movements[0]["movement_type"] == "CREATED"
    assert movements[0]["sequence_number"] == 1
    assert movements[1]["movement_type"] == "DERIVED"
    assert movements[1]["sequence_number"] == 2
    assert movements[1]["instruction"] == "Atender con prioridad"


def test_create_current_responsible_is_destination(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Responsable destino",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
        ),
    ).json()

    detail = client.get(
        f"/correspondences/{created['id']}",
        headers=auth_headers,
    ).json()
    assert detail["current_unit_id"] == str(second_org_unit.id)
    assert detail["current_user_id"] == str(second_user.id)
    assert detail["current_unit_name"] == second_org_unit.name


def test_list_correspondences(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Para listado",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
            reference="REF-LIST-001",
        ),
    ).json()
    response = client.get("/correspondences", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["total"] >= 1
    assert len(body["items"]) >= 1

    listed = next(item for item in body["items"] if item["id"] == created["id"])
    assert listed["current_unit_id"] == str(second_org_unit.id)
    assert listed["current_user_id"] == str(second_user.id)
    assert listed["current_unit_name"] == second_org_unit.name
    assert listed["current_user_name"] is not None
    assert listed["current_user_is_active"] is True
    assert listed["reference"] == "REF-LIST-001"
    assert listed["document_type_name"] == document_type.name
    assert listed["correspondence_type"] == "EXTERNAL"


def test_inactive_correspondence_excluded_from_operational_list(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(document_type, "Trámite anulado", unit_id=second_org_unit.id),
    ).json()

    correspondence = db.get(Correspondence, uuid.UUID(created["id"]))
    assert correspondence is not None
    correspondence.is_active = False
    db.commit()

    response = client.get("/correspondences", headers=auth_headers)
    assert response.status_code == 200
    ids = [item["id"] for item in response.json()["items"]]
    assert created["id"] not in ids

    detail = client.get(
        f"/correspondences/{created['id']}",
        headers=auth_headers,
    )
    assert detail.status_code == 404


def test_get_detail(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Detalle",
            unit_id=second_org_unit.id,
            priority="HIGH",
        ),
    ).json()
    response = client.get(
        f"/correspondences/{created['id']}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["subject"] == "Detalle"


def test_derive_updates_current_and_movements(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "A derivar",
            unit_id=org_unit.id,
            correspondence_type="INTERNAL",
            priority="MEDIUM",
        ),
    ).json()

    response = client.post(
        f"/correspondences/{created['id']}/derive",
        headers=auth_headers,
        json={
            "to_unit_id": str(second_org_unit.id),
            "to_user_id": str(second_user.id),
            "instruction": "Atender",
        },
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["current_unit_id"] == str(second_org_unit.id)
    assert body["current_user_id"] == str(second_user.id)

    movements = client.get(
        f"/correspondences/{created['id']}/movements",
        headers=auth_headers,
    ).json()
    types = [item["movement_type"] for item in movements]
    assert types.count("CREATED") == 1
    assert types.count("DERIVED") == 2


def test_unauthenticated_returns_401(client: TestClient) -> None:
    response = client.get("/correspondences")
    assert response.status_code == 401


def test_route_number_unique_sequential(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    numbers = []
    for i in range(3):
        response = client.post(
            "/correspondences",
            headers=auth_headers,
            json=_create_payload(document_type, f"Secuencial {i}", unit_id=second_org_unit.id),
        )
        assert response.status_code == 201
        numbers.append(response.json()["route_number"])
    assert len(set(numbers)) == 3


def test_route_number_unique_concurrent(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    def create_one(index: int):
        return client.post(
            "/correspondences",
            headers=auth_headers,
            json=_create_payload(
                document_type,
                f"Concurrente {index}",
                unit_id=second_org_unit.id,
            ),
        )

    with ThreadPoolExecutor(max_workers=2) as executor:
        futures = [executor.submit(create_one, i) for i in range(2)]
        responses = [future.result() for future in as_completed(futures)]

    assert all(response.status_code == 201 for response in responses)
    numbers = [response.json()["route_number"] for response in responses]
    sequences = [response.json()["route_sequence"] for response in responses]
    years = {response.json()["route_year"] for response in responses}

    assert len(years) == 1
    assert len(set(numbers)) == 2
    assert len(set(sequences)) == 2


def test_derive_concurrent_movement_sequences(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
) -> None:
    third_unit = OrganizationalUnit(
        id=uuid.uuid4(),
        code=f"TERCERA_{uuid.uuid4().hex[:6].upper()}",
        name="Unidad Tercera",
        is_active=True,
    )
    db.add(third_unit)
    db.commit()

    created = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Concurrencia derive",
            unit_id=org_unit.id,
            correspondence_type="INTERNAL",
            priority="MEDIUM",
        ),
    ).json()

    def derive_to(unit_id: uuid.UUID):
        return client.post(
            f"/correspondences/{created['id']}/derive",
            headers=auth_headers,
            json={"to_unit_id": str(unit_id), "instruction": "Derivar"},
        )

    with ThreadPoolExecutor(max_workers=2) as executor:
        futures = [
            executor.submit(derive_to, second_org_unit.id),
            executor.submit(derive_to, third_unit.id),
        ]
        responses = [future.result() for future in as_completed(futures)]

    success = [response for response in responses if response.status_code == 200]
    forbidden = [response for response in responses if response.status_code == 403]
    assert len(success) == 1, [response.text for response in responses]
    assert len(forbidden) == 1

    from sqlalchemy import select

    movements = db.scalars(
        select(CorrespondenceMovement)
        .where(CorrespondenceMovement.correspondence_id == uuid.UUID(created["id"]))
        .order_by(CorrespondenceMovement.sequence_number)
    ).all()

    derived = [movement for movement in movements if movement.movement_type == "DERIVED"]
    sequences = [movement.sequence_number for movement in derived]
    assert len(sequences) == 2
    assert len(set(sequences)) == 2
