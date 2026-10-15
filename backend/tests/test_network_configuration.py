import pytest
from fastapi import FastAPI, Response
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.core.config import Settings
from app.core.cors import configure_cors
from app.core import security


def settings(**kwargs):
    return Settings(
        _env_file=None,
        jwt_access_secret="network-test-secret-at-least-32-characters",
        app_env=kwargs.pop("app_env", "development"),
        cors_allow_origins=kwargs.pop("cors_allow_origins", ""),
        cors_allow_origin_regex=kwargs.pop("cors_allow_origin_regex", ""),
        cookie_secure=kwargs.pop("cookie_secure", None),
        cookie_samesite=kwargs.pop("cookie_samesite", "lax"),
        **kwargs,
    )


def client_for(config):
    application = FastAPI()
    configure_cors(application, config)
    @application.get("/health")
    def health():
        return {"status": "ok"}
    return TestClient(application)


@pytest.mark.parametrize("origin", [
    "http://localhost:5000", "http://localhost:5001", "http://localhost:53127",
    "http://127.0.0.1:54321", "https://localhost:61234", "https://127.0.0.1",
])
def test_dev_refresh_preflight_accepts_loopback(origin):
    with client_for(settings()) as client:
        response = client.options("/auth/refresh", headers={
            "Origin": origin, "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type,authorization,x-request-id",
        })
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == origin
    assert response.headers["access-control-allow-credentials"] == "true"
    assert "POST" in response.headers["access-control-allow-methods"]
    assert "x-request-id" in response.headers["access-control-allow-headers"]


@pytest.mark.parametrize("origin", [
    "https://external.example", "http://localhost.evil.example:5000",
    "http://127.0.0.1.evil.example", "http://192.168.1.50:5000", "null",
])
def test_dev_rejects_external_origins_even_with_env_override(origin):
    config = settings(cors_allow_origins=origin, cors_allow_origin_regex=".*")
    with client_for(config) as client:
        response = client.options("/auth/refresh", headers={
            "Origin": origin, "Access-Control-Request-Method": "POST",
        })
    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers


@pytest.mark.parametrize("environment", ["qa", "production"])
def test_same_origin_environments_need_no_external_cors(environment):
    config = settings(app_env=environment)
    assert config.cors_origins_list == []
    assert config.effective_cors_origin_regex is None
    with client_for(config) as client:
        assert client.get("/health").status_code == 200
        response = client.options("/auth/refresh", headers={
            "Origin": "https://external.example", "Access-Control-Request-Method": "POST",
        })
    assert "access-control-allow-origin" not in response.headers


def test_external_compatibility_is_explicit_and_restricted():
    with client_for(settings(app_env="qa", cors_allow_origins="https://trusted.example")) as client:
        response = client.options("/auth/refresh", headers={
            "Origin": "https://trusted.example", "Access-Control-Request-Method": "POST",
        })
        rejected = client.options("/auth/refresh", headers={
            "Origin": "https://untrusted.example", "Access-Control-Request-Method": "POST",
        })
    assert response.headers["access-control-allow-origin"] == "https://trusted.example"
    assert rejected.status_code == 400
    assert "access-control-allow-origin" not in rejected.headers


def test_wildcard_with_credentials_is_invalid():
    with pytest.raises(ValidationError, match="Wildcard"):
        settings(app_env="qa", cors_allow_origins="*")


@pytest.mark.parametrize("environment,secure", [
    ("development", False), ("qa", False), ("production", True),
])
def test_refresh_cookie_and_deletion_match_path_and_security(monkeypatch, environment, secure):
    config = settings(app_env=environment)
    monkeypatch.setattr(security, "get_settings", lambda: config)
    response = Response()
    security.set_refresh_cookie(response, "fictitious-token")
    cookie = response.headers["set-cookie"]
    assert "HttpOnly" in cookie
    assert "Path=/auth" in cookie  # Apache rewrites to /api/auth.
    assert "SameSite=lax" in cookie
    assert ("; Secure" in cookie) == secure
    deleted = Response()
    security.clear_refresh_cookie(deleted)
    assert "Path=/auth" in deleted.headers["set-cookie"]
    assert "Max-Age=0" in deleted.headers["set-cookie"]


def test_production_cannot_disable_secure_cookie():
    with pytest.raises(ValidationError, match="HTTPS"):
        settings(app_env="production", cookie_secure=False)


def test_cross_site_cookie_requires_secure():
    with pytest.raises(ValidationError, match="SameSite=None"):
        settings(cookie_samesite="none", cookie_secure=False)
