# Internal LLM Gateway product plan

**Status:** Ready for Phase 0 validation; production implementation starts after the open gates are closed  
**Date:** 2026-06-05  
**Product:** Internal LLM Gateway  
**Production target:** Railway  
**Primary gateway/admin surface:** LiteLLM Proxy OSS with built-in Admin UI  
**Architecture reference:** `docs\internal-llm-gateway-architecture-tech-stack.md`

## 1. Purpose

The Internal LLM Gateway gives approved developers a controlled OpenAI-compatible endpoint for day-to-day AI-assisted development while keeping provider credentials, budgets, routing policy, and operational controls server-side.

The product is a small internal platform for 10-15 developers. It does not host models or GPUs. It brokers requests to approved external LLM providers through LiteLLM, enforces model aliases and budgets, and exposes admin operations through LiteLLM's built-in Admin UI.

The plan is intentionally LiteLLM-first:

- LiteLLM Proxy is the gateway core.
- LiteLLM built-in Admin UI is the v1 admin surface for virtual keys, teams, users, budgets, spend, model aliases, and admin operations.
- Railway is the production platform for the gateway services and managed Postgres.
- Cloudflare Tunnel plus Cloudflare Access is the public ingress model.
- Custom admin portal, custom admin API, and admin database are deferred.
- Railway managed Redis is deferred until multiple LiteLLM replicas, distributed rate limiting, or shared response/cache state are required.

No deployment plan can guarantee "without any issues." This plan makes success testable. Do not delete or replace the current repository until a scratch Railway staging deployment passes the approval gates in section 9.

## 2. Product goals

The v1 product must:

- Provide one stable internal LLM API endpoint for supported developer tools.
- Support OpenAI-compatible API calls for chat completions, embeddings, model listing, and streaming where required.
- Keep provider keys, LiteLLM master key, database URLs, Cloudflare secrets, and backup credentials out of browser/client code.
- Give each developer a separate LiteLLM virtual key.
- Enforce model aliases, provider access, same-tier fallback rules, and per-key budgets.
- Give admins/leads a protected UI for users, teams, keys, budgets, spend, aliases, and model operations.
- Make spend, budget exhaustion, provider failures, tunnel failures, and backup failures visible.
- Support disaster recovery through Railway-native backups and off-platform logical backups.
- Keep the v1 system small enough to operate without a custom admin product.

## 3. Primary users and surfaces

| User or system | Surface | Purpose |
| --- | --- | --- |
| Developer | `llm.thaarei.com` or equivalent developer API hostname | Call approved OpenAI-compatible routes from supported tools. |
| Admin/lead | `admin.thaarei.com` or equivalent admin hostname/path | Use LiteLLM Admin UI for keys, users, teams, budgets, spend, and aliases. |
| Operator | Railway, Cloudflare, repository docs/runbooks | Deploy, rotate secrets, manage backups, restore, and respond to incidents. |
| CI/CD | Repository workflows | Block unsafe config, secrets, floating images, and failed smoke tests. |

## 4. V1 product scope

### 4.1 Included in v1

- Railway-hosted LiteLLM Proxy.
- Railway managed Postgres for LiteLLM state.
- Cloudflare Tunnel as the public ingress/origin guard.
- Cloudflare Access for developer API and admin UI access control.
- LiteLLM Admin UI for admin workflows.
- Per-developer virtual keys.
- Per-key daily and monthly budgets.
- Company-level budget ceiling.
- Model aliases for normal development use.
- Same-tier model fallback only.
- Metadata-only logging by default.
- CI checks for secret/config safety.
- Staging validation proof gates before production.
- Off-platform logical backups and restore runbook.
- Runbooks for setup, deployment, rollback, key rotation, provider outage, tunnel outage, and restore.

### 4.2 Deferred from v1

- Custom admin portal.
- Custom admin API.
- Admin database.
- `llm-edge` / Envoy origin guard, unless Cloudflare Tunnel cannot satisfy proof gates.
- Railway Redis, unless multiple LiteLLM replicas, distributed rate limiting, or shared cache state are required.
- Monitoring service beyond Railway/LiteLLM/Cloudflare basics, unless the baseline is not enough.

### 4.3 Out of scope for v1

- Building a custom LLM router.
- Hosting local/GPU models.
- Kubernetes.
- RAG platform.
- Training/fine-tuning.
- Semantic caching for source-code prompts.
- `sensitive-code` alias.
- Broad raw prompt/response logging.
- Public virtual-key-only production access as the default.
- Replacing tools that cannot support a custom OpenAI-compatible endpoint or the required auth path.
- Multiple LiteLLM replicas and Redis unless uptime/scale requirements justify them.

## 5. Decisions made

### 5.1 Railway is the production platform

Railway is the regular production platform if all proof gates pass. This is acceptable for the expected small internal scale because the gateway brokers requests to external providers and does not host models or GPUs.

