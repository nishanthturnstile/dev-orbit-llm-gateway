# Phase 0 disposable proof notes

**Status:** In progress; Railway + LiteLLM native-auth proof is deployed, final chat/streaming validation is blocked by provider credits  
**Roadmap phase:** Phase 0 - Launch-blocker validation and disposable proof spike  
**Tracker:** `docs\operations\implementation-status.md`

## Provisioning gate

Disposable Railway project, Postgres, and `litellm-proxy` resources were created after operator approval. The obsolete `cloudflared-tunnel` service was deleted because the selected Phase 0 direction is LiteLLM-native public-origin authentication.

Provisioning inputs and current approval status:

| Required input | Status |
| --- | --- |
| Operator approval for disposable proof project creation | Done |
| Operator approval for cost-bearing services/databases | Done |
| Railway workspace and billing confirmation | Done for Phase 0; durable billing revisited before staging |
| Public-origin LiteLLM-native-auth risk acceptance | Done for Phase 0 |
| Admin UI exposure/control decision | Done for Phase 0; strong LiteLLM admin credentials, staging/production hardening deferred |
| Low-cost provider/model selected and secret placed outside source control | Done for Phase 0 config; OpenAI `gpt-4o-mini` / `dev-fast` selected, valid key injected, credits unavailable |
| Proof spike budget cap | Done for Phase 0; USD 5 cap, USD 3 warning review |
| Teardown owner and deadline | Done; operator/project owner, within 24 hours after funded validation or by 2026-06-13 if deferred |

## Planned disposable proof shape

The proof should validate the smallest useful path:

1. Disposable Railway app service for `litellm-proxy`.
2. Disposable Railway managed Postgres for LiteLLM state.
3. Public Railway/custom endpoint for `litellm-proxy`.
4. One low-cost provider/model configured only through Railway variables.
5. One supported developer tool or OpenAI-compatible SDK client calling `/v1/chat/completions`.
6. Streaming request through LiteLLM virtual-key auth.
7. Missing/invalid key rejection.
8. Developer virtual-key denial for admin/control routes.

`litellm-proxy` currently has a temporary public Railway proof endpoint protected by LiteLLM native authentication. Keep it limited to Phase 0 validation until native-auth controls, admin controls, budgets, rate limits, metadata-only logging, secret handling, and teardown timing are approved.

## Resource inventory

| Resource | ID / name | Environment | Status | Teardown status |
| --- | --- | --- | --- | --- |
| Railway project | `internal-llm-gateway-phase0` (`c642da87-d8e5-40ec-ba54-bcd02ec1c64b`) | Default | Created | Pending final teardown |
| Railway `litellm-proxy` service | `litellm-proxy` (`f48fbf0d-706c-4acf-99cf-dc0e6d5febb9`) | Default / Railway `production` | Deployed; latest validated deployment `09a513aa-d2f1-4eb0-bc29-fba29251cd07` is `SUCCESS` | Pending final teardown |
| Railway `litellm-postgres` service | `Postgres` (`0a46a957-c35f-4d8c-8efe-ad31dba1c9fc`) | Default / Railway `production` | Created; latest deployment `SUCCESS`; readiness check reports DB connected | Pending final teardown |
| Railway `cloudflared-tunnel` service | `cloudflared-tunnel` (`30086a34-1c86-4d53-b685-e43f18dd5174`) | `production` | Deleted after auth pivot | Done |
| Cloudflare Tunnel | Not needed for current design | N/A | Deferred hardening option | N/A |
| Provider proof key/model | OpenAI `gpt-4o-mini` exposed as `dev-fast` | Railway variable / LiteLLM config | Key is valid but lacks credits; chat/streaming return provider quota `429` | Revoke/replace after proof |

## Test command log

Only non-secret commands and sanitized outputs may be recorded here.

