from functools import lru_cache

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = Field(default="correspondencia-api")
    app_version: str = Field(default="0.1.0")
    api_prefix: str = Field(default="")

    postgres_db: str = Field(default="correspondencia_sipe")
    postgres_user: str = Field(default="sipe_app")
    postgres_password: str = Field(default="")
    postgres_host: str = Field(default="localhost")
    postgres_port: int = Field(default=5432)

    database_url: str = Field(default="")

    cors_allow_origins: str = Field(default="")
    cors_allow_credentials: bool = Field(default=True)

    jwt_access_secret: str = Field(default="")
    jwt_issuer: str = Field(default="correspondencia-api")
    jwt_audience: str = Field(default="correspondencia-web")
    access_token_ttl_minutes: int = Field(default=15)

    refresh_token_ttl_days: int = Field(default=7)

    cookie_name: str = Field(default="refresh_token")
    cookie_path: str = Field(default="/auth")
    cookie_secure: bool = Field(default=False)
    cookie_samesite: str = Field(default="lax")

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_allow_origins.split(",") if o.strip()]

    @property
    def effective_database_url(self) -> str:
        if self.database_url:
            return self.database_url
        return (
            f"postgresql+psycopg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )

    @field_validator("cookie_samesite")
    @classmethod
    def _validate_cookie_samesite(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in {"lax", "strict", "none"}:
            raise ValueError(
                "cookie_samesite must be one of: lax, strict, none"
            )
        return normalized

    @field_validator("jwt_access_secret")
    @classmethod
    def _validate_jwt_access_secret(cls, value: str) -> str:
        # Reject empty / whitespace-only / too-short secrets at startup.
        # HS256 requires entropy equivalent to 256 bits, ~32 ASCII chars minimum.
        if not value or not value.strip():
            raise ValueError(
                "JWT_ACCESS_SECRET is required: provide a non-empty value via .env or environment"
            )
        if len(value) < 32:
            raise ValueError(
                "JWT_ACCESS_SECRET must be at least 32 characters long (HS256)"
            )
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
