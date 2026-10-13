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
    intake_unit_id: uuid.UUID | None = None
    intake_unit_name: str | None = None
    initial_recipient_employee_ids: list[uuid.UUID] = Field(default_factory=list)
    initial_recipients: list[AuthorityEmployeeResponse] = Field(default_factory=list)
    mayor_display_name: str | None = None
    mayor_employee_id: uuid.UUID | None = None
    mayor: AuthorityEmployeeResponse | None = None
    mayor_validation_error: str | None = None


class UpdateInstitutionalSettingsRequest(BaseModel):
    intake_unit_id: uuid.UUID | None = None
    initial_recipient_employee_ids: list[uuid.UUID] | None = Field(default=None, max_length=100)
    mayor_employee_id: uuid.UUID | None = Field(default=None, description="Referencia al funcionario autoridad institucional. Null elimina la selección; omitir conserva la selección.")
    mayor_display_name: str | None = Field(
        default=None,
        max_length=200,
        description="Texto de la máxima autoridad para documentos nuevos; no cambia el funcionario destinatario EDIE. Vacío elimina el texto personalizado.",
    )