| Test | Command / method | Status | Evidence |
| --- | --- | --- | --- |
| Railway preflight | Read-only CLI checks | Done | Railway CLI is installed/authenticated and current linked project/service visibility works; see `docs\decisions\phase-0-launch-blockers.md`. |
| Initial disposable resource creation | Railway CLI `init` and `add` commands after operator approval | Done | Project, Postgres, `litellm-proxy`, and `cloudflared-tunnel` were created. |
| Postgres deployment health | `railway deployment list --service Postgres --limit 1 --json` | Done | Latest Postgres deployment status is `SUCCESS`. |
| LiteLLM proof artifacts | `services\litellm\Dockerfile`; `config\litellm\config.yaml` | Done | Dockerfile uses digest-pinned `docker.litellm.ai/berriai/litellm-database:main-stable@sha256:bc57f7cdc09f29d8251846e4f4ae20503760c3c03fc5ae3a9e49eb87cc9fd0f0`; config maps `dev-fast` to `openai/gpt-4o-mini` via `OPENAI_API_KEY` env var and disables message logging. |
| Non-secret Railway service config | Railway CLI service config and variable set commands | Done | `litellm-proxy` uses Dockerfile builder, `services/litellm/Dockerfile`, `/health/readiness`, timeout `300`, `DATABASE_URL=${{Postgres.DATABASE_URL}}`, `PORT=4000`, `NO_DOCS=True`, `NO_REDOC=True`, `ENVIRONMENT=phase0`, and `UI_USERNAME=admin`. |
| Secret-setting helper | `scripts\phase0-set-railway-secrets.ps1` | Ready | Prompts locally for `LITELLM_MASTER_KEY`, `OPENAI_API_KEY`, and `UI_PASSWORD`, then sends them to Railway via stdin without printing values. |
| LiteLLM deployment | Railway deployment `09a513aa-d2f1-4eb0-bc29-fba29251cd07` | Done | Deployment status `SUCCESS` after redeploy with updated OpenAI key. |
| LiteLLM readiness | `GET /health/readiness` through public native-auth proof path | Done | Returned `200` with `{"status":"healthy","db":"connected"}`. |
| Missing key rejection | `POST /v1/chat/completions` without `Authorization` | Done | Returned `401` auth error. |
| Invalid key rejection | `POST /v1/chat/completions` with invalid key | Done | Returned `401` token-not-found error. |
| Docs disabled | `GET /docs` and `GET /redoc` | Done | Both returned `404`. |
| Temporary virtual key generation | `POST /key/generate` with master key injected by `railway run` | Done | Returned `200`; generated key with alias `phase0-proof-*`, `max_budget=0.05`, `rpm_limit=10`, and model `dev-fast`. |
| Chat completion | `POST /v1/chat/completions` through LiteLLM auth | Blocked | Request reached OpenAI through LiteLLM, but OpenAI returned quota/billing `429` because the key has no credits. |
| Streaming | Streaming chat completion through LiteLLM auth | Blocked | Request reached OpenAI through LiteLLM, but OpenAI returned quota/billing `429` because the key has no credits. |
| Admin/control route denial | Developer virtual key cannot access admin/control routes | Done | Temporary developer key returned `403` on `/key/list`. |
| Prompt sentinel log leak check | Railway logs filter for `phase0_no_log_sentinel_20260606` | Done | No sentinel string found in the latest 500 service logs. |
| Runtime secret/config presence | `railway run` readback of booleans only | Done | `LITELLM_MASTER_KEY`, `OPENAI_API_KEY`, `UI_PASSWORD`, and `DATABASE_URL` are present. `NO_DOCS=True`, `NO_REDOC=True`, `ENVIRONMENT=phase0`, `PORT=4000`. |
| Model alias exposure | `GET /v1/models` with master key injected by `railway run` | Done | Returned `200`, exposes only `dev-fast`, and response did not contain provider keys, database URLs, or secret markers. |

## Current outcome

The Railway integration, deployment path, database connection, LiteLLM public endpoint, native-auth rejection behavior, docs disabling, virtual-key generation, developer-key admin denial, model alias exposure, runtime secret presence, and sanitized logging checks are validated.

The only proof behavior not yet validated is a successful provider-backed chat/streaming completion. Both requests reach OpenAI through LiteLLM and fail with quota/billing `429`, so this is a provider-credit blocker rather than a Railway, LiteLLM, or authentication blocker.

## Final validation command after credits are available

Run this from the repository after adding credits or switching to another funded proof provider:

```powershell
$railway = Join-Path $env:APPDATA 'npm\railway.cmd'
& $railway run --service litellm-proxy --environment production -- pwsh -NoProfile -File .\scripts\phase0-validate-litellm.ps1
```

If chat and streaming return success, update `docs\operations\implementation-status.md` P0-15, P0-16, and the Phase 0 exit criteria to `Done`.

## Teardown checklist

| Teardown item | Status |
| --- | --- |
| Remove disposable Railway services | Scheduled after funded validation or by 2026-06-13 if deferred |
| Remove disposable Railway database | Scheduled after funded validation or by 2026-06-13 if deferred |
| Remove obsolete empty `cloudflared-tunnel` service | Done |
| Revoke/delete disposable provider proof key | Scheduled after funded validation or provider replacement |
| Confirm no Phase 0 resource is marked staging or production | Done; resources are documented as Phase 0 disposable only, even though Railway's default environment is named `production` |
