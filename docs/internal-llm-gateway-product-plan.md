# Internal LLM Gateway product plan

**Status:** Ready for Phase 0 validation; production implementation starts after the open gates are closed  
**Date:** 2026-06-05  
**Product:** Internal LLM Gateway  
**Production target:** Railway  
**Primary gateway/admin surface:** LiteLLM Proxy OSS with built-in Admin UI  
**Architecture reference:** `docs\internal-llm-gateway-architecture-tech-stack.md`
**Implementation roadmap:** `docs\internal-llm-gateway-implementation-roadmap.md`

## 1. Purpose

The Internal LLM Gateway gives approved developers a controlled OpenAI-compatible endpoint for day-to-day AI-assisted development while keeping provider credentials, budgets, routing policy, and operational controls server-side.

The product is a small internal platform for 10-15 developers. It does not host models or GPUs. It brokers requests to approved external LLM providers through LiteLLM, enforces model aliases and budgets, and exposes admin operations through LiteLLM's built-in Admin UI.

The plan is intentionally LiteLLM-first:

- LiteLLM Proxy is the gateway core.
- LiteLLM built-in Admin UI is the v1 admin surface for virtual keys, teams, users, budgets, spend, model aliases, and admin operations.
- Railway is the production platform for the gateway services and managed Postgres.
- LiteLLM native authentication is the public ingress/authentication model for the Phase 0 proof and MVP.
- Cloudflare Tunnel, Cloudflare Access, WAF, or an edge origin guard are deferred hardening options if public-origin risk becomes unacceptable.
- Custom admin portal, custom admin API, and admin database are deferred.
- Railway managed Redis is deferred until multiple LiteLLM replicas, distributed rate limiting, or shared response/cache state are required.

No deployment plan can guarantee "without any issues." This plan makes success testable. Do not delete or replace the current repository until a scratch Railway staging deployment passes the approval gates in section 9.

## 2. Product goals

The v1 product must:

- Provide one stable internal LLM API endpoint for supported developer tools.
- Support OpenAI-compatible API calls for chat completions, embeddings, model listing, and streaming where required.
- Keep provider keys, LiteLLM master key, database URLs, optional Cloudflare secrets, and backup credentials out of browser/client code.
- Give each developer a separate LiteLLM virtual key.
- Enforce model aliases, provider access, same-tier fallback rules, and per-key budgets.
- Give admins/leads a protected UI for users, teams, keys, budgets, spend, aliases, and model operations.
- Make spend, budget exhaustion, provider failures, authentication failures, public-origin abuse signals, and backup failures visible.
- Support disaster recovery through Railway-native backups and off-platform logical backups.
- Keep the v1 system small enough to operate without a custom admin product.

## 3. Primary users and surfaces

| User or system | Surface | Purpose |
| --- | --- | --- |
| Developer | `llm.thaarei.com` or equivalent developer API hostname | Call approved OpenAI-compatible routes from supported tools. |
| Admin/lead | `admin.thaarei.com` or equivalent admin hostname/path | Use LiteLLM Admin UI for keys, users, teams, budgets, spend, and aliases. |
| Operator | Railway, LiteLLM, repository docs/runbooks | Deploy, rotate secrets, manage backups, restore, and respond to incidents. |
| CI/CD | Repository workflows | Block unsafe config, secrets, floating images, and failed smoke tests. |

## 4. V1 product scope

### 4.1 Included in v1

- Railway-hosted LiteLLM Proxy.
- Railway managed Postgres for LiteLLM state.
- Railway public/custom domain for LiteLLM, protected by LiteLLM native authentication and compensating controls.
- LiteLLM virtual-key authentication, budgets, rate limits, and RBAC as the primary access-control layer.
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
- Runbooks for setup, deployment, rollback, key rotation, provider outage, public-origin abuse, and restore.

### 4.2 Deferred from v1

- Custom admin portal.
- Custom admin API.
- Admin database.
- Cloudflare Tunnel, Cloudflare Access, WAF, or `llm-edge` / Envoy origin guard unless public-origin risk or production requirements justify them.
- Railway Redis, unless multiple LiteLLM replicas, distributed rate limiting, or shared cache state are required.
- Monitoring service beyond Railway/LiteLLM basics, unless the baseline is not enough.

### 4.3 Out of scope for v1

- Building a custom LLM router.
- Hosting local/GPU models.
- Kubernetes.
- RAG platform.
- Training/fine-tuning.
- Semantic caching for source-code prompts.
- `sensitive-code` alias.
- Broad raw prompt/response logging.
- Unauthenticated or shared-key production access.
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
- Request authorization at the public LiteLLM gateway.

No custom service should become a second source of truth for model policy, provider credentials, budgets, or virtual-key enforcement.

### 5.3 LiteLLM Admin UI is the v1 admin surface

The v1 admin surface is LiteLLM's built-in Admin UI protected by LiteLLM-native authentication/RBAC and strong admin credentials. It already supports virtual keys, users, teams, budgets, spend visibility, model management, self-serve roles, and SSO/RBAC where configured.

