import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class DocumentTypeResponse(BaseModel):
    id: uuid.UUID
    code: str
    name: str


class DocumentTypeAdminResponse(BaseModel):
    id: uuid.UUID
    code: str
    name: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    created_by_user_id: uuid.UUID | None
    updated_by_user_id: uuid.UUID | None


class CreateDocumentTypeRequest(BaseModel):
    code: str = Field(min_length=1, max_length=50)
    name: str = Field(min_length=1, max_length=200)


class UpdateDocumentTypeRequest(BaseModel):
    name: str = Field(min_length=1, max_length=200)


class EmployeeOptionResponse(BaseModel):
    id: uuid.UUID
    full_name: str
    unit_id: uuid.UUID | None
    unit_name: str | None
    position_name: str | None
    document_number: str | None


class CreateCorrespondenceRequest(BaseModel):
    correspondence_type: Literal["INTERNAL", "EXTERNAL"]
    document_type_id: uuid.UUID
    subject: str | None = Field(default=None, max_length=500)
    reference: str | None = Field(default=None, max_length=200)
    description: str | None = Field(default=None, max_length=10000)
    priority: Literal["HIGH", "MEDIUM", "LOW"]
    origin_employee_id: uuid.UUID | None = None
    sender_name: str | None = Field(default=None, max_length=200)
    sender_document: str | None = Field(default=None, max_length=30)
    sender_contact: str | None = Field(default=None, max_length=50)
    origin_description: str | None = Field(default=None, max_length=300)
    initial_to_unit_id: uuid.UUID
    initial_to_user_id: uuid.UUID | None = None
    initial_instruction: str | None = Field(default=None, max_length=500)


class DeriveCorrespondenceRequest(BaseModel):
    to_unit_id: uuid.UUID
    to_user_id: uuid.UUID | None = None
    instruction: str | None = Field(default=None, max_length=500)
    observation: str | None = None


class CorrespondenceListItem(BaseModel):
    id: uuid.UUID
    route_number: str
    route_year: int
    route_sequence: int
    document_number: str | None
    document_sequence: int | None
    document_year: int | None
    correspondence_type: str
    document_type_code: str
    document_type_name: str
    subject: str
    reference: str | None
    priority: str
    status: str
    current_unit_id: uuid.UUID | None
    current_unit_name: str | None
    current_user_id: uuid.UUID | None
    current_user_name: str | None
    current_user_is_active: bool | None
    cite: str | None
    registered_at: datetime


class CorrespondenceListResponse(BaseModel):
    items: list[CorrespondenceListItem]
    page: int
    page_size: int
    total: int
    total_pages: int


class CorrespondenceDetail(CorrespondenceListItem):
    description: str | None
    sender_name: str | None
    sender_document: str | None
    sender_contact: str | None
    origin_description: str | None
    origin_unit_id: uuid.UUID | None
    origin_unit_name: str | None
    origin_user_id: uuid.UUID | None
    origin_user_name: str | None
    origin_employee_id: uuid.UUID | None
    origin_employee_name: str | None
    current_unit_id: uuid.UUID | None
    current_user_id: uuid.UUID | None
    cite_sequence: int | None
    cite_year: int | None
    concluded_at: datetime | None
    reopened_at: datetime | None
    created_by_user_id: uuid.UUID
    created_by_username: str


class CorrespondenceAttachmentResponse(BaseModel):
    id: uuid.UUID
    correspondence_id: uuid.UUID
    original_filename: str | None
    mime_type: str | None
    size_bytes: int | None
    sha256: str | None
    is_active: bool
    created_by_user_id: uuid.UUID
    created_by_username: str | None
    created_at: datetime
    deleted_at: datetime | None


class CorrespondenceMovementResponse(BaseModel):
    id: uuid.UUID
    sequence_number: int
    movement_type: str
    from_unit_name: str | None
    from_user_name: str | None
    to_unit_name: str | None
    to_user_name: str | None
    instruction: str | None
    observation: str | None
    created_by_username: str
    created_at: datetime
    cancelled_at: datetime | None
    cancellation_reason: str | None
