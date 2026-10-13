import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.mark.parametrize("method", ["GET", "PATCH"])
def test_internal_error_has_cors_and_safe_body(method):
    async def broken():
        raise RuntimeError("PRIVATE_TRACE_AND_DATABASE_DETAILS")
    path = "/_test_internal_error"
    app.add_api_route(path, broken, methods=[method])
    route = app.router.routes[-1]
    try:
        with TestClient(app, raise_server_exceptions=False) as client:
            response = client.request(method, path, headers={"Origin": "http://localhost:57875"})
            assert response.status_code == 500
            assert response.headers["access-control-allow-origin"] == "http://localhost:57875"
            assert response.headers["access-control-allow-credentials"] == "true"
            assert response.json() == {"detail": "Error del servidor. Intente nuevamente."}
            assert "PRIVATE_TRACE" not in response.text
    finally:
        app.router.routes.remove(route)
