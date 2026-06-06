import os

import pytest


pytestmark = pytest.mark.smoke


def _smoke_env():
    base_url = os.getenv("SMOKE_LITELLM_BASE_URL")
    api_key = os.getenv("SMOKE_LITELLM_API_KEY")
    model = os.getenv("SMOKE_LITELLM_CHAT_MODEL", "dev-fast")
    if not base_url or not api_key:
        pytest.skip("Set SMOKE_LITELLM_BASE_URL and SMOKE_LITELLM_API_KEY to run smoke tests")
    return base_url.rstrip("/"), api_key, model


def test_streaming_smoke():
    httpx = pytest.importorskip("httpx")
    base_url, api_key, model = _smoke_env()

    with httpx.stream(
        "POST",
        f"{base_url}/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": model,
            "messages": [{"role": "user", "content": "Reply with STREAM_OK."}],
            "max_tokens": 10,
            "stream": True,
        },
        timeout=60,
    ) as response:
        assert response.status_code == 200
        chunks = [chunk for chunk in response.iter_text() if chunk.strip()]

    assert any("data:" in chunk for chunk in chunks)
