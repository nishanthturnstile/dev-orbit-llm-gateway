# Phase 0 disposable proof notes

**Status:** Complete and torn down; named developer-tool validation deferred to Phase 8
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
| Low-cost provider/model selected and secret placed outside source control | Done for Phase 0 config; OpenAI `gpt-4o-mini` / `dev-fast` selected, credited key injected, chat and streaming validation succeeded |
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

`litellm-proxy` had a temporary public Railway proof endpoint protected by LiteLLM native authentication. That endpoint belonged only to the disposable Phase 0 project and is no longer needed after durable staging shell provisioning.

## Resource inventory

| Resource | ID / name | Environment | Status | Teardown status |
| --- | --- | --- | --- | --- |
| Railway project | `internal-llm-gateway-phase0` (`c642da87-d8e5-40ec-ba54-bcd02ec1c64b`) | Default | Deletion accepted by Railway; `deletedAt=2026-06-08T06:40:12.528Z` | Done |
| Railway `litellm-proxy` service | `litellm-proxy` (`f48fbf0d-706c-4acf-99cf-dc0e6d5febb9`) | Default / Railway `production` | Was deployed; latest validated deployment `2cba1ae5-6bb6-4043-8630-d389c1861ae4` was `SUCCESS` before project deletion | Done through project deletion |
| Railway `litellm-postgres` service | `Postgres` (`0a46a957-c35f-4d8c-8efe-ad31dba1c9fc`) | Default / Railway `production` | Was created; latest deployment was `SUCCESS`; readiness check reported DB connected before project deletion | Done through project deletion |
| Railway `cloudflared-tunnel` service | `cloudflared-tunnel` (`30086a34-1c86-4d53-b685-e43f18dd5174`) | `production` | Deleted after auth pivot | Done |
| Cloudflare Tunnel | Not needed for current design | N/A | Deferred hardening option | N/A |
| Provider proof key/model | OpenAI `gpt-4o-mini` exposed as `dev-fast` | Railway variable / LiteLLM config | Credited key validated through LiteLLM; chat and streaming return `200` | Revoke/replace after proof |

## Test command log

Only non-secret commands and sanitized outputs may be recorded here.

