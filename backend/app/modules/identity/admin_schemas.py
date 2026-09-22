import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class UserAdminResponse(BaseModel):
    id: uuid.UUID
    username: str
    email: str | None
    employee_id: uuid.UUID | None
    employee_name: str | None
    unit_name: str | None
    is_active: bool
    role_codes: list[str]
    created_at: datetime
    updated_at: datetime
    created_by_user_id: uuid.UUID | None
    updated_by_user_id: uuid.UUID | None


class CreateUserRequest(BaseModel):
    username: str = Field(min_length=1, max_length=50)
    email: str | None = Field(default=None, max_length=150)
    employee_id: uuid.UUID
    initial_password: str = Field(min_length=8, max_length=255)
    role_ids: list[uuid.UUID] = Field(min_length=1)


class UpdateUserRequest(BaseModel):
    username: str = Field(min_length=1, max_length=50)
    email: str | None = Field(default=None, max_length=150)
    employee_id: uuid.UUID
    role_ids: list[uuid.UUID] = Field(min_length=1)
