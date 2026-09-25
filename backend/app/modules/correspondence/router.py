import io
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, Query, UploadFile, status
from fastapi.responses import Response, StreamingResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.auth.dependencies import get_current_user
from app.modules.correspondence.attachment_service import CorrespondenceAttachmentService
from app.modules.correspondence.schemas import (
    CorrespondenceAttachmentResponse,
    CorrespondenceDetail,
    CorrespondenceInboxCountsResponse,
    CorrespondenceListResponse,
    CorrespondenceSentCountResponse,
    CorrespondenceMovementResponse,
    CorrespondenceLifecycleRequest,
    CreateCorrespondenceRequest,
    DeriveCorrespondenceRequest,
    DocumentTypeResponse,
    EmployeeOptionResponse,
)
from app.modules.correspondence.service import CorrespondenceService
from app.modules.identity.user import User

router = APIRouter(prefix="/correspondences", tags=["correspondences"])
catalog_router = APIRouter(tags=["correspondences"])


def _service(db: Annotated[Session, Depends(get_db)]) -> CorrespondenceService:
    return CorrespondenceService(db)


def _attachment_service(
    db: Annotated[Session, Depends(get_db)],
) -> CorrespondenceAttachmentService:
    return CorrespondenceAttachmentService(db)


@catalog_router.get("/document-types", response_model=list[DocumentTypeResponse])
def list_document_types(
    service: Annotated[CorrespondenceService, Depends(_service)],
    _user: Annotated[User, Depends(get_current_user)],
) -> list[DocumentTypeResponse]:
    return service.list_document_types()


@catalog_router.get("/employees", response_model=list[EmployeeOptionResponse])
def list_active_employees(
    service: Annotated[CorrespondenceService, Depends(_service)],
    _user: Annotated[User, Depends(get_current_user)],
) -> list[EmployeeOptionResponse]:
    return service.list_active_employees()


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


@router.get("/inbox", response_model=CorrespondenceListResponse)
def list_inbox(
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
    scope: str = Query(..., pattern="^(mine|unit)$"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
) -> CorrespondenceListResponse:
    return service.list_inbox(
        user,
        scope=scope,
        page=page,
        page_size=page_size,
        search=search,
    )


@router.get("/inbox/counts", response_model=CorrespondenceInboxCountsResponse)
def get_inbox_counts(
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> CorrespondenceInboxCountsResponse:
    return service.get_inbox_counts(user)


@router.get("/sent", response_model=CorrespondenceListResponse)
def list_sent(
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    status: str | None = Query(default=None),
) -> CorrespondenceListResponse:
    return service.list_sent(
        user,
        page=page,
        page_size=page_size,
        search=search,
        status_filter=status,
    )


@router.get("/sent/count", response_model=CorrespondenceSentCountResponse)
def get_sent_count(
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> CorrespondenceSentCountResponse:
    return service.get_sent_count(user)


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


@router.post("/{correspondence_id}/conclude", response_model=CorrespondenceDetail)
def conclude_correspondence(
    correspondence_id: uuid.UUID,
    body: CorrespondenceLifecycleRequest,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> CorrespondenceDetail:
    return service.conclude_correspondence(user, correspondence_id, body)


@router.post("/{correspondence_id}/reopen", response_model=CorrespondenceDetail)
def reopen_correspondence(
    correspondence_id: uuid.UUID,
    body: CorrespondenceLifecycleRequest,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> CorrespondenceDetail:
    return service.reopen_correspondence(user, correspondence_id, body)


@router.get("/{correspondence_id}/encadenamiento.pdf")
def download_encadenamiento_pdf(
    correspondence_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceService, Depends(_service)],
) -> StreamingResponse:
    del user
    pdf_bytes, filename = service.generate_encadenamiento_pdf_bytes(
        correspondence_id,
        active_only=True,
    )
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'inline; filename="{filename}"',
        },
    )


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


@router.get(
    "/{correspondence_id}/attachments",
    response_model=list[CorrespondenceAttachmentResponse],
)
def list_attachments(
    correspondence_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceAttachmentService, Depends(_attachment_service)],
) -> list[CorrespondenceAttachmentResponse]:
    del user
    return service.list_attachments(correspondence_id, active_only=True)


@router.post(
    "/{correspondence_id}/attachments",
    response_model=CorrespondenceAttachmentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_attachment(
    correspondence_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceAttachmentService, Depends(_attachment_service)],
    file: UploadFile = File(...),
) -> CorrespondenceAttachmentResponse:
    return await service.upload_attachment(
        user,
        correspondence_id,
        file,
        active_only=True,
    )


@router.get("/{correspondence_id}/attachments/{attachment_id}/download")
def download_attachment(
    correspondence_id: uuid.UUID,
    attachment_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceAttachmentService, Depends(_attachment_service)],
) -> Response:
    del user
    payload, filename, mime_type = service.download_attachment(
        correspondence_id,
        attachment_id,
        active_only=True,
    )
    return Response(
        content=payload,
        media_type=mime_type,
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )


@router.delete(
    "/{correspondence_id}/attachments/{attachment_id}",
    response_model=CorrespondenceAttachmentResponse,
)
def deactivate_attachment(
    correspondence_id: uuid.UUID,
    attachment_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    service: Annotated[CorrespondenceAttachmentService, Depends(_attachment_service)],
) -> CorrespondenceAttachmentResponse:
    return service.deactivate_attachment(
        user,
        correspondence_id,
        attachment_id,
        active_only=True,
    )
