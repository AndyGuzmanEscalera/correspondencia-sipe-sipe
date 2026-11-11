"""Pages/API CORS and cookie contracts. Entirely in-memory; no DB/conftest."""
import pytest
from fastapi import FastAPI, Request, Response
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.core.config import Settings
from app.core.cors import configure_cors
from app.core import security

FRONTEND = "https://correspondencia.sipesipe.gob.bo"
API = "https://api-correspondencia.sipesipe.gob.bo"


def settings(**overrides):
    return Settings(_env_file=None, jwt_access_secret="synthetic-pages-contract-secret-long-enough",
                    app_env="production", cors_allow_origins=overrides.pop("cors_allow_origins", FRONTEND),
                    **overrides)


def client_for(config, monkeypatch):
    monkeypatch.setattr(security, "get_settings", lambda: config)
    app = FastAPI()
    configure_cors(app, config)

    @app.post("/auth/login")
    def login(response: Response):
        security.set_refresh_cookie(response, "synthetic-initial")
        return {"authenticated": True}

    @app.post("/auth/refresh")
    def refresh(request: Request, response: Response):
        assert request.cookies.get("refresh_token") == "synthetic-initial"
        security.set_refresh_cookie(response, "synthetic-rotated")
        return {"refreshed": True}

    @app.post("/auth/logout")
    def logout(request: Request, response: Response):
        assert request.cookies.get("refresh_token") == "synthetic-rotated"
        security.clear_refresh_cookie(response)
        return {"logged_out": True}

    return TestClient(app, base_url=API)


@pytest.mark.parametrize("route", ["/auth/login", "/auth/refresh", "/auth/logout"])
def test_pages_preflight_allows_exact_origin_and_credentials(monkeypatch, route):
    with client_for(settings(), monkeypatch) as client:
        response = client.options(route, headers={
            "Origin": FRONTEND, "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "authorization,content-type",
        })
        assert response.status_code == 200
        assert response.headers["access-control-allow-origin"] == FRONTEND
        assert response.headers["access-control-allow-credentials"] == "true"
        assert "Origin" in response.headers["vary"]


@pytest.mark.parametrize("origin", [
    "https://evil.example", "https://correspondencia.sipesipe.gob.bo.evil.example",
    "https://sipesipe-correspondencia.pages.dev", "null",
])
def test_unconfigured_origins_are_not_implicitly_trusted(monkeypatch, origin):
    with client_for(settings(), monkeypatch) as client:
        response = client.options("/auth/refresh", headers={
            "Origin": origin, "Access-Control-Request-Method": "POST",
        })
        assert response.status_code == 400
        assert "access-control-allow-origin" not in response.headers


def test_cookie_login_refresh_logout_contract_over_https(monkeypatch):
    with client_for(settings(), monkeypatch) as client:
        headers = {"Origin": FRONTEND}
        login = client.post("/auth/login", headers=headers)
        refresh = client.post("/auth/refresh", headers=headers)
        logout = client.post("/auth/logout", headers=headers)
        for response in (login, refresh, logout):
            assert response.status_code == 200
            assert response.headers["access-control-allow-origin"] == FRONTEND
            assert response.headers["access-control-allow-credentials"] == "true"
            cookie = response.headers["set-cookie"]
            assert "HttpOnly" in cookie and "Secure" in cookie
            assert "SameSite=lax" in cookie and "Path=/auth" in cookie
            assert "Domain=" not in cookie  # API-host-only, never parent-domain cookies.
        assert "synthetic-rotated" in refresh.headers["set-cookie"]
        assert "Max-Age=0" in logout.headers["set-cookie"]
        assert not client.cookies.get("refresh_token")
        # The retained API gateway maps /api/auth -> /auth and rewrites the path.


def test_wildcard_credentials_still_rejected():
    with pytest.raises(ValidationError, match="Wildcard"):
        settings(cors_allow_origins="*")


def test_production_cookie_cannot_be_insecure():
    with pytest.raises(ValidationError, match="HTTPS"):
        settings(cookie_secure=False)
