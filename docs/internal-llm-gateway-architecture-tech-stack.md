# Internal LLM Gateway architecture and tech stack

**Status:** Ready for Phase 0 validation; production implementation starts after the open gates are closed  
**Date:** 2026-06-05  
**Product:** Internal LLM Gateway  
**Production target:** Railway  
**Product reference:** `docs\internal-llm-gateway-product-plan.md`

## 1. Purpose

This document is the technical source of truth for the Internal LLM Gateway architecture, service topology, technology choices, configuration boundaries, and implementation rules.

The system is a Railway-hosted, LiteLLM-first internal gateway. Cloudflare Tunnel and Cloudflare Access provide public ingress and access control. LiteLLM Proxy provides OpenAI-compatible routing, model aliases, virtual keys, budgets, spend tracking, and the v1 Admin UI. Railway managed Postgres stores LiteLLM state.

## 2. Target architecture

### 2.1 Railway project and environments

Create one Railway project, for example `internal-llm-gateway`, with:

- `staging`: production-like validation environment with lower budgets and non-production provider keys where possible.
- `production`: regular internal production environment.

Use separate Railway variables per environment. Staging must not inherit:

- Production provider keys.
- Production LiteLLM master key.
- Production Cloudflare Access AUD values.
- Production backup bucket credentials.
- Production virtual keys.

### 2.2 Railway services

| Service | Type | Public? | Purpose |
| --- | --- | ---: | --- |
| `cloudflared-tunnel` | App service from pinned `cloudflared` image/Dockerfile | No Railway public domain | Outbound-only connector from Railway private network to Cloudflare. Publishes approved hostnames through Cloudflare Tunnel. |
| `litellm-proxy` | App service from pinned LiteLLM image/Dockerfile | No Railway public domain | LiteLLM Proxy core and built-in Admin UI. Private-only origin, reached through the tunnel. |
| `litellm-postgres` | Railway managed Postgres | No public app ingress | LiteLLM users, virtual keys, budgets, spend, teams, and metadata. |
| `backup-worker` | Scheduled app service | No Railway public domain | Runs logical `pg_dump` backups for LiteLLM Postgres and ships encrypted/versioned copies off Railway. |
| `litellm-redis` | Deferred Railway managed Redis | No public app ingress | Add only when multiple LiteLLM replicas, distributed rate limiting, or shared cache state are required. |
| `monitor` | Optional later service or external SaaS | Depends | Uptime Kuma, Grafana/Prometheus, Langfuse, or equivalent if Railway logs/metrics plus LiteLLM metrics are not enough. |

Deferred from v1:

- `admin-api`
- `admin-web`
- `admin-postgres`
- `llm-edge` / Envoy origin guard, unless Cloudflare Tunnel cannot satisfy the production proof gates

### 2.3 Public LLM API flow

For `llm.thaarei.com`:

1. Client tool sends request through Cloudflare.
2. Cloudflare Access validates a service token, a tested local wrapper flow, or another approved Access policy.
3. Cloudflare Tunnel forwards the request over the outbound `cloudflared-tunnel` connection.
4. The request reaches private `litellm-proxy`; no public Railway domain exists for LiteLLM.
5. `litellm-proxy` validates the LiteLLM virtual key in `Authorization: Bearer ...`.
6. LiteLLM checks model access, budget, rate limits, routing, fallbacks, cache policy, and provider credentials.

Developer traffic should be limited by Cloudflare Access/WAF rules and LiteLLM auth to required OpenAI-compatible routes, for example:

- `/v1/chat/completions`
- `/v1/completions` if needed by a supported client
- `/v1/embeddings`
- `/v1/models`
- `/chat/completions` only if a client cannot use `/v1/chat/completions`
- `/embeddings` only if a client cannot use `/v1/embeddings`

Developer traffic must not be allowed to use LiteLLM admin/control routes such as `/ui`, `/key/*`, `/user/*`, `/team/*`, `/config/*`, or `/admin*`.

### 2.4 Admin flow

For `admin.thaarei.com` or an equivalent admin hostname/path:

1. Admin or lead opens LiteLLM's built-in Admin UI through Cloudflare Access human login.
2. Cloudflare Access allows only approved admin/lead identities or groups.
3. Cloudflare Tunnel forwards the request to private `litellm-proxy`.
4. LiteLLM UI/RBAC handles users, teams, virtual keys, budgets, spend, model aliases, and admin operations.
5. Company-specific onboarding, alias guidance, and policy text live in repo docs/wiki unless a later custom portal is approved.

