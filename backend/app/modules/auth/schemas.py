from pydantic import BaseModel, ConfigDict, EmailStr, Field


class LoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=50)
    password: str = Field(min_length=1, max_length=255)


class UserBrief(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    username: str
    email: str | None = None
    employee_id: str | None = None
    is_active: bool


class AuthResponse(BaseModel):
    access_token: str
    expires_in: int
    user: UserBrief | None = None


class RefreshResponse(BaseModel):
    access_token: str
    expires_in: int


class MeResponse(UserBrief):
    pass
