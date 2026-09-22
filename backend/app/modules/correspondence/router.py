import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.auth.dependencies import get_current_user
from app.modules.correspondence.schemas import (
    CorrespondenceDetail,
    CorrespondenceListResponse,
    CorrespondenceMovementResponse,
    CreateCorrespondenceRequest,
    DeriveCorrespondenceRequest,
    DocumentTypeResponse,
)
from app.modules.correspondence.service import CorrespondenceService
from app.modules.identity.user import User

router = APIRouter(prefix="/correspondences", tags=["correspondences"])
catalog_router = APIRouter(tags=["correspondences"])


def _service(db: Annotated[Session, Depends(get_db)]) -> CorrespondenceService:
    return CorrespondenceService(db)


@catalog_router.get("/document-types", response_model=list[DocumentTypeResponse])
def list_document_types(
    service: Annotated[CorrespondenceService, Depends(_service)],
    _user: Annotated[User, Depends(get_current_user)],
) -> list[DocumentTypeResponse]:
    return service.list_document_types()


@router.post(
    "",
    response_model=CorrespondenceDetail,
    status_code=status.HTTP_201_CREATED,
)
def create_correspondence(
    body: CreateCorrespondenceRequest,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> CorrespondenceDetail:
    return service.create_correspondence(user, body)


@router.get("", response_model=CorrespondenceListResponse)
def list_correspondences(
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    status: str | None = Query(default=None),
    correspondence_type: str | None = Query(default=None),
    search: str | None = Query(default=None),
) -> CorrespondenceListResponse:
    del user
    return service.list_correspondences(
        page=page,
        page_size=page_size,
        status_filter=status,
        correspondence_type=correspondence_type,
        search=search,
        active_only=True,
    )


@router.get("/{correspondence_id}", response_model=CorrespondenceDetail)
def get_correspondence(
    correspondence_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> CorrespondenceDetail:
    del user
    return service.get_correspondence(correspondence_id, active_only=True)


@router.post("/{correspondence_id}/derive", response_model=CorrespondenceDetail)
def derive_correspondence(
    correspondence_id: uuid.UUID,
    body: DeriveCorrespondenceRequest,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> CorrespondenceDetail:
    return service.derive_correspondence(user, correspondence_id, body)


@router.get(
    "/{correspondence_id}/movements",
    response_model=list[CorrespondenceMovementResponse],
)
def list_movements(
    correspondence_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> list[CorrespondenceMovementResponse]:
    del user
    return service.list_movements(correspondence_id, active_only=True)
