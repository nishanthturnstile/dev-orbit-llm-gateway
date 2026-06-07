# Internal LLM Gateway architecture and tech stack

**Status:** Ready for Phase 0 validation; production implementation starts after the open gates are closed  
**Date:** 2026-06-05  
**Product:** Internal LLM Gateway  
**Production target:** Railway  
**Product reference:** `docs\internal-llm-gateway-product-plan.md`
**Implementation roadmap:** `docs\internal-llm-gateway-implementation-roadmap.md`

## 1. Purpose

This document is the technical source of truth for the Internal LLM Gateway architecture, service topology, technology choices, configuration boundaries, and implementation rules.

The system is a Railway-hosted, LiteLLM-first internal gateway. LiteLLM native authentication provides the Phase 0/MVP public API access layer through a Railway public/custom domain. LiteLLM Proxy provides OpenAI-compatible routing, model aliases, virtual keys, budgets, rate limits, spend tracking, and the v1 Admin UI. Railway managed Postgres stores LiteLLM state. Cloudflare Tunnel, Cloudflare Access, WAF, and edge-origin services are not part of the current implementation path.

## 2. Target architecture

### 2.1 Railway project and environments

Create one Railway project, for example `internal-llm-gateway`, with:

- `staging`: production-like validation environment with lower budgets and non-production provider keys where possible.
- `production`: regular internal production environment.

Use separate Railway variables per environment. Staging must not inherit:

- Production provider keys.
- Production LiteLLM master key.
- Production backup bucket credentials.
- Production virtual keys.

### 2.2 Railway services

| Service | Type | Public? | Purpose |
| --- | --- | ---: | --- |
| `litellm-proxy` | App service from pinned LiteLLM image/Dockerfile | Yes, public Railway/custom domain | LiteLLM Proxy core, OpenAI-compatible API, native auth, budgets, rate limits, and built-in Admin UI. |
| `litellm-postgres` | Railway managed Postgres | No public app ingress | LiteLLM users, virtual keys, budgets, spend, teams, and metadata. |
| `backup-worker` | Scheduled app service | No Railway public domain | Runs logical `pg_dump` backups for LiteLLM Postgres and ships encrypted/versioned copies off Railway. |
| `litellm-redis` | Deferred Railway managed Redis | No public app ingress | Add only when multiple LiteLLM replicas, distributed rate limiting, or shared cache state are required. |
| `monitor` | Optional later service or external SaaS | Depends | Uptime Kuma, Grafana/Prometheus, Langfuse, or equivalent if Railway logs/metrics plus LiteLLM metrics are not enough. |

Deferred from v1:

- `admin-api`
- `admin-web`
- `admin-postgres`
- Cloudflare Tunnel/Access/WAF or `llm-edge` / Envoy origin guard unless a later design decision explicitly reintroduces them

### 2.3 Public LLM API flow

For `llm.thaarei.com`:

1. Client tool sends request to the public Railway/custom LiteLLM endpoint.
2. `litellm-proxy` validates the LiteLLM virtual key in `Authorization: Bearer ...`.
3. LiteLLM checks model access, budget, per-key rate limits, routing, fallbacks, cache policy, and provider credentials.
4. LiteLLM emits metadata-only operational logs and spend metrics.

Developer traffic should be limited by LiteLLM auth, budgets, and rate limits to required OpenAI-compatible routes, for example:

- `/v1/chat/completions`
- `/v1/completions` if needed by a supported client
- `/v1/embeddings`
- `/v1/models`
- `/chat/completions` only if a client cannot use `/v1/chat/completions`
- `/embeddings` only if a client cannot use `/v1/embeddings`

Developer virtual keys must not be able to use LiteLLM admin/control routes such as `/ui`, `/key/*`, `/user/*`, `/team/*`, `/config/*`, or `/admin*`. Because the origin is public, the Admin UI/login surface and docs/Swagger exposure must be explicitly locked down before production.

### 2.4 Admin flow

For `admin.thaarei.com`, the Railway public domain, or an equivalent admin hostname/path:

1. Admin or lead opens LiteLLM's built-in Admin UI.
2. LiteLLM native login/RBAC, strong admin credentials, or LiteLLM-supported SSO gates admin access.
3. LiteLLM UI/RBAC handles users, teams, virtual keys, budgets, spend, model aliases, and admin operations.
4. Company-specific onboarding, alias guidance, and policy text live in repo docs/wiki unless a later custom portal is approved.

