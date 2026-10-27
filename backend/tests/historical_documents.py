"""Pre-phase-2 fixture importer, NOT the public creation endpoint.

Legacy behavior tests need historical rows without reopening legacy CREATE.
Operational types always go through the real endpoint. Read/derive/report/PDF
requests in these tests remain real HTTP and use the current authorization.
Separate phase-2 tests assert direct HTTP rejects every legacy type.
"""

import uuid
import httpx
from fastapi import HTTPException
from pydantic import ValidationError
from app.core.database import SessionLocal
from app.core.security import decode_access_token
from app.modules.identity.user import User
from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.schemas import CreateCorrespondenceRequest
from app.modules.correspondence.service import CorrespondenceService


def seed_historical_document(client, path="/correspondences", *, headers, json):
    assert path == "/correspondences"
    with SessionLocal() as db:
        kind = db.get(DocumentType, uuid.UUID(json["document_type_id"]))
        if kind and kind.is_operational:
            return client.post(path, headers=headers, json=json)
        actor = db.get(
            User,
            uuid.UUID(
                decode_access_token(headers["Authorization"].split(" ", 1)[1])["sub"]
            ),
        )
        assert actor and actor.is_active
        try:
            body = CreateCorrespondenceRequest.model_validate(json)
            result = CorrespondenceService(db)._create_routed_correspondence(
                actor, body
            )
            return httpx.Response(201, json=result.model_dump(mode="json"))
        except HTTPException as error:
            db.rollback()
            return httpx.Response(error.status_code, json={"detail": error.detail})
        except ValidationError:
            db.rollback()
            return httpx.Response(
                422, json={"detail": "Historical fixture payload validation failed"}
            )
