from pydantic import BaseModel, Field


class InstitutionalSettingsResponse(BaseModel):
    mayor_display_name: str | None = None


class UpdateInstitutionalSettingsRequest(BaseModel):
    mayor_display_name: str | None = Field(
        default=None,
        max_length=200,
        description="Nombre del alcalde/alcaldesa para documentos (encadenamiento).",
    )