### 2.5 Private traffic

- `cloudflared-tunnel` -> `litellm-proxy` over Railway private networking.
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
| Public ingress/origin guard | Cloudflare Tunnel (`cloudflared`) + Cloudflare Access | Publishes the service without a public Railway origin and supports separate API/admin access policies. |
| Deferred edge fallback | Envoy Proxy | Use only if Cloudflare Tunnel cannot meet proof gates; production-grade JWT/path/streaming proxy but more operational work. |
| Key request workflow | GitHub Issues/Actions or Slack Workflow | Lightweight enough for 10-15 developers; avoids a custom portal/database. |
| Onboarding/docs | Repo docs, wiki, MkDocs, or Docusaurus | Static policy and alias docs are enough for v1. |
| Smoke/API tests | pytest + httpx | Stable Python test stack for OpenAI-compatible API checks. |
| Secret scanning | Gitleaks | OSS secret detection in CI and local checks. |
| Image/security scanning | Trivy + cosign | Useful hardening; keep image pinning mandatory, make heavier gating dependent on compliance needs. |
| Monitoring/alerts | LiteLLM Prometheus metrics + Grafana/Alertmanager, Uptime Kuma, Better Stack, or equivalent | Budget, error, backup, tunnel, and provider alerts are required before production. |
| Observability optional | Langfuse, OpenTelemetry Collector, Grafana/Tempo/Loki/SigNoz | Add if LiteLLM metrics and metadata-only logs are not enough. |
| Backups | `pg_dump` + rclone/awscli | Stable logical backups to R2/S3/B2. |

Managed/non-OSS dependencies intentionally used:

