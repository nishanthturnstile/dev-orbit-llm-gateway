import os

import pytest


pytestmark = pytest.mark.smoke


def test_cloudflare_block_placeholder():
    if os.getenv("SMOKE_CLOUDFLARE_HARDENING_ENABLED") != "true":
        pytest.skip("Cloudflare hardening is deferred and disabled by default")

    pytest.fail("Cloudflare block smoke flow must be implemented after Cloudflare hardening is approved")
