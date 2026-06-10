# Public-origin validation

This document defines the Phase 6 evidence shape for exposing the LiteLLM staging API through a Railway public/custom domain. It is non-secret by design.

## Current Phase 6 posture

Phase 6 public ingress is live on the Railway-generated staging endpoint. The literal Railway host is kept out of tracked docs to satisfy repository secret/public-host scans; use the Railway service domain record or the session handoff for the current host.

```text
https://<railway-generated-staging-domain>
```

The Admin UI is available at:

```text
https://<railway-generated-staging-domain>/ui/
```

Phase 6 public validation passed after:

1. `dev-search` was validated with a rotated approved `PERPLEXITY_API_KEY`.
2. Operator confirmed exposed staging keys were rotated.
3. Active alerting was explicitly risk-accepted as deferred for this staging proof.
4. Operator approved the exact Railway-generated domain mutation.

The Phase 6 Admin UI posture is private staging access only: Admin UI is enabled with sealed strong credentials, no public URL exists yet, and public Admin UI exposure remains gated.

## Public validation inputs

Runtime validation requires operator-supplied values. Do not write these values to docs, issues, chat, logs, or screenshots.

| Input | Source | Secret? | Notes |
| --- | --- | --- | --- |
| Public gateway base URL | Railway-generated public domain | No | Public hostnames are operational data, not credentials. Custom domain is deferred. |
| Disposable developer virtual key | LiteLLM operator context | Yes | Use a scoped short-lived key and block/revoke it after validation. |
| Invalid key marker | Validator default or operator-provided dummy value | No | Must not match a real key. |
| Readiness policy | Operator decision | No | `Skip`, `Public`, or `Blocked`. |

## Validator

Use the Phase 6 public-origin validator only after the public-ingress gate is closed and the exact mutation is approved:

```powershell
pwsh -NoProfile -File scripts\phase6-validate-public-origin.ps1 `
  -GatewayBaseUrl "<public-base-url>" `
  -VirtualKey "<disposable-developer-key>" `
  -ReadinessPolicy Public `
  -AdminUiMode Enabled `
  -IncludeModels `
  -IncludeEmbeddings `
  -IncludeLongStreamingProbe
```

For CI shape validation without network calls:

```powershell
pwsh -NoProfile -File scripts\phase6-validate-public-origin.ps1 -ValidateOnly
```

The validator prints redacted JSON only. It must not print generated keys, provider keys, master keys, database URLs, private hostnames, raw prompts, raw responses, stack traces, or SQL.

## Required checks

| Check | Expected result |
| --- | --- |
| Missing bearer key on `/v1/chat/completions` | `401` or `403` |
| Invalid bearer key on `/v1/chat/completions` | `401` or `403` |
| Valid disposable developer key on `/v1/chat/completions` | `2xx` |
| Streaming/SSE through public endpoint | `2xx` with stream chunks |
| Optional long streaming probe | `2xx` with stream chunks |
| `/v1/models` if enabled | `2xx` and aliases only |
| `/v1/embeddings` if enabled | `2xx` |
| `sensitive-code` alias | rejected |
| direct provider model name | rejected |
| `/ui` | enabled only when Admin UI credentials are configured; public exposure remains gated |
| `/key/*`, `/user/*`, `/team/*`, `/config/*`, `/admin*`, `/spend/*` with developer key | rejected |
| `/docs`, `/redoc`, `/openapi.json` | blocked |
| Public error bodies | no secrets, private hostnames, stack traces, SQL, or raw prompt/response details |

## Evidence rules

Record only:

- pass/fail summaries
- status codes
- public endpoint class or hostname
- service/deployment IDs
- redacted command shapes
- alert categories and destinations
- deferred non-secret decisions

Never record:

- provider keys
- LiteLLM master key
- `LITELLM_SALT_KEY`
- generated virtual keys
- database URLs
- private Railway hostnames
- Tunnel or edge-service secrets
- raw prompts or responses
- stack traces
- SQL

## Disposable key cleanup

Every public validation run must use a short-lived scoped key. After validation:

1. Block or revoke the disposable key from an approved operator context.
2. Verify the key no longer works.
3. Record only the cleanup status, never the key value.

## Alerting gate

Before public exposure, configure at least one active alert path for:

- 401/403 spike or sustained anonymous/invalid-key noise
- spend spike
- budget exhaustion
- provider authentication/failure spike
- LiteLLM/gateway 5xx spike
- public endpoint availability failure

Railway deployment healthchecks are not continuous monitoring, so they do not satisfy this gate by themselves.

Railway Observability monitors can cover infrastructure thresholds such as CPU, RAM, disk usage, and network egress, and can notify through email/in-app notifications or project webhooks when available on the workspace plan. Railway metrics do not provide application-level request, provider, spend, or budget alerts by themselves. Phase 6 therefore needs either a LiteLLM-native alert/webhook path or an approved external monitor/log query path for 401/403 spikes, spend/budget events, provider failures, gateway 5xx, and endpoint availability.

## Phase 6 approved public settings

| Setting | Phase 6 value |
| --- | --- |
| Public endpoint | Railway-generated staging domain; custom domain deferred. |
| Public readiness | `/health/readiness` may be publicly reachable and return `200` in staging. |
| Admin UI | Enabled for private staging testing with sealed strong credentials; public exposure remains gated. |
| Tunnel/edge services | Removed from Phase 6 scope; do not configure Tunnel, Access, WAF, service tokens, or edge origin guards. |
| Staging disposable validation key | USD 5 max budget, 24h duration, 120 RPM, 300k TPM, 5 max parallel requests. |
| MVP per-developer default | USD 10/day, USD 100/month, 120 RPM, 300k TPM, 5 max parallel requests. |
| Secret rotation | Closed by operator confirmation for staging keys. |
| Alerting | Explicit Phase 6 staging-proof risk exception: operator deferred active alerting for now. Revisit before production or broader pilot. |

## Phase 6 public validation evidence

| Check | Result |
| --- | --- |
| Readiness | Public `/health/readiness` returned `200`. |
| Missing auth | Public `/v1/chat/completions` returned `401`. |
| Invalid auth | Public `/v1/chat/completions` returned `401`. |
| Valid key chat | Disposable key succeeded on `dev-fast`. |
| Valid key search | Disposable key succeeded on `dev-search`. |
| Valid key embeddings | Disposable key succeeded on `dev-embed`. |
| Streaming | Disposable key succeeded on public `dev-fast` streaming and produced SSE data. |
| Developer admin/control routes | Disposable developer key was denied on `/key/list`, `/user/info`, `/team/list`, `/config/list`, `/spend/logs`, and `/admin`. |
| Admin UI | `/ui/` returned `200` HTML and is protected by sealed Admin UI credentials. |
| Docs/ReDoc/OpenAPI | `/docs`, `/redoc`, and `/openapi.json` are blocked. |
| Disposable key cleanup | Public validation key was blocked after validation. |