| Test | Command / method | Status | Evidence |
| --- | --- | --- | --- |
| Railway preflight | Read-only CLI checks | Done | Railway CLI is installed/authenticated and current linked project/service visibility works; see `docs\decisions\phase-0-launch-blockers.md`. |
| Initial disposable resource creation | Railway CLI `init` and `add` commands after operator approval | Done | Project, Postgres, `litellm-proxy`, and `cloudflared-tunnel` were created. |
| Postgres deployment health | `railway deployment list --service Postgres --limit 1 --json` | Done | Latest Postgres deployment status is `SUCCESS`. |
| LiteLLM proof artifacts | `services\litellm\Dockerfile`; former `config\litellm\config.yaml` | Done | Phase 0 used a digest-pinned `docker.litellm.ai/berriai/litellm-database:main-stable@sha256:bc57f7cdc09f29d8251846e4f4ae20503760c3c03fc5ae3a9e49eb87cc9fd0f0` image and a temporary config mapping `dev-fast` to `openai/gpt-4o-mini`. Phase 2 supersedes the local runtime config path with `services\litellm\config.yaml`; the deployed Phase 0 proof is not mutated by this local move. |
| Non-secret Railway service config | Railway CLI service config and variable set commands | Done | `litellm-proxy` uses Dockerfile builder, `services/litellm/Dockerfile`, `/health/readiness`, timeout `300`, `DATABASE_URL=${{Postgres.DATABASE_URL}}`, `PORT=4000`, `NO_DOCS=True`, `NO_REDOC=True`, `ENVIRONMENT=phase0`, and `UI_USERNAME=admin`. |
| Secret-setting helper | `scripts\phase0-set-railway-secrets.ps1` | Ready | Prompts locally for `LITELLM_MASTER_KEY`, `OPENAI_API_KEY`, and `UI_PASSWORD`, then sends them to Railway via stdin without printing values. |
| LiteLLM deployment | Railway deployment `2cba1ae5-6bb6-4043-8630-d389c1861ae4` | Done | Deployment status `SUCCESS` after redeploy with updated OpenAI key. |
| LiteLLM readiness | `GET /health/readiness` through public native-auth proof path | Done | Returned `200` with `{"status":"healthy","db":"connected"}`. |
| Missing key rejection | `POST /v1/chat/completions` without `Authorization` | Done | Returned `401` auth error. |
| Invalid key rejection | `POST /v1/chat/completions` with invalid key | Done | Returned `401` token-not-found error. |
| Docs disabled | `GET /docs` and `GET /redoc` | Done | Both returned `404`. |
| Temporary virtual key generation | `POST /key/generate` with master key injected by `railway run` | Done | Returned `200`; generated key with alias `phase0-proof-*`, `max_budget=0.05`, `rpm_limit=10`, and model `dev-fast`. |
| Chat completion | `POST /v1/chat/completions` through LiteLLM auth | Done | OpenAI-compatible validation script returned `200` through LiteLLM with a generated virtual key and `dev-fast`. |
| Streaming | Streaming chat completion through LiteLLM auth | Done | OpenAI-compatible validation script returned `200` and received stream chunks through LiteLLM with a generated virtual key and `dev-fast`. |
| Admin/control route denial | Developer virtual key cannot access admin/control routes | Done | Temporary developer key returned `403` on `/key/list`. |
| Prompt sentinel log leak check | Railway logs filter for `phase0_no_log_sentinel_20260606` | Done | No sentinel string found in the latest 500 service logs. |
| Runtime secret/config presence | `railway run` readback of booleans only | Done | `LITELLM_MASTER_KEY`, `OPENAI_API_KEY`, `UI_PASSWORD`, and `DATABASE_URL` are present. `NO_DOCS=True`, `NO_REDOC=True`, `ENVIRONMENT=phase0`, `PORT=4000`. |
| Model alias exposure | `GET /v1/models` with master key injected by `railway run` | Done | Returned `200`, exposes only `dev-fast`, and response did not contain provider keys, database URLs, or secret markers. |
| Disposable project deletion | `railway delete --project c642da87-d8e5-40ec-ba54-bcd02ec1c64b --yes --json` | Done | Railway accepted deletion for project `internal-llm-gateway-phase0`; project readback shows `deletedAt=2026-06-08T06:40:12.528Z`. |

## Current outcome

The Railway integration, deployment path, database connection, LiteLLM public endpoint, native-auth rejection behavior, docs disabling, virtual-key generation, developer-key admin denial, model alias exposure, runtime secret presence, credited OpenAI-backed chat completion, credited OpenAI-backed streaming, and sanitized logging checks are validated.

The operator accepted the successful OpenAI-compatible validation script as sufficient proof for Phase 2 planning. Named primary developer-tool compatibility remains deferred to Phase 8 staging proof gates.

## Funded validation command

Validated on 2026-06-06 after adding OpenAI credits:

```powershell
$railway = Join-Path $env:APPDATA 'npm\railway.cmd'
& $railway run --service litellm-proxy --environment production -- pwsh -NoProfile -File .\scripts\phase0-validate-litellm.ps1 -BaseUrl '<phase0-base-url>'
```

The command returned:

- `generate virtual key`: `200`
- `valid-key chat`: `200`
- `valid-key streaming`: `200`
- `developer key admin route`: `403`
- `sentinel`: `200`

Readiness also returned `200` with DB connected, and a bounded Railway log search for `phase0_no_log_sentinel_20260606` returned no matches.

## Teardown checklist

| Teardown item | Status |
| --- | --- |
| Remove disposable Railway services | Done through project deletion request; Railway readback shows project deletion scheduled |
| Remove disposable Railway database | Done through project deletion request; Railway readback shows project deletion scheduled |
| Remove obsolete empty `cloudflared-tunnel` service | Done |
| Revoke/delete disposable provider proof key | Done through project deletion request for the Railway-held proof environment; any provider-side key should remain revoked/rotated outside the repository if it was not single-use |
| Confirm no Phase 0 resource is marked staging or production | Done; resources are documented as Phase 0 disposable only, even though Railway's default environment is named `production` |
