"""Unit tests for the HTTPS biometric API client. Never contact the real API."""
import json

import httpx
import pytest

from app.modules.rrhh.api_client.client import BiometricApiClient
from app.modules.rrhh.api_client.config import ApiConfig
from app.modules.rrhh.api_client.errors import BiometricApiError
from app.modules.rrhh.biometric_service import BiometricService
from app.modules.rrhh.reader.records import attendance_record
from types import SimpleNamespace
from datetime import datetime


def config(**overrides):
    values = dict(url="https://biometric.example.test", token="test-token",
                  timeout=5, device_id="alcaldia-central")
    values.update(overrides)
    return ApiConfig(**values)


def page(records, *, total=None, offset=0, limit=20, device_id="alcaldia-central"):
    total = len(records) if total is None else total
    return {
        "device_id": device_id,
        "filters": {"date": None, "from": None, "to": None, "ci": None},
        "total": total,
        "offset": offset,
        "limit": limit,
        "count": len(records),
        "records": records,
    }


def record(user="12970173", stamp="2026-11-11T03:40:56", status=15, punch=255, uid=42748):
    return {
        "device_id": "alcaldia-central",
        "uid": uid,
        "user_id": user,
        "timestamp": stamp,
        "date": stamp[:10],
        "time": stamp[11:],
        "status": status,
        "punch": punch,
        "record_id": "external-ignored",
    }


class Router:
    def __init__(self, handlers):
        self.handlers = handlers
        self.calls = []

    def __call__(self, request):
        self.calls.append((request.method, request.url.path, dict(request.url.params),
                           request.headers.get("authorization")))
        handler = self.handlers.get((request.method, request.url.path))
        if handler is None:
            return httpx.Response(404, json={"detail": "missing stub"})
        return handler(request)


def client_for(handlers):
    router = Router(handlers)
    transport = httpx.MockTransport(router)
    return BiometricApiClient(config(), transport=transport), router


def test_health_ok():
    api, router = client_for({("GET", "/health"): lambda r: httpx.Response(200, json={"status": "ok"})})
    assert api.health() == {"status": "ok"}
    assert router.calls[0][1] == "/health"


def test_device_ok():
    payload = {"device_id": "alcaldia-central", "connected": True, "device_name": "uFace"}
    api, _ = client_for({("GET", "/device"): lambda r: httpx.Response(200, json=payload)})
    assert api.get_device()["connected"] is True


def test_users_ok():
    payload = {"device_id": "alcaldia-central", "total": 1,
               "users": [{"uid": 400, "user_id": "12970173", "name": "Ana"}]}
    api, _ = client_for({("GET", "/users"): lambda r: httpx.Response(200, json=payload)})
    assert api.get_users() == payload["users"]


@pytest.mark.parametrize("params,expected", [
    ({"date": "2026-11-11"}, {"date": "2026-11-11", "limit": "500", "offset": "0"}),
    ({"from_date": "2026-11-01", "to_date": "2026-11-11"},
     {"from": "2026-11-01", "to": "2026-11-11", "limit": "500", "offset": "0"}),
    ({"ci": "12970173"}, {"ci": "12970173", "limit": "500", "offset": "0"}),
    ({"ci": "12970173", "from_date": "2026-11-01", "to_date": "2026-11-11"},
     {"ci": "12970173", "from": "2026-11-01", "to": "2026-11-11", "limit": "500", "offset": "0"}),
])
def test_attendance_filters(params, expected):
    api, router = client_for({
        ("GET", "/attendance"): lambda r: httpx.Response(200, json=page([record()])),
    })
    api.get_attendance(**params)
    assert router.calls[0][2] == expected


def test_attendance_empty():
    api, _ = client_for({
        ("GET", "/attendance"): lambda r: httpx.Response(200, json=page([])),
    })
    assert api.download_attendance() == []


def test_pagination_walks_until_total():
    pages = {
        0: page([record("1"), record("2")], total=3, offset=0, limit=2),
        2: page([record("3")], total=3, offset=2, limit=2),
    }

    def handler(request):
        offset = int(request.url.params["offset"])
        return httpx.Response(200, json=pages[offset])

    api, router = client_for({("GET", "/attendance"): handler})
    rows = api.download_attendance(page_size=2)
    assert [row["user_id"] for row in rows] == ["1", "2", "3"]
    assert [call[2]["offset"] for call in router.calls] == ["0", "2"]


