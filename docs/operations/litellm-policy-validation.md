# LiteLLM policy validation

This document records the non-secret Phase 5 validation plan and evidence shape for the durable staging `litellm-proxy` deployment.

## Phase 5 decisions

| Decision | Value |
| --- | --- |
| Provider scope | Fireworks-backed default aliases, utility aliases, and restricted premium aliases |
| `dev-search` | Alias remains present; runtime validation passed after operator rotated the staged `PERPLEXITY_API_KEY` |
| Admin UI | Enabled for private staging test with strong `UI_USERNAME` / `UI_PASSWORD`; no public URL exists |
| OpenAPI schema | Disabled with `NO_OPENAPI=True` |
| HTTP validation path | Private/internal Railway path |
| DB-backed model state | Keep `store_model_in_db: true` |
| Salt key | Set sealed `LITELLM_SALT_KEY` before first boot |
| Validation spend cap | USD 1 total |
| Durable public ingress | Not created in Phase 5 |

The pinned LiteLLM image still served the Admin UI shell with only the documented `DISABLE_ADMIN_UI=true` flag. Phase 5 therefore also enforces a container-level startup guard that returns 404 for `/ui`, `/ui/*`, and the LiteLLM UI asset prefix when that flag is enabled. Phase 6 private staging testing later set `DISABLE_ADMIN_UI=false` with sealed Admin UI credentials.

## Current status

Phase 5 private runtime validation passed for the previous OpenAI-backed alias set. The current local config has since been expanded to Fireworks-backed default aliases plus restricted OpenAI/Anthropic premium aliases. Those new routes require fresh staging validation before they are considered production-ready.

## Required runtime checks

1. `/health/readiness` reports ready and DB connected.
2. Missing and invalid bearer keys are rejected.
3. A short-lived disposable regular developer key succeeds on approved default aliases and is denied premium/ultra-premium aliases.
4. Streaming works on `dev-fast`.
5. Embeddings work on `dev-embed`.
6. Vision is validated if the OpenAI account supports it; otherwise record the provider/account limitation.
7. `dev-search` succeeds with a valid approved Perplexity key.
8. A short-lived premium validation key succeeds on `premium-code`, `premium-planning`, `ultra-premium-code`, and `ultra-premium-planning` under operator-approved spend controls.
9. `sensitive-code` and direct wildcard/provider model names fail.
10. Developer keys cannot access admin/control routes.
11. `/ui`, `/docs`, `/redoc`, and `/openapi.json` are unavailable or protected.
12. Spend metadata is visible through a non-secret admin endpoint or validation path that does not put generated keys in URLs.
13. Key/spend state persists after restart or redeploy.
14. Disposable validation keys are blocked and verified unusable after validation.
15. Health, error, and log output do not expose secrets, database URLs, private hostnames, raw prompts, raw responses, stack traces, or SQL.

## Phase 5 validation evidence

| Check | Result |
| --- | --- |
| Deployment | `095bc349-2e77-4552-9ab4-ff36d54bb506` is `SUCCESS` |
| Public URL | None |
| Readiness | `200`, DB connected |
| Missing/invalid auth | `401` rejection |
| Previous OpenAI-backed chat aliases | Passed for the old alias set before the Fireworks/premium expansion |
| Current Fireworks-backed default aliases | Needs fresh staging validation for `dev-fast`, `dev-code`, `dev-long-horizon`, and `dev-reasoning` |
| Current premium aliases | Needs fresh staging validation for `premium-code`, `premium-planning`, `ultra-premium-code`, and `ultra-premium-planning` |
| Streaming | Passed on `dev-fast` |
| Embeddings | Passed on `dev-embed` |
| `dev-search` | Passed with rotated staged `PERPLEXITY_API_KEY`; disposable validation key was blocked after test |
| Forbidden alias | `sensitive-code` denied |
| Developer admin route | Denied |
| Admin UI/docs/ReDoc/OpenAPI | Admin UI enabled privately with sealed credentials; docs/ReDoc/OpenAPI remain disabled/protected |
| Spend metadata | Readable from approved operator context |
| Disposable key blocking | Passed |
| Key metadata persistence | Passed after controlled restart |
| RPM enforcement | Passed with a dedicated disposable key: first request succeeded, second request returned `429` |
| Log hygiene | Fresh bounded scan after the log-redaction wrapper found zero secret-key, DB URL, private-host, or traceback matches |

## Current blockers before public Phase 6 ingress

| Blocker | Required closure |
| --- | --- |
| Exposed staging secrets during validation readback | Rotate exposed provider/LiteLLM/database/admin/generated-key staging credentials before public ingress. Do not risk-accept exposed control-plane secrets for a public origin and do not reuse exposed values for production. |

Creating a Railway public domain remains blocked until exposed control-plane secret rotation is confirmed and either active alerting is configured or an explicit public-ingress risk exception is recorded.

## Evidence rules

Record only pass/fail summaries, status codes, redacted command shapes, service IDs, deployment IDs, and non-secret deferred items. Do not record generated key values, provider keys, master keys, database URLs, raw prompts, raw responses, stack traces, or private hostnames.
