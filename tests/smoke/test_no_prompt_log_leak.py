import os

import pytest


pytestmark = pytest.mark.smoke


def test_no_prompt_log_leak_placeholder():
    if not os.getenv("SMOKE_LOG_QUERY_COMMAND"):
        pytest.skip("Set SMOKE_LOG_QUERY_COMMAND to run prompt/log leakage validation")

    pytest.fail("Prompt/log leakage smoke flow must be implemented with a sanitized log query command")
