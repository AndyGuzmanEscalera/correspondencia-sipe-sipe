import copy
import uuid
import pytest
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.public_tracking_router import limiter
from app.modules.correspondence.public_tracking_service import NOT_FOUND
from tests.test_phase2_operational_documents import actor, body, headers

CODES = ["HOJA_RUTA", "COMUNICADO_INTERNO", "INFORME", "MEMORANDUM", "CIRCULAR"]
PUBLIC_FIELDS = {"found", "route_sheet_number", "status", "status_label", "reference", "received_at", "current_unit", "last_updated_at", "movements"}

@pytest.mark.parametrize("code", CODES)
def test_creation_without_content_automatic_origin_tracking_and_capabilities(client, db, org_unit, second_org_unit, code):
    limiter.clients.clear()
    creator, employee, _ = actor(db, org_unit, "DIRECTOR", permissions=["correspondence.create"] if code == "HOJA_RUTA" else None)
    receiver, receiver_employee, _ = actor(db, second_org_unit, "DIRECTOR")
    payload=body(db, code, employee, second_org_unit)
    payload.pop("subject"); payload.pop("description")
    if code != "HOJA_RUTA":
        payload.pop("reference")
        payload["origin_employee_id"]=str(receiver_employee.id)  # Must be ignored.
    payload["initial_to_user_id"]=str(receiver.id)
    result=client.post("/correspondences", headers=headers(creator), json=payload)
    assert result.status_code == 201, result.text
    data=result.json(); row=db.get(Correspondence, uuid.UUID(data["id"]))
    assert row.origin_employee_id == employee.id
    assert row.description is None
    snapshot=copy.deepcopy(row.document_snapshot)
    public=client.post("/public/correspondence/track", json={"route_sheet_number": data["route_number"]})
    assert public.status_code == 200 and public.json()["found"], public.text
    assert set(public.json()) <= PUBLIC_FIELDS
    assert all(set(m) <= {"date", "status", "label", "unit"} for m in public.json()["movements"])
    assert client.post("/public/correspondence/track", json={"route_sheet_number": data["route_number"][-6:]}).json() == NOT_FOUND
    detail=client.get("/correspondences/"+data["id"], headers=headers(receiver))
    assert detail.status_code == 200, detail.text
    assert detail.json()["can_derive"] is True
    # New creation must not rewrite previously stored data or snapshot.
    row.subject="Historical subject"; row.description="Historical content"; db.commit()
    old_id=row.id
    again=client.post("/correspondences", headers=headers(creator), json=payload)
    assert again.status_code == 201, again.text
    db.expire_all(); old=db.get(Correspondence, old_id)
    assert old.subject == "Historical subject" and old.description == "Historical content"
    assert old.document_snapshot == snapshot
    old.is_active=False; db.commit()
    assert client.post("/public/correspondence/track", json={"route_sheet_number": data["route_number"]}).json() == NOT_FOUND