- Railway hosting, managed Postgres, logs, metrics, variables.
- Cloudflare DNS, Access, WAF, and service tokens.
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
|   |-- cloudflared-tunnel
|   |   |-- Dockerfile
|   |   |-- config.example.yml
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
|   |-- cloudflare
|   |   `-- README.md
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
|   |   |-- test_cloudflare_block.py
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

Do not expose a public Railway domain for this service.

### 5.2 `cloudflared-tunnel`

Required variables:

- `CLOUDFLARE_TUNNEL_TOKEN`: sealed.
- `LITELLM_PRIVATE_BASE_URL`
- `TUNNEL_LOG_LEVEL`
- `ENVIRONMENT`

This service must not expose a public Railway domain. Cloudflare owns public DNS and Access policies.

### 5.3 Deferred `llm-edge` fallback

Only needed if Cloudflare Tunnel cannot satisfy the proof gates.

Required variables if implemented:

- `CLOUDFLARE_ACCESS_ISSUER`
- `CLOUDFLARE_ACCESS_AUD`
- `CLOUDFLARE_ACCESS_JWKS_URL`
- `LITELLM_PRIVATE_BASE_URL`
- `ALLOWED_API_PATHS`
- `BLOCKED_ADMIN_PATHS`
- `REQUEST_TIMEOUT_SECONDS`
- `STREAM_IDLE_TIMEOUT_SECONDS`

### 5.4 Deferred `admin-api` and `admin-web`

No custom admin API or web service is part of v1. If a future phase approves them, they require a separate design review before any variables are created.

Future `admin-api` variables would include:

- `ADMIN_DATABASE_URL`: Railway private/internal URL from future `admin-postgres`.
- `LITELLM_PRIVATE_BASE_URL`
- `LITELLM_ADMIN_KEY`: sealed and server-side only.
- `CLOUDFLARE_ACCESS_ISSUER`
- `CLOUDFLARE_ACCESS_AUD`
- `CLOUDFLARE_ACCESS_JWKS_URL`
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
- Cloudflare service-token secrets.

### 5.5 `backup-worker`

Required variables:

- `LITELLM_DATABASE_URL`: private/internal.
- `BACKUP_BUCKET_ENDPOINT`
- `BACKUP_BUCKET_NAME`
- `BACKUP_ACCESS_KEY_ID`
- `BACKUP_SECRET_ACCESS_KEY`: sealed.
- `BACKUP_ENCRYPTION_KEY`: sealed.
- `BACKUP_RETENTION_DAYS`

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

### 6.3 Cloudflare-specific rules

- Use Cloudflare Tunnel as the preferred public ingress path.
- Use Access human policies for LiteLLM Admin UI.
- Use Access service tokens or a tested wrapper for developer tool/API traffic.
- If a fallback `llm-edge` is introduced, validate Access JWT at origin.
- Remove or block direct Railway origin domains.
- Configure host/path policy so developer API service-token users cannot access LiteLLM Admin UI or admin/control routes.
- Test streaming through Cloudflare.
- Document service-token renewal and revocation.
- Avoid WAF body-inspection rules that break code/prose prompts on `/v1/chat/completions`.

## 7. Security controls

Mandatory controls:

- No direct public LiteLLM origin.
- Cloudflare Tunnel as default ingress.
- Cloudflare Access on all public hostnames.
- Separate Access policies for developer API traffic and LiteLLM Admin UI.
- Developer API users cannot access LiteLLM admin/control routes.
- LiteLLM virtual keys per developer.
- Per-key budget windows: daily and monthly.
- Company-level budget ceiling.
- Budget/spend spike alerts before production.
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
- Cloudflare Tunnel and Access setup.
- Cloudflare service-token rotation.
- LiteLLM virtual-key creation.
- LiteLLM virtual-key revocation.
- Provider key rotation.
- Budget increase approval.
- Budget/spend alert response.
- LiteLLM Postgres outage.
- Cloudflare Tunnel outage.
- Provider outage and same-tier fallback validation.
- Railway backup restore.
- Off-platform logical backup restore.
- Prompt/log leakage investigation.
- Supported developer tool setup.

## 10. Implementation sequence

This section remains here until a dedicated implementation roadmap document is created.

### Phase 0 - Launch-blocker validation

Goal: close the decisions that can invalidate the Railway production design before building the full repo.

Tasks:

- Confirm Railway workspace, billing plan, target region, and expected monthly platform cost.
- Confirm Cloudflare zone ownership, Zero Trust availability, and Cloudflare Tunnel availability.
- Confirm domain names:
    - `llm.thaarei.com` for developer API traffic.
    - `admin.thaarei.com` or an equivalent admin hostname/path for LiteLLM Admin UI.
- Confirm provider accounts: OpenAI, Anthropic, Fireworks AI, Perplexity, or the final approved provider list.
- Confirm whether any provider requires static egress IP allowlisting. If yes, pause and redesign egress before proceeding.
- Confirm initial company monthly budget, per-developer budget, and budget alert thresholds.
- Confirm IdP/group source for admin/lead/developer access.
- Confirm secure virtual-key distribution and revocation process.
- Confirm log retention and metadata-only logging policy.
- Confirm initial SLA target: best-effort internal, business-hours critical, or higher.
- Confirm max request body, timeout, and streaming limits.
- Stand up a temporary staging proof using LiteLLM, Postgres, Cloudflare Tunnel, and one low-cost provider/model.
- Prove one primary developer tool can call `/v1/chat/completions` with Cloudflare Access plus LiteLLM virtual key, including streaming.

Exit criteria:

- Cloudflare Tunnel works from Railway to private LiteLLM without a public Railway LiteLLM domain.
- `/v1` access strategy is proven with at least one real developer tool.
- Any tool requiring a local header-injecting wrapper is documented.
- Any virtual-key-only public fallback is rejected or documented as a temporary risk exception with owner, budget limits, monitoring, and expiry.
- The team agrees the MVP uses LiteLLM Admin UI, not a custom admin portal.

### Phase 1 - Scratch repository scaffold

Goal: create a clean MVP repo with service boundaries, docs, CI, and secret hygiene.

Tasks:

- Create the repository structure in section 4.
- Add `.gitignore`, `.env.example`, root README, and contribution workflow.
- Add service README files explaining boundaries.
- Add docs homes for decisions, runbooks, onboarding, security, and operations.
- Add LiteLLM config linting scripts.
- Add Gitleaks or equivalent secret scanning.
- Add initial CI for static checks, config linting, and secret scanning.

Exit criteria:

- The repo documents Railway + Cloudflare Tunnel + LiteLLM architecture, service boundaries, and deferred components.
- CI fails on committed secrets or forbidden config patterns.

### Phase 2 - Railway staging services

Goal: create a production-like staging environment before production resources are created.

Tasks:

- Create Railway project.
- Create `staging` environment.
- Add managed Postgres for LiteLLM.
- Add app services: `litellm-proxy`, `cloudflared-tunnel`, `backup-worker`.
- Confirm Postgres variables generated by Railway.
- Prefer private/internal connection variables.
- Never use public TCP proxy URLs from app services.
- Remove/avoid public domains from `litellm-proxy`, Postgres, and backup worker.
- Configure service root directories and watch paths.

Exit criteria:

- Staging services exist.
- Private networking works between `cloudflared-tunnel`, `litellm-proxy`, Postgres, and backup worker.
- Staging variables do not include production secrets.

### Phase 3 - LiteLLM service and policy-as-code

Goal: deploy a private-only LiteLLM Proxy service with stable model aliases and safe defaults.

Tasks:

- Create `services\litellm\Dockerfile` from a pinned LiteLLM database-capable image digest.
- Copy `config.yaml` into the image.
- Set `PORT=4000` or start command compatible with Railway's injected `PORT`.
- Configure Railway healthcheck path `/health/readiness` with sufficient timeout.
- Do not use `--detailed_debug` in production.
- Set `DATABASE_URL` from `litellm-postgres`.
- Set provider keys as sealed Railway variables.
- Set `LITELLM_MASTER_KEY` as sealed Railway variable starting with `sk-`.
- Define aliases:
    - `dev-fast`
    - `dev-code`
    - `dev-reasoning`
    - `dev-long-context`
    - `batch-analysis`
    - `dev-search`
    - `dev-embed`
    - `dev-vision`
- Do not define `sensitive-code`.
- Use same-tier fallbacks only.
- Set explicit timeouts and retry limits to avoid runaway costs during outages.
- Set metadata-only logging:
    - message logging off
    - user key info redacted where supported
    - health details hidden
    - no raw prompt/response logging by default
- Keep response caching default-off for code prompts.
- Add CI lint for:
    - forbidden provider domains/CN-hosted endpoints
    - `sensitive-*` aliases
    - debug flags
    - plaintext keys
    - missing env references

Exit criteria:

- LiteLLM starts in staging.
- Readiness healthcheck passes.
- `/health` deep model probe is not used for Railway deployment healthcheck.
- Direct public access to `litellm-proxy` is impossible.
- LiteLLM Admin UI works for approved admins/leads through Cloudflare Access.

### Phase 4 - Cloudflare Tunnel and Access

Goal: make the public LLM API and admin UI reachable only through Cloudflare.

Tasks:

- Configure Cloudflare DNS for developer and admin hostnames.
- Configure Cloudflare Tunnel to route public hostnames to private `litellm-proxy`.
- Configure Cloudflare Access service-token policy for developer tool/API traffic.
- Configure Cloudflare Access human policy for LiteLLM Admin UI.
- Configure path/hostname rules so developer API traffic cannot use LiteLLM admin/control routes:
    - `/ui`
    - `/key/*`
    - `/user/*`
    - `/team/*`
    - `/config/*`
    - `/admin*`
    - Swagger/admin docs routes unless explicitly protected
- Preserve LiteLLM virtual-key `Authorization` header.
- Support streaming/SSE end-to-end.
- Configure tunnel degraded/down notifications.

Exit criteria:

- Anonymous request to `llm.thaarei.com` is blocked.
- Request with Cloudflare service token but no LiteLLM virtual key is blocked by LiteLLM.
- Request with valid Cloudflare service token and valid LiteLLM virtual key succeeds.
- Direct Railway-domain bypass fails because no public Railway LiteLLM domain exists.
- Streaming completion works through Cloudflare Tunnel and LiteLLM.
- Admin UI is available only to approved human users.

### Phase 5 - Backups, restore, and alerting baseline

Goal: make production state recoverable and spend failures visible before real usage.

Tasks:

- Enable Railway native volume backups on LiteLLM Postgres.
- Configure daily, weekly, and monthly backup schedules.
- Create `backup-worker` scheduled job for logical backups:
    - `pg_dump` LiteLLM Postgres
    - encrypt/compress
    - upload to R2/S3/B2 with versioning
    - log metadata only
- Create restore runbook:
    - restore Railway volume snapshot
    - restore logical backup into new Postgres service
    - repoint `DATABASE_URL`
    - verify LiteLLM virtual key auth
    - reconcile revoked keys after restore
- Add key rotation runbooks:
    - provider keys
    - Cloudflare service tokens
    - LiteLLM master/admin credential
    - developer virtual keys
- Add outage runbooks:
    - provider outage
    - Postgres outage
    - Railway deploy rollback
    - bad LiteLLM config rollback
    - Cloudflare Tunnel outage
- Add alerts:
    - company budget threshold
    - per-key spend spike
    - provider error rate
    - LiteLLM 5xx/error rate
    - tunnel degraded/down
    - backup failure

Exit criteria:

- Backup job succeeds in staging.
- Restore drill succeeds before production launch.
- RPO/RTO are documented.
- Budget/error/tunnel/backup alerts are configured.

### Phase 6 - CI/CD and security gates

Goal: make bad config and unsafe secrets fail before deployment.

Tasks:

- Add LiteLLM config CI:
    - YAML parse
    - required aliases
    - no `sensitive-*`
    - no provider denylist domains
    - no plaintext keys
    - no debug flags
    - env refs for secrets
- Add secret scan:
    - Gitleaks
    - custom provider-key patterns
- Add image checks:
    - LiteLLM image pinned by digest
    - Trivy/cosign if compliance or team policy requires them
- Add staging deployment workflow or documented Railway CLI deployment procedure.
- Add smoke test workflow against staging after deploy.

Exit criteria:

- Unsafe config cannot merge.
- Staging deploy can be reproduced from a clean checkout.
- Production deploy uses the same artifacts/config that passed staging.

### Phase 7 - Staging validation proof gates

Goal: prove Railway + Cloudflare + LiteLLM behavior before production.

Mandatory smoke tests:

- `GET /health/readiness` passes for private LiteLLM.
- Anonymous public request to `llm.thaarei.com` is blocked.
- Direct Railway-domain bypass fails.
- Valid Cloudflare service token plus valid LiteLLM virtual key can call `/v1/chat/completions`.
- Invalid LiteLLM key is blocked.
- Valid LiteLLM key without Cloudflare Access is blocked.
- `/v1/models` exposes aliases, not provider credentials.
- Disallowed model/provider names are blocked for developer keys.
- Per-key daily/monthly budget windows block over-budget requests.
- Same-tier fallback works for a controlled simulated provider failure.
- No fallback silently downgrades premium aliases to weaker tiers.
- Streaming SSE works through Cloudflare Tunnel and LiteLLM.
- Response cache remains off for code prompts unless explicitly requested and policy-allowed.
- Railway logs do not contain known prompt/response sentinel strings.
- LiteLLM Admin UI is not accessible to developer API service-token users.
- Backup worker creates off-platform logical backups.
- Restore drill works into a fresh staging database.
- Provider key rotation runbook works for one provider.
- Cloudflare service token rotation runbook works.

Exit criteria:

- All mandatory smoke tests pass.
- At least one primary developer tool works end-to-end with the required Cloudflare + LiteLLM auth path.
- Blocked tools are documented and excluded from launch.

### Phase 8 - Production deployment and pilot

Goal: promote the proven staging stack to production and operate a small pilot.

Tasks:

- Create `production` Railway environment only after staging proof gates pass.
- Create production Railway variables from approved secret store/operator input.
- Deploy pinned artifacts/images to production.
- Configure production Cloudflare Tunnel, Access policies, service tokens, and domains.
- Confirm no unused/default public Railway domains exist.
- Enable backups and backup worker.
- Run production smoke tests with low-cost model/provider calls.
- Create initial admin/lead users in LiteLLM.
- Create initial developer virtual keys.
- Apply per-developer budgets and allowed aliases.
- Document supported tool setup.
- Announce production usage rules:
    - no sensitive/client/private/production incident content
    - use aliases only
    - report failures with LiteLLM call ID
    - do not share virtual keys
- Onboard a small pilot cohort.
- Monitor spend, errors, latency, provider failures, cache behavior, and budget hits.
- Review Railway CPU/memory/network/disk metrics.
- Review LiteLLM spend/user/team metadata.
- Review Cloudflare Access logs for denied/bypassed attempts.
- Tune aliases and budgets based on real usage.
- Expand supported tools only after compatibility tests.

Exit criteria:

- Production endpoint works through Cloudflare only.
- LiteLLM Admin UI works through Cloudflare only.
- Initial users can make approved requests.
- Budgets and model restrictions are enforced.
- Backups are running.
- Restore path has been tested in staging and documented for production.
- Pilot users can use the gateway day-to-day for approved non-sensitive work.

## 11. First implementation order

Start implementation in this order:

1. Close Phase 0 decisions and proofs, especially Cloudflare Tunnel and `/v1` auth/tool compatibility.
2. Create the scratch repo structure and CI secret/config gates.
3. Provision Railway staging only.
4. Deploy private LiteLLM with placeholder/low-cost provider config.
5. Add Cloudflare Tunnel and prove direct Railway-origin bypass is impossible.
6. Prove one real client can call `/v1/chat/completions` with Cloudflare Access plus LiteLLM auth, including streaming.
7. Configure LiteLLM Admin UI behind Cloudflare Access for admins/leads.
8. Add backups, alerts, and restore drill.
9. Run full staging proof gates.
10. Only then create production variables and deploy production.
