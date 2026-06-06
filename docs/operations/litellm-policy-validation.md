# LiteLLM policy validation

This document records the non-secret Phase 5 validation plan and evidence shape for the durable staging `litellm-proxy` deployment.

## Phase 5 decisions

| Decision | Value |
| --- | --- |
| Provider scope | OpenAI-backed aliases first |
| `dev-search` | Alias remains present; runtime validation blocked until a valid approved `PERPLEXITY_API_KEY` is sealed in Railway |
| Admin UI | Disabled with `DISABLE_ADMIN_UI=true` |
| OpenAPI schema | Disabled with `NO_OPENAPI=True` |
| HTTP validation path | Private/internal Railway path |
| DB-backed model state | Keep `store_model_in_db: true` |
| Salt key | Set sealed `LITELLM_SALT_KEY` before first boot |
| Validation spend cap | USD 1 total |
| Durable public ingress | Not created in Phase 5 |

The pinned LiteLLM image still served the Admin UI shell with only the documented `DISABLE_ADMIN_UI=true` flag. Phase 5 therefore also enforces a container-level startup guard that returns 404 for `/ui`, `/ui/*`, and the LiteLLM UI asset prefix when that flag is enabled.

## Current status

Phase 5 runtime validation is blocked only on `dev-search`. Railway `litellm-proxy` deployment `dceac0a0-a478-4bc4-991d-45b124f56358` is healthy with no public URL. Runtime validation reached LiteLLM and Postgres; readiness, auth rejection, OpenAI-backed aliases, streaming, embeddings, key metadata persistence, RPM enforcement, Admin UI/docs/ReDoc/OpenAPI closure, admin route denial, forbidden/direct-provider alias denial, spend metadata access, key blocking, and fresh log hygiene passed. `dev-search` reaches Perplexity but fails with provider `401` because the staged `PERPLEXITY_API_KEY` is invalid.

## Required runtime checks

1. `/health/readiness` reports ready and DB connected.
2. Missing and invalid bearer keys are rejected.
3. A short-lived disposable developer key succeeds on approved OpenAI-backed aliases.
4. Streaming works on `dev-fast`.
5. Embeddings work on `dev-embed`.
6. Vision is validated if the OpenAI account supports it; otherwise record the provider/account limitation.
7. `dev-search` succeeds with a valid approved Perplexity key; a provider `401` keeps Phase 5 blocked.
8. `sensitive-code` and direct wildcard/provider model names fail.
9. Developer keys cannot access admin/control routes.
10. `/ui`, `/docs`, `/redoc`, and `/openapi.json` are unavailable or protected.
11. Spend metadata is visible through a non-secret admin endpoint or validation path that does not put generated keys in URLs.
12. Key/spend state persists after restart or redeploy.
13. Disposable validation keys are blocked and verified unusable after validation.
14. Health, error, and log output do not expose secrets, database URLs, private hostnames, raw prompts, raw responses, stack traces, or SQL.

## Phase 5 validation evidence

| Check | Result |
| --- | --- |
| Deployment | `dceac0a0-a478-4bc4-991d-45b124f56358` is `SUCCESS` |
| Public URL | None |
| Readiness | `200`, DB connected |
| Missing/invalid auth | `401` rejection |
| OpenAI-backed chat aliases | Passed for `dev-fast`, `dev-code`, `dev-reasoning`, `dev-long-context`, `batch-analysis`, and `dev-vision` |
| Streaming | Passed on `dev-fast` |
| Embeddings | Passed on `dev-embed` |
| `dev-search` | Blocked; provider returns `401` for the staged `PERPLEXITY_API_KEY` |
| Forbidden alias | `sensitive-code` denied |
| Developer admin route | Denied |
| Admin UI/docs/ReDoc/OpenAPI | Disabled/protected |
| Spend metadata | Readable from approved operator context |
| Disposable key blocking | Passed |
| Key metadata persistence | Passed after controlled restart |
| RPM enforcement | Passed with a dedicated disposable key: first request succeeded, second request returned `429` |
| Log hygiene | Fresh bounded scan after the log-redaction wrapper found zero secret-key, DB URL, private-host, or traceback matches |

## Current blockers before Phase 6

| Blocker | Required closure |
| --- | --- |
| Invalid Perplexity credential | Rotate or replace `PERPLEXITY_API_KEY` through an operator-controlled terminal, restart `litellm-proxy`, and rerun private validation without `--allow-dev-search-deferred`. |
| Exposed staging secrets during validation readback | Rotate exposed provider/LiteLLM staging credentials before real use, or record an explicit staging-only risk acceptance. Do not reuse exposed values for production. |

## Evidence rules

Record only pass/fail summaries, status codes, redacted command shapes, service IDs, deployment IDs, and non-secret deferred items. Do not record generated key values, provider keys, master keys, database URLs, raw prompts, raw responses, stack traces, or private hostnames.
