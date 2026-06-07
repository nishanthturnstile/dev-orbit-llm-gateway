import os

import pytest


pytestmark = pytest.mark.smoke


FORBIDDEN_RESPONSE_MARKERS = (
    "postgres" "://",
    "postgresql" "://",
    "DATABASE" "_URL",
    "railway" ".internal",
    "Traceback",
    "stack trace",
)


def _base_url():
    base_url = os.getenv("SMOKE_LITELLM_BASE_URL")
    if not base_url:
        pytest.skip("Set SMOKE_LITELLM_BASE_URL to run public-origin policy smoke tests")
    return base_url.rstrip("/")


def _api_key():
    api_key = os.getenv("SMOKE_LITELLM_API_KEY")
    if not api_key:
        pytest.skip("Set SMOKE_LITELLM_API_KEY to run developer-key public-origin policy smoke tests")
    return api_key


def _assert_safe_response(response):
    body = response.text
    assert not any(marker in body for marker in FORBIDDEN_RESPONSE_MARKERS)


def test_missing_auth_is_rejected_publicly():
    httpx = pytest.importorskip("httpx")
    base_url = _base_url()

    response = httpx.post(
        f"{base_url}/v1/chat/completions",
        json={
            "model": "dev-fast",
            "messages": [{"role": "user", "content": "Reply with OK."}],
            "max_tokens": 10,
        },
        timeout=60,
    )

    assert response.status_code in {401, 403}
    _assert_safe_response(response)


def test_invalid_auth_is_rejected_publicly():
    httpx = pytest.importorskip("httpx")
    base_url = _base_url()

    response = httpx.post(
        f"{base_url}/v1/chat/completions",
        headers={"Authorization": "Bearer not-a-valid-phase6-key"},
        json={
            "model": "dev-fast",
            "messages": [{"role": "user", "content": "Reply with OK."}],
            "max_tokens": 10,
        },
        timeout=60,
    )

    assert response.status_code in {401, 403}
    _assert_safe_response(response)


@pytest.mark.parametrize("path", ["/docs", "/redoc", "/openapi.json"])
def test_public_docs_are_blocked(path):
    httpx = pytest.importorskip("httpx")
    base_url = _base_url()

    response = httpx.get(f"{base_url}{path}", timeout=30)

    assert response.status_code in {401, 403, 404}
    _assert_safe_response(response)


@pytest.mark.parametrize(
    "path",
    [
        "/ui",
        "/key/list",
        "/user/info",
        "/team/info",
        "/config/list",
        "/admin",
        "/spend/logs",
    ],
)
def test_developer_key_cannot_access_control_routes(path):
    httpx = pytest.importorskip("httpx")
    base_url = _base_url()
    api_key = _api_key()

    response = httpx.get(
        f"{base_url}{path}",
        headers={"Authorization": f"Bearer {api_key}"},
        timeout=30,
    )

    assert response.status_code in {400, 401, 403, 404, 405}
    _assert_safe_response(response)