If the public Admin UI exposure is not acceptable, stop before production and approve a separate identity-aware hardening design.

### 2.5 Private traffic

- `litellm-proxy` -> `litellm-postgres` using private/internal Railway variables.
- `litellm-proxy` -> `litellm-redis` only if Redis is added later.
- `backup-worker` -> `litellm-postgres` using private/internal Railway variables.

Browser code must never receive:

- Provider keys.
- LiteLLM master key.
- Database URLs.
- Redis URLs.
- Private Railway hostnames.
- Private internal hostnames or other privileged internals.
- Stack traces, SQL, or operational secrets.

## 3. Technology stack

| Area | Tool | Reason |
| --- | --- | --- |
| Hosting platform | Railway | Managed app services, managed Postgres, variables, private networking, logs, metrics, and deploy workflows. |
| Gateway core | LiteLLM Proxy OSS | Mature OpenAI-compatible gateway with virtual keys, budgets, aliases, routing, spend. |
| Admin surface | LiteLLM built-in Admin UI | Covers keys, users, teams, budgets, spend, aliases, and model management without a custom product. |
| Gateway state database | Railway managed Postgres | Stores LiteLLM users, teams, virtual keys, budgets, spend, and metadata. |
| Optional shared state/cache | Railway managed Redis | Deferred until multiple replicas, distributed rate limiting, or shared cache state are required. |
| Public ingress/auth | Railway public/custom domain + LiteLLM native auth | Simplest MVP path; LiteLLM virtual keys, budgets, rate limits, and RBAC protect the public API. |
| Deferred edge/origin hardening | Separate design required | Not part of the current implementation; add only if public-origin risk or production requirements justify a new design. |
| Key request workflow | GitHub Issues/Actions or Slack Workflow | Lightweight enough for 10-15 developers; avoids a custom portal/database. |
| Onboarding/docs | Repo docs, wiki, MkDocs, or Docusaurus | Static policy and alias docs are enough for v1. |
| Smoke/API tests | pytest + httpx | Stable Python test stack for OpenAI-compatible API checks. |
| Secret scanning | Gitleaks | OSS secret detection in CI and local checks. |
| Image/security scanning | Trivy + cosign | Useful hardening; keep image pinning mandatory, make heavier gating dependent on compliance needs. |
| Monitoring/alerts | LiteLLM Prometheus metrics + Grafana/Alertmanager, Uptime Kuma, Better Stack, or equivalent | Budget, auth-failure, public-origin abuse, backup, and provider alerts are required before production. |
| Observability optional | Langfuse, OpenTelemetry Collector, Grafana/Tempo/Loki/SigNoz | Add if LiteLLM metrics and metadata-only logs are not enough. |
| Backups | `pg_dump` + rclone/awscli | Stable logical backups to R2/S3/B2. |

Managed/non-OSS dependencies intentionally used:

- Railway hosting, managed Postgres, logs, metrics, variables.
- External LLM providers.

These are production dependencies, not custom gateway logic.

## 4. Repository structure

```text
.
|-- README.md
|-- .gitignore
|-- .env.example
|-- services
|   |-- litellm
|   |   |-- Dockerfile
|   |   |-- config.yaml
|   |   |-- scripts
|   |   |   `-- verify-config.sh
|   |   `-- README.md
|   `-- backup-worker
|       |-- Dockerfile
|       |-- scripts
|       |   |-- backup-postgres.sh
|       |   `-- restore-check.sh
|       `-- README.md
|-- config
|   |-- litellm
|   |   |-- model-aliases.yaml
|   |   |-- provider-denylist.yaml
|   |   `-- policy.md
|   `-- railway
|       |-- README.md
|       |-- staging.md
|       `-- production.md
|-- scripts
|   |-- check-secrets.ps1
|   |-- lint-litellm-config.ps1
|   |-- smoke-railway.ps1
|   |-- create-virtual-key.ps1
|   `-- README.md
|-- tests
|   |-- smoke
|   |   |-- test_chat_completion.py
|   |   |-- test_streaming.py
|   |   |-- test_budget_block.py
|   |   `-- test_no_prompt_log_leak.py
|   `-- fixtures
|-- docs
|   |-- decisions
|   |-- runbooks
|   |-- security
|   |-- onboarding
|   `-- operations
`-- .github
    |-- workflows
    |   |-- ci.yml
    |   |-- staging-smoke.yml
    |   `-- image-policy.yml
    `-- dependabot.yml
