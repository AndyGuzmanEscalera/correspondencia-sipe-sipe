import uuid
from pydantic import BaseModel, Field


class AuthorityEmployeeResponse(BaseModel):
    employee_id: uuid.UUID
    user_id: uuid.UUID
    unit_id: uuid.UUID
    employee_name: str
    position_name: str
    unit_name: str
    document_number: str | None = None


class InstitutionalSettingsResponse(BaseModel):
    mayor_display_name: str | None = None
    mayor_employee_id: uuid.UUID | None = None
    mayor: AuthorityEmployeeResponse | None = None
    mayor_validation_error: str | None = None


class UpdateInstitutionalSettingsRequest(BaseModel):
    mayor_employee_id: uuid.UUID | None = Field(default=None, description="Referencia al funcionario autoridad institucional. Null elimina la selección; omitir conserva la selección.")
    mayor_display_name: str | None = Field(
        default=None,
        max_length=200,
        description="Campo legacy sin efecto en EDIE/PDF. Usar mayor_employee_id.",
    )
