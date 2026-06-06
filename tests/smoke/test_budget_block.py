import os

import pytest


pytestmark = pytest.mark.smoke


def test_budget_block_smoke_placeholder():
    if not os.getenv("SMOKE_LITELLM_BUDGET_EXHAUSTED_KEY"):
        pytest.skip("Set SMOKE_LITELLM_BUDGET_EXHAUSTED_KEY after creating a budget-limited test key")

    pytest.fail("Budget-block smoke flow must be implemented with an explicit exhausted test key")
