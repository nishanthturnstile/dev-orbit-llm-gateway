# LiteLLM virtual-key creation runbook

This runbook records the Phase 5 non-secret process for creating developer or validation virtual keys. Never paste generated virtual keys, the LiteLLM master key, provider keys, database URLs, or private hostnames into docs, chat, issues, screenshots, or logs.

## Phase 5 defaults

| Item | Value |
| --- | --- |
| Admin UI | Disabled with `DISABLE_ADMIN_UI=true` |
| Creation path | LiteLLM API from an approved operator context |
| Master key | Railway sealed variable only; must start with `sk-` |
| Provider scope | OpenAI-backed aliases only |
| `dev-search` | Blocked until a valid approved `PERPLEXITY_API_KEY` passes runtime validation |
| Validation spend cap | USD 1 total for Phase 5 |
| Test key duration | Short-lived, default one hour or less |

## Create a validation key

Use the bundled Phase 5 validator from inside the deployed `litellm-proxy` container or another approved private Railway context. The validator reads `LITELLM_MASTER_KEY` from the runtime environment and does not print generated keys.

```powershell
$railway = Join-Path $env:APPDATA 'npm\railway.cmd'
& $railway ssh --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service litellm-proxy -- python /app/phase5_validate_litellm.py --base-url http://127.0.0.1:4000
```

## Create a developer key later

After Phase 5, an operator may create one key per approved developer with explicit aliases, budgets, duration/rotation policy, and metadata. Deliver the generated key only through the approved secret-sharing channel. Record only non-secret metadata: owner, team, aliases, budget tier, creation date, and rotation date.

Do not enable self-service key creation until a later phase explicitly approves it.