def test_pagination_stops_on_mid_page_error():
    def handler(request):
        if request.url.params["offset"] == "0":
            return httpx.Response(200, json=page([record("1")], total=3, offset=0, limit=1))
        return httpx.Response(502, json={"detail": "device down"})

    api, _ = client_for({("GET", "/attendance"): handler})
    with pytest.raises(BiometricApiError) as error:
        api.download_attendance(page_size=1)
    assert error.value.code == "biometric_device_unreachable"


def test_api_401_maps_to_unauthorized():
    api, _ = client_for({("GET", "/device"): lambda r: httpx.Response(401, json={"detail": "bad token"})})
    with pytest.raises(BiometricApiError) as error:
        api.get_device()
    assert error.value.code == "biometric_api_unauthorized"


def test_api_502_maps_to_device_unreachable():
    api, _ = client_for({("GET", "/device"): lambda r: httpx.Response(502, json={"detail": "down"})})
    with pytest.raises(BiometricApiError) as error:
        api.get_device()
    assert error.value.code == "biometric_device_unreachable"


def test_timeout_maps_to_timeout():
    def boom(_request):
        raise httpx.ReadTimeout("slow")

    api, _ = client_for({("GET", "/health"): boom})
    with pytest.raises(BiometricApiError) as error:
        api.health()
    assert error.value.code == "biometric_api_timeout"


def test_network_failure_maps_to_unreachable():
    def boom(_request):
        raise httpx.ConnectError("dns")

    api, _ = client_for({("GET", "/health"): boom})
    with pytest.raises(BiometricApiError) as error:
        api.health()
    assert error.value.code == "biometric_api_unreachable"


def test_device_id_mismatch_is_rejected():
    api, _ = client_for({
        ("GET", "/device"): lambda r: httpx.Response(
            200, json={"device_id": "other-clock", "connected": True}),
    })
    with pytest.raises(BiometricApiError) as error:
        api.get_device()
    assert error.value.code == "biometric_device_id_mismatch"


def test_raw_status_and_punch_are_preserved():
    raw = record(status=25, punch=255)
    api, _ = client_for({
        ("GET", "/attendance"): lambda r: httpx.Response(200, json=page([raw])),
    })
    got = api.download_attendance()[0]
    assert got["status"] == 25 and got["punch"] == 255


def test_local_record_id_ignores_external_id_for_dedup_compatibility():
    # Historical SOURCE_API rows used the local SHA-256 identity. Keep that algorithm
    # so re-downloading the same event does not create duplicates.
    stamp = datetime.fromisoformat("2026-11-11T03:40:56")
    local = attendance_record(SimpleNamespace(
        user_id="12970173", timestamp=stamp, status=15, punch=255, uid=1,
        record_id="external-ignored"), "alcaldia-central")
    assert local["record_id"] != "external-ignored"
    again = attendance_record(SimpleNamespace(
        user_id="12970173", timestamp=stamp, status=15, punch=255, uid=99,
        record_id="another-external"), "alcaldia-central")
    assert again["record_id"] == local["record_id"]


def test_service_download_uses_range_and_optional_ci():
    api, router = client_for({
        ("GET", "/attendance"): lambda r: httpx.Response(200, json=page([record()])),
    })
    service = BiometricService(api)
    from datetime import date
    service.download(start_date=date(2026, 11, 1), end_date=date(2026, 11, 11), ci="12970173")
    assert router.calls[0][2]["from"] == "2026-11-01"
    assert router.calls[0][2]["to"] == "2026-11-11"
    assert router.calls[0][2]["ci"] == "12970173"


def test_token_is_sent_as_bearer_and_never_logged_in_error_text():
    api, router = client_for({
        ("GET", "/users"): lambda r: httpx.Response(403, json={"detail": "nope"}),
    })
    with pytest.raises(BiometricApiError) as error:
        api.get_users()
    assert router.calls[0][3] == "Bearer test-token"
    assert "test-token" not in error.value.message
    assert "test-token" not in repr(error.value)