Because the new design exposes the LiteLLM origin publicly, admin access needs extra care:

- Use a strong, unique admin credential or LiteLLM-supported SSO before production.
- Do not distribute the LiteLLM master key to developers.
- Confirm developer virtual keys cannot access admin/control routes.
- Disable public docs/Swagger and any unauthenticated control surfaces where supported.

Custom admin portal features are deferred:

- Key request and approval workflow.
- Company-specific policy acknowledgement.
- Curated developer onboarding dashboard.
- Sanitized developer-only spend views beyond LiteLLM roles.

Use repo docs/wiki and GitHub Issues or Slack workflow for v1 onboarding and key requests. If a custom admin portal is later approved, it must use a separate database and a separate design review.

### 5.4 LiteLLM-native auth is the primary ingress guard

The approved Phase 0/MVP direction is a public Railway/custom domain for `litellm-proxy`, protected primarily by LiteLLM-native authentication, budgets, rate limits, RBAC, and metadata-only logging.

This is simpler than Cloudflare Tunnel + Access and works for a small internal gateway proof, but it is a weaker security posture because a leaked virtual key can be used from the public internet. The design requires explicit risk acceptance and these compensating controls:

- Per-developer LiteLLM virtual keys; no shared production developer key.
- Strict per-key daily/monthly budgets, rate limits, and model alias restrictions.
- Strong admin credentials or LiteLLM-supported SSO.
- Master/admin keys stored only as sealed Railway variables and never distributed.
- Public docs/Swagger disabled where supported.
- Metadata-only logging; raw prompt/response logging off by default.
- Alerts for spend spikes, 401/403 spikes, provider errors, and gateway 5xx.
- Key distribution, revocation, and rotation runbooks.
- Streaming/SSE support.
- Cloudflare Tunnel/Access/WAF can be added later as a hardening layer if public-origin risk is not acceptable.

### 5.5 Developer-tool compatibility is a launch blocker

Before production, each supported developer tool must prove:

- It can target an OpenAI-compatible base URL.
- It can send the LiteLLM `Authorization: Bearer ...` virtual-key header.
- It supports streaming if streaming is required for that tool.
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

The public-origin LiteLLM-native-auth design must be recorded as an accepted risk with strict budgets, rate limits, monitoring, and a review/expiry date.

### 5.6 Future admin API must authenticate independently

No custom `admin-api` is part of v1. If a future phase introduces one, it must have its own authentication and authorization design and must not trust forwarded identity headers alone.

A future `admin-api` must:

- Validate any upstream identity token signature, issuer, audience, expiry, and issued-at.
- If Cloudflare Access is added later, require and validate `Cf-Access-Jwt-Assertion`; do not trust `Cf-Access-Authenticated-User-Email` alone.
- Map roles from verified identity claims only after token validation.
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
- A public LiteLLM-native-auth endpoint is operationally simple but weaker than an identity-aware edge gate. It is the selected MVP path only with documented risk acceptance, strict budgets, rate limits, monitoring, and admin controls.
- Cloudflare Tunnel/Access/WAF remains a future hardening option if public-origin risk is not acceptable.
- Railway-native backups alone are not enough for disaster recovery; keep off-platform logical backups.
- LiteLLM upgrades can include DB migrations; pin images and soak in staging.
- If uptime becomes business-critical, move to two LiteLLM replicas and add Redis after validating shared state, deploy behavior, and routing under load.
- If an external provider requires outbound IP allowlisting, Railway may need an egress proxy or a different hosting design.
- A custom admin portal should not be started until LiteLLM Admin UI plus docs/workflows proves insufficient.

## 8. Current readiness

This product plan is ready to guide Phase 0 validation and MVP implementation planning.

It is not ready for direct production implementation until these items are closed:

- Confirm public Railway/custom LiteLLM endpoint requires valid LiteLLM auth.
- Confirm at least one primary developer tool works with LiteLLM virtual key and streaming.
- Confirm supported-tool matrix and wrapper requirements.
- Confirm provider accounts and whether any provider requires static egress IP allowlisting.
- Confirm company budget, per-developer budgets, and alert thresholds.
- Confirm admin/lead/developer access model, including Admin UI controls and per-developer virtual-key ownership.
- Confirm secure virtual-key distribution and revocation process.
- Confirm RPO/RTO, backup bucket choice, and restore-drill owner.

## 9. Approval gates before deleting or replacing this repository

Do not delete or replace the current repository until a scratch project proves:

- The Railway service topology deploys from a clean checkout.
- Public Railway/custom LiteLLM endpoint rejects missing/invalid keys.
- At least one target developer tool works with the required auth path.
- LiteLLM aliases, budgets, virtual keys, and provider routing work.
- LiteLLM Admin UI is controlled for approved admins/leads and developer keys cannot access admin/control routes.
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

- Public-origin risk acceptance and compensating LiteLLM-native controls.
- `/v1` developer-tool compatibility with LiteLLM native auth.
- LiteLLM image pinning.
- Off-platform backups.
- Budget/error alerting.
- Secure virtual-key distribution and revocation.
- Mandatory staging validation gates.