Start with one region close to the team. Start with one LiteLLM replica unless no-downtime deploys are required from day one. Move to two replicas only after Redis shared state, streaming, and deploy behavior are validated.

### 5.2 LiteLLM is the source of truth for gateway policy

LiteLLM owns:

- Virtual keys.
- Users and teams.
- Budgets and spend.
- Model aliases.
- Provider routing.
- Same-tier fallbacks.
- Provider credentials.
- Request authorization after Cloudflare Access allows traffic through.

No custom service should become a second source of truth for model policy, provider credentials, budgets, or virtual-key enforcement.

### 5.3 LiteLLM Admin UI is the v1 admin surface

The v1 admin surface is LiteLLM's built-in Admin UI behind Cloudflare Access. It already supports virtual keys, users, teams, budgets, spend visibility, model management, self-serve roles, and SSO/RBAC.

Custom admin portal features are deferred:

- Key request and approval workflow.
- Company-specific policy acknowledgement.
- Curated developer onboarding dashboard.
- Sanitized developer-only spend views beyond LiteLLM roles.

Use repo docs/wiki and GitHub Issues or Slack workflow for v1 onboarding and key requests. If a custom admin portal is later approved, it must use a separate database and a separate design review.

### 5.4 Cloudflare Tunnel is the origin guard

Cloudflare Tunnel is the v1 origin model. It creates outbound-only connections from Railway to Cloudflare, so LiteLLM does not need a public Railway origin.

The production design requires:

- No Railway-generated public domain or custom public domain on `litellm-proxy`.
- Public hostnames configured in Cloudflare Tunnel/Access, not directly on the Railway LiteLLM service.
- Separate Cloudflare Access policies for developer API traffic and admin UI traffic.
- LiteLLM virtual-key `Authorization` header preserved end-to-end.
- Developer API traffic blocked from LiteLLM admin/control routes.
- Streaming/SSE support.
- Tunnel health/degraded alerting.

### 5.5 Cloudflare Access compatibility is a launch blocker

Before production, each supported developer tool must prove one of:

- It can send Cloudflare Access service-token headers plus the LiteLLM `Authorization` header.
- It can run through a documented local header-injecting proxy/wrapper.
- It is excluded from v1 production support.

Initial tools to test:

- Continue.dev
- Cline/Roo-style VS Code tools
- Aider or equivalent coding CLI
- OpenAI SDK scripts
- Copilot CLI BYOK-compatible usage if applicable

Record each as:

- `supported`
- `supported-with-wrapper`
- `blocked`
- `not-in-v1`

Any public virtual-key-only fallback must be a risk exception with explicit approval, strict budgets, WAF/rate limits, monitoring, and an expiration date.

### 5.6 Future admin API must validate Cloudflare JWTs itself

No custom `admin-api` is part of v1. If a future phase introduces one, it must verify Cloudflare JWTs itself and must not trust `Cf-Access-Authenticated-User-Email` alone.

A future `admin-api` must:

- Require `Cf-Access-Jwt-Assertion`.
- Fetch/cache Cloudflare Access JWKS.
- Validate JWT signature.
- Validate issuer.
- Validate audience/application AUD.
- Validate expiry and issued-at.
- Map roles from verified email/groups only after JWT validation.
- Reject missing or invalid JWTs even if requests come through Railway private networking.
- Return clean `401/403` errors without stack traces or private details.

### 5.7 Secrets stay server-side

Provider keys, LiteLLM master key, Cloudflare secrets, database URLs, optional Redis URLs, backup credentials, and generated virtual keys must stay out of browser/client code and source control.

Do not commit:

- `.env`
- real Railway variables
- provider keys
- LiteLLM master key
- Cloudflare Access token secrets
- database URLs
- Redis URLs
- backup bucket credentials
- generated virtual keys

### 5.8 Backups must include off-platform logical backups

Railway volume backups are useful but not enough because they restore only within the same project/environment.

Use both:

- Railway native volume backups for LiteLLM Postgres: daily, weekly, and monthly schedules.
- Logical `pg_dump` backups from `backup-worker` to Cloudflare R2, S3, or Backblaze B2 with encryption, versioning, and restricted credentials.

Suggested initial RPO/RTO:

- RPO: 24 hours.
- RTO: 4 hours for internal production.

Perform a restore drill before pilot and then on a scheduled cadence.

### 5.9 Sensitive-code remains disabled

Do not create a `sensitive-code` alias until a ZDR/MAM-approved provider endpoint is contracted, configured, and tested.

CI must fail if `sensitive-code` or `sensitive-*` appears in LiteLLM config before the approval flag/document exists.

## 6. Product operating model

### 6.1 Developer onboarding

V1 onboarding should use lightweight docs and an approval workflow rather than a custom portal.