```

Deferred directories, only if a later custom portal or edge fallback is approved:

- `apps\admin-web`
- `services\admin-api`
- `services\admin-postgres` is not a repo directory, but the database service should also stay deferred
- `services\llm-edge`
- Cloudflare tunnel/access/edge service scaffolds

## 5. Service variable plan

### 5.1 `litellm-proxy`

Required variables:

- `DATABASE_URL`: Railway private/internal URL from `litellm-postgres`.
- `REDIS_URL` or `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`: optional; add only when Redis is introduced.
- `LITELLM_MASTER_KEY`: sealed; must start with `sk-`.
- `OPENAI_API_KEY`: sealed.
- `ANTHROPIC_API_KEY`: sealed.
- `FIREWORKS_API_KEY`: sealed.
- `PERPLEXITY_API_KEY`: sealed.
- `PROXY_BASE_URL`: public LLM API URL, for metadata only.
- `ENVIRONMENT`: `staging` or `production`.
- Admin UI credentials or LiteLLM SSO settings, sealed where applicable.
- Rate-limit and budget policy variables/config.

The service may expose a public Railway/custom domain only after LiteLLM native authentication, admin controls, budgets, rate limits, metadata-only logging, and secret handling are configured.

### 5.2 Deferred edge fallback

Only needed if LiteLLM-native public-origin auth is not sufficient and a separate edge-origin design is approved.

Required variables if implemented:

- `LITELLM_PRIVATE_BASE_URL`
- `ALLOWED_API_PATHS`
- `BLOCKED_ADMIN_PATHS`
- `REQUEST_TIMEOUT_SECONDS`
- `STREAM_IDLE_TIMEOUT_SECONDS`

### 5.3 Deferred `admin-api` and `admin-web`

No custom admin API or web service is part of v1. If a future phase approves them, they require a separate design review before any variables are created.

Future `admin-api` variables would include:

- `ADMIN_DATABASE_URL`: Railway private/internal URL from future `admin-postgres`.
- `LITELLM_PRIVATE_BASE_URL`
- `LITELLM_ADMIN_KEY`: sealed and server-side only.
- `ADMIN_ALLOWED_EMAIL_DOMAINS`
- `ADMIN_ROLE_MAPPING`
- `SESSION_SIGNING_SECRET` if sessions are used.
- `ENVIRONMENT`

Future browser variables must never expose:

- LiteLLM private URL.
- LiteLLM master/admin key.
- Database URLs.
- Redis URLs.
- Provider keys.
- Edge service-token secrets.

### 5.4 `backup-worker`

Required variables:

- `LITELLM_DATABASE_URL`: private/internal.
- `BACKUP_ENCRYPTION_KEY`: sealed.
- `BACKUP_RCLONE_DESTINATION`
- `BACKUP_TIER`: `daily`, `weekly`, or `monthly`.
- `BACKUP_RETENTION_DAYS`
- `RCLONE_CONFIG_BACKUP_TYPE`
- `RCLONE_CONFIG_BACKUP_PROVIDER`
- `RCLONE_CONFIG_BACKUP_ENDPOINT`
- `RCLONE_CONFIG_BACKUP_REGION`
- `RCLONE_CONFIG_BACKUP_ACCESS_KEY_ID`
- `RCLONE_CONFIG_BACKUP_SECRET_ACCESS_KEY`: sealed.
- `RCLONE_CONFIG_BACKUP_ACL`
- `RESTORE_DATABASE_URL`: only for fresh restore-drill databases.

Backup credentials must be scoped only to the backup bucket/prefix.

## 6. Platform implementation rules

### 6.1 Railway-specific rules

- Use `railway add --database postgres --json`.
- Add Redis only when multiple LiteLLM replicas, distributed rate limiting, or shared cache state are required.
- Never retry ambiguous database creation without listing services first.
- Use explicit `--project`, `--environment`, and `--service` flags in automation.
- Use Railway service variable references for database wiring.
- Inspect generated Postgres variables after provisioning and select private/internal connection values.
- Do not use public TCP proxy URLs for app-to-database traffic.
- Railway healthchecks are deployment cutover checks only.
- Use `/health/readiness`, not `/health`, for LiteLLM deployment health.
- Configure continuous monitoring separately; Railway healthchecks are not continuous uptime monitoring.
- Use bounded Railway logs in scripts with `--lines` or `--since`.
- Emit single-line structured JSON logs from custom services such as `backup-worker`.
- Railway metrics are infrastructure-level only; use LiteLLM metadata and optional OpenTelemetry for app-level metrics.
- Railway service replicas do not have sticky sessions.
- Redis shared state is mandatory before multiple LiteLLM replicas.
- Services with volumes may have downtime during redeploys.

### 6.2 LiteLLM-specific rules

- `LITELLM_MASTER_KEY` must start with `sk-`.
- `DATABASE_URL` must be set for persistent virtual keys and spend.
- Use `os.environ/VAR_NAME` references in `config.yaml`.
- Do not run `--detailed_debug` in production.
- Use `/health/liveliness` for simple alive checks.
- Use `/health/readiness` for readiness.
- Use `/health` only for deliberate provider-health probing because it can make provider calls.
- Hide health details from broad/public responses.
- Set explicit retries, timeouts, and fallbacks.
- Keep raw logging disabled by default.
- Keep response cache default-off for code prompts.
- If Redis is added, use a short auth-cache TTL to balance performance with revocation responsiveness.
- Test streaming explicitly because IDE tools often depend on it.

### 6.3 Public-origin rules

- LiteLLM-native auth is the approved Phase 0/MVP public-origin control.
- Do not expose the public LiteLLM service until virtual-key auth, admin controls, budgets, rate limits, and metadata-only logging are configured.
- Disable public docs/Swagger where supported.
- Confirm developer virtual keys cannot access LiteLLM Admin UI or admin/control routes.
- Alert on repeated 401/403 responses, spend spikes, provider errors, and gateway 5xx.
- If any edge-origin hardening is added later, document token renewal and revocation, validate streaming through that layer, and avoid body-inspection rules that break code/prose prompts on `/v1/chat/completions`.

## 7. Security controls

Mandatory controls:

- Public LiteLLM origin is allowed only with explicit risk acceptance and documented compensating controls.
- LiteLLM virtual-key authentication on all developer API traffic.
- Strong admin credentials or LiteLLM-supported SSO for the Admin UI.
- Developer virtual keys cannot access LiteLLM admin/control routes.
- Public docs/Swagger disabled where supported.
- LiteLLM virtual keys per developer.
- Per-key budget windows: daily and monthly.
- Per-key rate limits and max request/concurrency limits.
- Company-level budget ceiling.
- Budget/spend spike alerts before production.
- Alerts for 401/403 spikes and public-origin abuse signals.
- Model alias restrictions.
- Same-tier failover only.
- Provider keys server-side only.
- No custom admin portal/database in v1.
- Metadata-only logging by default.
- Secret scanning in CI.
- Config policy linting in CI.
- Off-platform logical backups.
- Restore drill before production launch.

## 8. CI and policy checks

CI must fail on:

- Committed `.env` files.
- Known provider key patterns.
- Plaintext provider keys in LiteLLM config.
- LiteLLM config secrets not using env references.
- `sensitive-code` or `sensitive-*` aliases before approval.
- CN-hosted/first-party restricted provider endpoints.
- `--detailed_debug` in production config.
- Repo artifacts containing provider keys, LiteLLM keys, database URLs, Redis URLs, private Railway domains, or backup credentials.
- LiteLLM image not pinned by digest.
- LiteLLM image signature verification failure if signature verification is enabled by policy.
- Smoke test failures.

## 9. Runbooks required before production

Create runbooks under `docs\runbooks` for:

- Railway project/service setup.
- Staging deployment.
- Production deployment.
- Rollback.
- LiteLLM virtual-key creation.
- LiteLLM virtual-key revocation.
- Provider key rotation.
- Budget increase approval.
- Budget/spend alert response.
- LiteLLM Postgres outage.
- Provider outage and same-tier fallback validation.
- Railway backup restore.
- Off-platform logical backup restore.
- Prompt/log leakage investigation.
- Supported developer tool setup.

## 10. Implementation roadmap

The phase-wise implementation plan lives in `docs\internal-llm-gateway-implementation-roadmap.md`.