The onboarding flow should cover:

- Approved use cases.
- Disallowed sensitive/client/private/production incident content.
- Supported tools and setup instructions.
- How to request a virtual key.
- How to store and rotate the virtual key.
- Which model aliases to use.
- How to report failures with LiteLLM call ID.
- Budget windows and expected usage behavior.

### 6.2 Key requests and approvals

Use GitHub Issues/Actions or Slack Workflow for v1 key requests. Admins/leads create and manage keys in LiteLLM Admin UI.

The key request process should capture:

- Requester identity.
- Tool/client to be used.
- Required model aliases.
- Expected monthly usage.
- Budget tier.
- Approval owner.
- Expiration or review date if needed.

### 6.3 Supported-tool matrix

| Tool | Header support | Streaming support | Status |
| --- | --- | --- | --- |
| Continue.dev | To test in Phase 0 | To test in Phase 0 | Not production-supported until proven |
| Cline/Roo-style VS Code tool | To test in Phase 0 | To test in Phase 0 | Not production-supported until proven |
| Aider or equivalent CLI | To test in Phase 0 | To test in Phase 0 | Not production-supported until proven |
| OpenAI SDK scripts | To test in Phase 0 | To test in Phase 0 | Not production-supported until proven |
| Copilot CLI BYOK-compatible usage | To test in Phase 0 | To test in Phase 0 | Not production-supported until proven |

## 7. Notes and risks

- Railway is viable for regular internal production, but the design depends on Cloudflare Tunnel + Cloudflare Access working with real developer tools.
- If developer tools cannot use Access headers or a wrapper, the supported-tool list must be narrowed.
- A public virtual-key-only endpoint is operationally simple but weaker. It should be a temporary exception only, not the default design.
- Cloudflare Access service-token compatibility must be tested with real target tools before production.
- Railway-native backups alone are not enough for disaster recovery; keep off-platform logical backups.
- LiteLLM upgrades can include DB migrations; pin images and soak in staging.
- If uptime becomes business-critical, move to two LiteLLM replicas and add Redis after validating shared state, deploy behavior, and routing under load.
- If an external provider requires outbound IP allowlisting, Railway may need an egress proxy or a different hosting design.
- A custom admin portal should not be started until LiteLLM Admin UI plus docs/workflows proves insufficient.

## 8. Current readiness

This product plan is ready to guide Phase 0 validation and MVP implementation planning.

It is not ready for direct production implementation until these items are closed:

- Confirm Cloudflare Tunnel works reliably from Railway to private LiteLLM.
- Confirm at least one primary developer tool works with Cloudflare Access plus LiteLLM virtual key and streaming.
- Confirm supported-tool matrix and wrapper requirements.
- Confirm provider accounts and whether any provider requires static egress IP allowlisting.
- Confirm company budget, per-developer budgets, and alert thresholds.
- Confirm IdP/group mapping for admin, lead, and developer access.
- Confirm secure virtual-key distribution and revocation process.
- Confirm RPO/RTO, backup bucket choice, and restore-drill owner.

## 9. Approval gates before deleting or replacing this repository

Do not delete or replace the current repository until a scratch project proves:

- The Railway service topology deploys from a clean checkout.
- Cloudflare Tunnel prevents direct Railway-origin bypass.
- At least one target developer tool works with the required auth path.
- LiteLLM aliases, budgets, virtual keys, and provider routing work.
- LiteLLM Admin UI works behind Cloudflare Access for approved admins/leads.
- Backups and restore are tested.
- Smoke tests pass in staging.
- A production cutover/rollback runbook exists.

## 10. Review basis

Repository docs reviewed:

- `docs\implementation-plan.md`
- `docs\internal_llm_gateway_product_plan.md`
- `docs\internal_llm_gateway_technical_implementation_guide.md`
- Existing Phase 1-3 docs under `docs\impl-plan`

External/current docs reviewed:

- Railway: private networking, public networking, domains, variables, healthchecks, Postgres, volume backups, logs, metrics, scaling, and third-party observability.
- LiteLLM: deployment, config, virtual keys, users/budgets, caching, health endpoints, and logging.
- Cloudflare: Access service tokens, Access JWT behavior, and Cloudflare Tunnel.
- Envoy: JWT auth filter, considered but not selected for v1.

Independent review incorporated:

- GPT-5.5 review.
- Claude Opus 4.8 independent review.

Both reviews considered Railway viable for a 10-15 developer internal gateway if the final plan keeps v1 small and addresses:

- Direct Railway origin bypass by using Cloudflare Tunnel or an approved fallback.
- `/v1` developer-tool compatibility with Cloudflare Access.
- LiteLLM image pinning.
- Off-platform backups.
- Budget/error alerting.
- Secure virtual-key distribution and revocation.
- Mandatory staging validation gates.
