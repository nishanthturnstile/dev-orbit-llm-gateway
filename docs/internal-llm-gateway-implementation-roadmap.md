# Internal LLM Gateway implementation roadmap

**Status:** Phase 5 blocked - LiteLLM staging deployment and runtime policy validation passed except `dev-search`, which reaches Perplexity but fails with the staged provider key
**Date:** 2026-06-05  
**Product:** Internal LLM Gateway  
**Production target:** Railway  
**Product reference:** `docs\internal-llm-gateway-product-plan.md`  
**Architecture reference:** `docs\internal-llm-gateway-architecture-tech-stack.md`

## 1. Purpose

This roadmap is the implementation source of truth for building the Internal LLM Gateway from scratch in a phase-wise manner.

The roadmap translates the approved product plan and architecture into an execution sequence. It starts with launch-blocking validation, then creates the repository structure, service scaffolding, policy/config, CI gates, Railway staging, LiteLLM deployment, public-origin access validation, backups, staging proof gates, production pilot, and post-pilot hardening.

This document owns:

- Phase order.
- Phase dependencies.
- Phase deliverables.
- Phase exit criteria.
- Implementation readiness gates.
- Runbook/documentation outputs per phase.

The product plan owns product goals, scope, user surfaces, and product decisions. The architecture and tech stack document owns service topology, traffic flows, technology choices, variables, platform rules, security controls, and CI policy rules.

## 2. Roadmap principles

- Build from a clean, reproducible repository structure.
- Validate launch-blocking assumptions before investing in durable infrastructure.
- Keep Phase 0 disposable; do not promote spike resources to staging or production.
- Keep LiteLLM as the gateway policy source of truth.
- Use LiteLLM-native authentication as the Phase 0/MVP public ingress control.
- Allow a public Railway/custom domain for `litellm-proxy` only after LiteLLM virtual-key auth, admin controls, budgets, rate limits, metadata-only logging, and secret handling are configured.
- Keep Cloudflare Tunnel, Cloudflare Access, WAF, and edge-origin services out of the current implementation path unless a later design decision explicitly reintroduces them.
- Keep custom admin portal/API/database out of v1.
- Keep Redis and multiple LiteLLM replicas deferred until uptime/scale/shared-state needs justify them.
- Keep provider keys, LiteLLM keys, database URLs, edge-service secrets, and backup credentials out of source control and browser/client code.
- Do not advance to production until staging proof gates pass.
- Do not delete or replace the current repository until the approval gates in the product plan pass.

## 3. Phase overview

| Phase | Name | Primary outcome |
| ---: | --- | --- |
| 0 | Launch-blocker validation and disposable proof spike | Prove Railway + LiteLLM-native auth can satisfy the highest-risk assumptions before durable build-out. |
| 1 | Repository and project structure | Create the clean repo shape, docs homes, service boundaries, and baseline examples. |
| 2 | Local service scaffolding and policy/config authoring | Author service scaffolds and LiteLLM policy/config artifacts locally. |
| 3 | CI/CD, secret scanning, and policy gates | Make unsafe secrets/config/images fail before deployment. |
| 4 | Durable Railway staging provisioning | Create repeatable staging Railway services, variables, and private networking. |
| 5 | LiteLLM deployment and runtime policy validation | Deploy public-origin LiteLLM in staging and validate native auth, aliases, budgets, rate limits, health, logging, and provider routing. |
| 6 | Public-origin hardening and access validation | Validate public Railway/custom-domain exposure, admin controls, auth-failure handling, and LiteLLM-native public-origin controls. |
| 7 | Backups, restore, alerts, and runbooks | Make state recoverable and operational failures visible before production. |
| 8 | Staging proof gates and client compatibility | Prove end-to-end behavior, smoke tests, and supported developer tools. |
| 9 | Production deployment, cutover, and pilot | Promote proven artifacts to production and run a controlled pilot. |
| 10 | Post-pilot hardening and deferred capabilities | Decide whether to add Redis, multiple replicas, monitoring extensions, custom admin, or separately approved edge hardening. |

### Execution tracking

Track implementation progress in `docs\operations\implementation-status.md`.

The tracker records each phase status, Phase 0 task status, evidence, and blockers. Keep this roadmap focused on phase order, dependencies, deliverables, and exit criteria; keep mutable execution status in the tracker.

## 4. Phase 0 - Launch-blocker validation and disposable proof spike

### Goal

Close the decisions that can invalidate the Railway production design before building the full repository or durable staging environment.

Phase 0 may create temporary Railway, LiteLLM, Postgres, public-domain, and provider resources. These resources are a disposable proof spike only. They must not become the durable staging environment and must not be promoted to production.

### Dependencies

- Access to the target Railway workspace or a temporary validation workspace.
- Approval to expose a temporary public Railway/custom LiteLLM endpoint protected by LiteLLM-native authentication.
- At least one low-cost approved LLM provider/model key.
- A developer tool candidate that can target an OpenAI-compatible endpoint.

### Scope

- Confirm Railway workspace, billing plan, target region, and expected monthly platform cost.
- Confirm public-origin risk acceptance for LiteLLM-native authentication.
- Confirm target domain names:
    - `llm.thaarei.com` for developer API traffic.
    - `admin.thaarei.com` or an equivalent admin hostname/path for LiteLLM Admin UI.
- Confirm provider accounts: OpenAI, Anthropic, Fireworks AI, Perplexity, or the final approved provider list.
- Confirm whether any provider requires static egress IP allowlisting.
- Confirm initial company monthly budget, per-developer budget, and alert thresholds.
- Confirm IdP/group source for admin, lead, and developer access.
- Confirm secure virtual-key distribution and revocation process.
- Confirm log retention and metadata-only logging policy.
- Confirm initial SLA target: best-effort internal, business-hours critical, or higher.
- Confirm max request body, timeout, and streaming limits.
- Stand up a disposable proof using LiteLLM, Postgres, a public Railway/custom endpoint, and one low-cost provider/model.
- Prove one primary developer tool can call `/v1/chat/completions` with a LiteLLM virtual key, including streaming.
- Prove missing/invalid LiteLLM keys are rejected.
- Prove admin/control routes and public docs/Swagger are disabled or protected from developer virtual keys.

### Deliverables

- Phase 0 decision record under `docs\decisions`.
- Disposable proof notes with resource IDs, test commands, and teardown status.
- Supported-tool validation notes for at least one primary developer tool.
- Static egress IP assessment.
- Initial budget and alert threshold proposal.
- Initial IdP/group mapping proposal.
- Initial key distribution and revocation proposal.

### Exit criteria

- Public Railway/custom LiteLLM endpoint works only with valid LiteLLM-native authentication.
- `/v1` access strategy is proven with at least one real developer tool.
- Streaming works through the temporary public LiteLLM path.
- Missing/invalid LiteLLM keys are rejected.
- Developer virtual keys cannot access LiteLLM admin/control routes.
- Public docs/Swagger are disabled where supported.
- Public-origin risk is accepted with owner, budget limits, rate limits, monitoring, and review/expiry date.
- Provider static egress IP requirements are confirmed. If any required provider needs allowlisting that Railway cannot satisfy, pause implementation and redesign egress before proceeding.
- The team agrees the MVP uses LiteLLM Admin UI, not a custom admin portal.
- Disposable proof resources are torn down or explicitly marked as non-production/non-staging.

### Runbook/docs outputs

- `docs\decisions\phase-0-launch-blockers.md`
- `docs\onboarding\supported-tools-matrix.md` draft
- `docs\operations\key-distribution.md` draft

## 5. Phase 1 - Repository and project structure

### Goal

Create the clean repository foundation for the MVP with service boundaries, documentation homes, examples, and hygiene files.

### Dependencies

- Phase 0 launch-blocker decisions closed.
- Final service list confirmed from the architecture document.

### Scope

- Create the base repository structure:

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

- Add root README describing:
    - product purpose
    - production target
    - service list
    - local development approach
    - deployment model
    - links to product, architecture, and roadmap docs
- Add `.gitignore` for `.env`, local secrets, generated keys, local test outputs, and backup artifacts.
- Add `.env.example` with placeholder variable names only.
- Add service README files explaining service boundaries and what must not be stored in each service.
- Add docs homes for decisions, runbooks, security, onboarding, and operations.

### Deliverables

- Clean repository tree.
- Root README.
- `.gitignore`.
- `.env.example`.
- Service README placeholders.
- Docs directory placeholders.

### Exit criteria

- The repo documents Railway + LiteLLM architecture, service boundaries, and deferred components.
- No real secrets or generated credentials are present.
- Deferred directories are not created unless approved:
    - `apps\admin-web`
    - `services\admin-api`
    - `services\llm-edge`
    - Cloudflare tunnel/access/edge services
- The repository can be checked out cleanly by another developer.

### Runbook/docs outputs

- `docs\decisions\v1-service-boundaries.md`
- `docs\operations\repository-structure.md`

## 6. Phase 2 - Local service scaffolding and policy/config authoring

### Goal

Author the local service scaffolds and LiteLLM policy/config artifacts before any durable deployment.

This phase owns local artifact creation. Later phases validate and deploy these artifacts; they should not redefine the policy in separate places.

### Dependencies

- Phase 1 repository structure exists.
- Phase 0 provider, budget, access, and tool assumptions are known.

### Scope

- Create `services\litellm\Dockerfile` from a pinned LiteLLM database-capable image digest.
- Create `services\litellm\config.yaml` using environment references for secrets.
- Create `services\litellm\scripts\verify-config.sh`.
- Create `services\backup-worker\Dockerfile`.
- Create backup and restore-check scripts.
- Create `config\litellm\model-aliases.yaml`.
- Create `config\litellm\provider-denylist.yaml`.
- Create `config\litellm\policy.md`.
- Create initial smoke test skeletons.

### LiteLLM policy baseline

Define these initial aliases:

- `dev-fast`
- `dev-code`
- `dev-reasoning`
- `dev-long-horizon`
- `dev-search`
- `dev-embed`
- `dev-vision`
- `premium-code`
- `premium-planning`
- `ultra-premium-code`
- `ultra-premium-planning`

Do not define `sensitive-code`.

Policy/config requirements:

- Use `os.environ/VAR_NAME` references for all secrets.
- Set same-tier fallbacks only.
- Set explicit retries and timeouts.
- Keep response caching default-off for code prompts.
- Keep raw prompt/response logging disabled by default.
- Redact user/key information where LiteLLM supports it.
- Hide detailed health/provider output from broad/public responses.
- Keep provider credentials in Railway variables only.
- Do not use `--detailed_debug` in production config.

### Deliverables

- LiteLLM Dockerfile and config.
- Backup worker scaffold.
- Model alias config.
- Provider denylist config.
- Policy document.
- Smoke test skeletons.

### Exit criteria

- Local config parses.
- All secrets are represented as environment references or placeholders.
- Required aliases exist.
- `sensitive-code` and `sensitive-*` aliases are absent.
- Service scaffolds include README notes for deployment and security boundaries.
- No service exposes or assumes a public Railway domain for `litellm-proxy`.

### Runbook/docs outputs

- `docs\security\model-alias-policy.md`
- `docs\operations\provider-config.md`
- `docs\operations\local-config-validation.md`

## 7. Phase 3 - CI/CD, secret scanning, and policy gates

### Goal

Make unsafe secrets, config, image choices, and policy drift fail before deployment.

This phase validates the artifacts created in Phase 2. It does not own the policy definitions; it owns enforcement.

### Dependencies

- Phase 2 config and service scaffolds exist.

### Scope

- Add LiteLLM config linting.
- Add secret scanning.
- Add image pinning checks.
- Add initial smoke-test workflow skeleton.
- Add repository hygiene checks.
- Add documented local validation commands.

CI must fail on:

- Committed `.env` files.
- Known provider key patterns.
- Plaintext provider keys in LiteLLM config.
- LiteLLM config secrets not using env references.
- Missing required aliases.
- `sensitive-code` or `sensitive-*` aliases before approval.
- CN-hosted/first-party restricted provider endpoints.
- `--detailed_debug` in production config.
- Repo artifacts containing provider keys, LiteLLM keys, database URLs, Redis URLs, private Railway domains, or backup credentials.
- LiteLLM image not pinned by digest.
- LiteLLM image signature verification failure if signature verification is enabled by policy.
- Smoke test failures.

### Deliverables

- `.github\workflows\ci.yml`
- `.github\workflows\image-policy.yml`
- `.github\workflows\staging-smoke.yml` skeleton
- `scripts\check-secrets.ps1`
- `scripts\lint-litellm-config.ps1`
- `scripts\smoke-railway.ps1` skeleton
- Gitleaks or equivalent configuration

### Exit criteria

- Unsafe config cannot merge.
- Secret scanning runs locally and in CI.
- LiteLLM config linting runs locally and in CI.
- Image pinning checks run in CI.
- Smoke-test workflow can be run once staging exists.

### Runbook/docs outputs

- `docs\operations\ci-policy-gates.md`
- `docs\security\secret-scanning.md`

## 8. Phase 4 - Durable Railway staging provisioning

### Goal

Create a durable, repeatable Railway staging environment from committed configuration and documented steps.

This phase creates real staging. It is separate from the disposable Phase 0 proof spike.

### Dependencies

- Phase 0 launch blockers closed.
- Phase 1 repository structure exists.
- Phase 2 service scaffolds exist.
- Phase 3 baseline CI gates exist.

### Scope

- Create Railway project.
- Create `staging` environment.
- Add managed Postgres for LiteLLM.
- Add app services:
    - `litellm-proxy`
    - `backup-worker`
- Confirm Postgres variables generated by Railway.
- Prefer private/internal connection variables.
- Never use public TCP proxy URLs from app services.
- Remove/avoid public domains from `litellm-proxy`, Postgres, and backup worker.
- Configure service root directories and watch paths.
- Configure Railway healthcheck path for LiteLLM as `/health/readiness`.
- Configure staging variables with non-production values.
- Keep production secrets out of staging.

### Deliverables

- Railway project.
- `staging` environment.
- Staging `litellm-postgres`.
- Staging app service shells.
- Documented Railway service IDs and environment IDs in an internal/non-secret location.
- `config\railway\staging.md`.

### Exit criteria

- Staging services exist.
- Private networking works between `litellm-proxy`, Postgres, and backup worker.
- Staging variables do not include production secrets.
- `litellm-proxy` public Railway/custom domain is enabled only after LiteLLM native auth, admin controls, budgets, rate limits, metadata-only logging, and secret handling are configured.
- Postgres is not accessed through public TCP proxy URLs by app services.
- Staging provisioning can be reproduced from a clean checkout and documented commands.

### Runbook/docs outputs

- `docs\runbooks\railway-project-service-setup.md`
- `docs\runbooks\staging-deployment.md`
- `config\railway\staging.md`

## 9. Phase 5 - LiteLLM deployment and runtime policy validation

### Goal

Deploy LiteLLM in staging and prove that native-auth runtime behavior matches the policy/config authored earlier. Durable public-origin exposure is deferred to Phase 6.

This phase owns deployment and runtime validation. It does not redefine aliases or policy outside the committed config artifacts.

### Dependencies

- Phase 4 durable staging exists.
- Phase 2 LiteLLM config exists.
- Phase 3 CI policy gates pass.

### Scope

- Deploy `litellm-proxy` to Railway staging without a durable public URL.
- Set `DATABASE_URL` from the actual Railway Postgres service reference `${{Postgres.DATABASE_URL}}`.
- Set approved provider keys as sealed Railway variables.
- Set `LITELLM_MASTER_KEY` as sealed Railway variable starting with `sk-`.
- Set `LITELLM_SALT_KEY` as sealed Railway variable before first boot while `store_model_in_db: true` remains enabled.
- Set `PORT=4000` or start command compatible with Railway's injected `PORT`.
- Validate `/health/readiness`.
- Confirm `/health` deep provider probe is not used for Railway deployment healthcheck.
- Validate aliases:
    - `dev-fast`
    - `dev-code`
    - `dev-reasoning`
    - `dev-long-horizon`
    - `dev-search` remains present but runtime validation is blocked until a valid approved `PERPLEXITY_API_KEY` is sealed and loaded.
    - `dev-embed`
    - `dev-vision`
    - `premium-code`
    - `premium-planning`
    - `ultra-premium-code`
    - `ultra-premium-planning`
- Validate `sensitive-code` is absent.
- Validate same-tier fallbacks only.
- Validate retries and timeouts.
- Validate metadata-only logging.
- Validate response cache remains default-off for code prompts.
- Keep LiteLLM Admin UI disabled in Phase 5 and validate admin/control APIs through approved operator-context API calls.

### Deliverables

- Staging LiteLLM deployment.
- Staging LiteLLM config validation output.
- Admin UI disabled posture notes.
- Initial virtual-key creation procedure.
- Runtime policy validation notes.

### Exit criteria

- LiteLLM starts in staging.
- Readiness healthcheck passes.
- No durable public URL remains for `litellm-proxy`.
- LiteLLM persists users, virtual keys, teams, budgets, and spend to Postgres.
- Model aliases route to approved providers only.
- Budget/spend/revocation behavior is validated with controlled disposable keys under the approved Phase 5 validation spend cap.
- Logs do not contain known prompt/response sentinel strings.

### Runbook/docs outputs

- `docs\runbooks\litellm-virtual-key-creation.md`
- `docs\runbooks\litellm-virtual-key-revocation.md`
- `docs\operations\litellm-policy-validation.md`

## 10. Phase 6 - Public-origin hardening and access validation

### Goal

Make the public LLM API and admin UI safe enough for MVP use with LiteLLM-native authentication and documented residual risk.

### Dependencies

- Phase 4 staging services exist.
- Phase 5 LiteLLM is healthy with native auth.
- Public-origin risk acceptance is recorded.

### Scope

- Configure Railway public/custom domain for the LiteLLM proof/staging endpoint.
- Confirm LiteLLM virtual-key auth is required for developer API traffic.
- Configure strong Admin UI credentials or LiteLLM-supported SSO before production.
- Disable public docs/Swagger where supported.
- Confirm developer virtual keys cannot use LiteLLM admin/control routes:
    - `/ui`
    - `/key/*`
    - `/user/*`
    - `/team/*`
    - `/config/*`
    - `/admin*`
    - Swagger/admin docs routes unless explicitly protected
- Preserve LiteLLM virtual-key `Authorization` behavior.
- Support streaming/SSE end-to-end.
- Configure alerts for 401/403 spikes, spend spikes, provider errors, and gateway 5xx.
- Record that Cloudflare Tunnel/Access/WAF and edge-origin services are out of the current implementation path unless a later design decision explicitly reintroduces them.

### Deliverables

- Staging public Railway/custom developer API endpoint.
- Staging Admin UI access-control decision.
- Public-origin risk acceptance record.
- Native-auth and admin-control validation notes.
- Auth-failure/spend/provider/gateway alert plan.
- No-Cloudflare-current-implementation decision record.

### Exit criteria

- Anonymous or missing-key request to `llm.thaarei.com` or staging equivalent is blocked.
- Invalid LiteLLM virtual key is blocked.
- Valid LiteLLM virtual key succeeds on approved `/v1` routes.
- Streaming completion works through the public LiteLLM endpoint.
- Admin UI is available only to approved admins/leads through LiteLLM-native auth, strong credentials, SSO, or an approved hardening layer.
- Developer virtual keys cannot access LiteLLM Admin UI or admin/control routes.
- Public docs/Swagger are disabled or explicitly protected.

### Runbook/docs outputs

- `docs\decisions\public-origin-risk-acceptance.md`
- `docs\security\litellm-native-auth-policy.md`
- `docs\onboarding\supported-tools-matrix.md` update

## 11. Phase 7 - Backups, restore, alerts, and runbooks

### Goal

Make production state recoverable and operational failures visible before real usage.

### Dependencies

- Phase 4 staging Postgres exists.
- Phase 5 LiteLLM stores state in Postgres.
- Phase 6 public LiteLLM-native path is configured enough for health and availability checks.

### Scope

- Enable Railway native volume backups on LiteLLM Postgres.
- Configure daily, weekly, and monthly backup schedules.
- Create `backup-worker` scheduled job for logical backups:
    - `pg_dump` LiteLLM Postgres
    - encrypt/compress
    - upload to R2/S3/B2 with versioning
    - log metadata only
- Create restore procedure:
    - restore Railway volume snapshot
    - restore logical backup into new Postgres service
    - repoint `DATABASE_URL`
    - verify LiteLLM virtual key auth
    - reconcile revoked keys after restore
- Add key rotation runbooks:
    - provider keys
    - LiteLLM master/admin credential
    - developer virtual keys
- Add outage runbooks:
    - provider outage
    - Postgres outage
    - Railway deploy rollback
    - bad LiteLLM config rollback
- Add alerts:
    - company budget threshold
    - per-key spend spike
    - provider error rate
    - LiteLLM 5xx/error rate
    - backup failure

### Deliverables

- Railway native backup schedule.
- Backup worker deployment.
- Off-platform backup bucket/prefix.
- Encrypted logical backup artifacts.
- Restore drill notes.
- Alert definitions.
- Required operational runbooks.

### Exit criteria

- Backup job succeeds in staging.
- Restore drill succeeds into a fresh staging database.
- Restored database supports LiteLLM virtual-key auth.
- Revoked-key reconciliation procedure is documented.
- RPO/RTO are documented.
- Budget/error/backup alerts are configured.
- Production cutover/rollback runbook draft exists.

### Runbook/docs outputs

- `docs\runbooks\railway-backup-restore.md`
- `docs\runbooks\off-platform-logical-backup-restore.md`
- `docs\runbooks\provider-key-rotation.md`
- `docs\runbooks\budget-spend-alert-response.md`
- `docs\runbooks\litellm-postgres-outage.md`
- `docs\runbooks\provider-outage-same-tier-fallback.md`
- `docs\runbooks\railway-deploy-rollback.md`
- `docs\runbooks\prompt-log-leakage-investigation.md`

## 12. Phase 8 - Staging proof gates and client compatibility

### Goal

Prove Railway + LiteLLM behavior in staging before production exists using the LiteLLM-native public Railway/custom endpoint.

### Dependencies

- Phase 5 LiteLLM deployment is healthy.
- Phase 6 public-origin hardening and access validation are configured.
- Phase 7 backup/restore baseline exists.
- At least one target developer tool is available for testing.

### Mandatory smoke tests

- `GET /health/readiness` passes for LiteLLM.
- Anonymous public request to `llm.thaarei.com` or staging equivalent is blocked.
- Missing LiteLLM key is blocked.
- Valid LiteLLM virtual key can call `/v1/chat/completions`.
- Invalid LiteLLM key is blocked.
- `/v1/models` exposes aliases, not provider credentials.
- Disallowed model/provider names are blocked for developer keys.
- Per-key daily/monthly budget windows block over-budget requests.
- Same-tier fallback works for a controlled simulated provider failure.
- No fallback silently downgrades premium aliases to weaker tiers.
- Streaming SSE works through the public/custom LiteLLM endpoint.
- Response cache remains off for code prompts unless explicitly requested and policy-allowed.
- Railway logs do not contain known prompt/response sentinel strings.
- LiteLLM Admin UI is not accessible to developer API service-token users.
- Backup worker creates off-platform logical backups.
- Restore drill works into a fresh staging database.
- Provider key rotation runbook works for one provider.

### Client compatibility matrix

| Tool | Header support | Streaming support | Status |
| --- | --- | --- | --- |
| Continue.dev | To test in Phase 0/8 | To test in Phase 0/8 | Not production-supported until proven |
| Cline/Roo-style VS Code tool | To test in Phase 0/8 | To test in Phase 0/8 | Not production-supported until proven |
| Aider or equivalent CLI | To test in Phase 0/8 | To test in Phase 0/8 | Not production-supported until proven |
| OpenAI SDK scripts | To test in Phase 0/8 | To test in Phase 0/8 | Not production-supported until proven |
| Copilot CLI BYOK-compatible usage | To test in Phase 0/8 | To test in Phase 0/8 | Not production-supported until proven |

### Deliverables

- Staging smoke-test report.
- Client compatibility matrix.
- Wrapper instructions for tools that need local header injection.
- Blocked-tool list.
- Production readiness review notes.

### Exit criteria

- All mandatory smoke tests pass.
- At least one primary developer tool works end-to-end with the required LiteLLM-native auth path.
- Blocked tools are documented and excluded from launch.
- Risk exceptions, if any, have owner, expiry, budget limits, rate limits, and monitoring.
- Product approval gates are ready for production creation.

### Runbook/docs outputs

- `docs\onboarding\supported-developer-tool-setup.md`
- `docs\operations\staging-proof-gates.md`
- `docs\decisions\production-readiness-review.md`

## 13. Phase 9 - Production deployment, cutover, and pilot

### Goal

Promote the proven staging stack to production and operate a small controlled pilot.

### Dependencies

- Phase 8 staging proof gates pass.
- Production secrets and provider accounts are approved.
- Production public/custom domains and LiteLLM-native access controls are approved.
- Production cutover/rollback runbook is ready.

### Scope

- Create `production` Railway environment only after staging proof gates pass.
- Create production Railway variables from approved secret store/operator input.
- Deploy pinned artifacts/images to production.
- Configure production Railway/custom domains and LiteLLM-native access controls.
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
- Review LiteLLM auth-failure, spend, provider-error, and gateway-error signals.
- Tune aliases and budgets based on real usage.

### Deliverables

- Production Railway environment.
- Production LiteLLM deployment.
- Production public/custom domain and LiteLLM-native access setup.
- Production backup and alert setup.
- Initial admin/lead users.
- Initial pilot developer virtual keys.
- Production smoke-test report.
- Pilot launch announcement.
- Cutover and rollback runbooks.

### Exit criteria

- Production endpoint requires valid LiteLLM-native authentication.
- LiteLLM Admin UI is available only to approved admins/leads through configured LiteLLM-native controls.
- Initial users can make approved requests.
- Budgets and model restrictions are enforced.
- Backups are running.
- Restore path has been tested in staging and documented for production.
- Pilot users can use the gateway day-to-day for approved non-sensitive work.
- Production cutover/rollback process is documented.
- Any public Railway/custom origin for `litellm-proxy` is protected by LiteLLM-native authentication, admin controls, budgets, rate limits, and metadata-only logging.

### Runbook/docs outputs

- `docs\runbooks\production-deployment.md`
- `docs\runbooks\rollback.md`
- `docs\onboarding\production-usage-rules.md`
- `docs\operations\pilot-review.md`

## 14. Phase 10 - Post-pilot hardening and deferred capabilities

### Goal

Use pilot evidence to decide whether to add hardening, scale, observability, or deferred product capabilities.

### Dependencies

- Phase 9 pilot has enough real usage to evaluate stability, cost, support burden, and tool compatibility.

### Scope

- Review pilot spend, latency, provider failures, budget hits, and support issues.
- Review whether Railway CPU/memory/network/disk metrics are sufficient.
- Review whether LiteLLM metadata and Prometheus metrics are sufficient.
- Decide whether to add:
    - Railway Redis
    - multiple LiteLLM replicas
    - external monitoring/alerting service
    - OpenTelemetry/Langfuse/SigNoz/Grafana stack
    - custom admin portal/API
    - separately approved edge hardening
    - additional providers
    - additional supported tools
- Revisit RPO/RTO and backup cadence.
- Revisit budget levels and alert thresholds.
- Revisit provider egress requirements.
- Revisit `sensitive-code` only if a ZDR/MAM-approved provider endpoint is contracted, configured, and tested.

### Redis and multi-replica decision criteria

Do not add Redis or multiple LiteLLM replicas by default.

Consider Redis and multiple replicas only if:

- Uptime becomes business-critical.
- No-downtime deploys are required.
- A single LiteLLM replica is a proven bottleneck.
- Distributed rate limiting is required.
- Shared response/cache state is explicitly approved.
- Streaming behavior, deploy behavior, and routing behavior are validated under load.

Redis shared state is mandatory before multiple LiteLLM replicas.

### Custom admin decision criteria

Do not build a custom admin portal/API unless LiteLLM Admin UI plus docs/workflows proves insufficient.

Only consider a custom admin product if there is clear evidence that v1 cannot handle:

- Key request/approval workflow.
- Company-specific policy acknowledgement.
- Developer onboarding dashboard.
- Sanitized developer-only spend views.
- Access review or approval audits.

Any future custom admin API must authenticate independently and must not trust forwarded identity headers alone.

### Deliverables

- Pilot review report.
- Hardening decision record.
- Updated risk register.
- Updated supported-tool matrix.
- Updated budget/alert configuration proposal.
- New roadmap phase proposals if deferred capabilities are approved.

### Exit criteria

- Pilot findings are documented.
- Deferred capabilities are explicitly accepted, rejected, or scheduled.
- Redis/multi-replica decision is documented.
- Custom admin decision is documented.
- Monitoring/observability decision is documented.
- Any new phase has a clear owner, scope, dependencies, and proof gates.

### Runbook/docs outputs

- `docs\decisions\post-pilot-hardening.md`
- `docs\operations\pilot-findings.md`
- `docs\operations\risk-register.md`

## 15. Global implementation gates

These gates apply across all phases:

- Never commit secrets.
- Never expose provider keys, LiteLLM master key, database URLs, Redis URLs, backup credentials, private Railway hostnames, stack traces, SQL, or operational internals to browser/client code.
- Never expose `litellm-proxy` publicly before LiteLLM virtual-key auth, admin controls, budgets, rate limits, metadata-only logging, and secret handling are configured.
- Never use public TCP proxy URLs for app-to-database traffic.
- Never use `/health` as Railway deployment healthcheck; use `/health/readiness`.
- Never enable raw prompt/response logging by default.
- Never add `sensitive-code` before explicit approval and provider readiness.
- Never add multiple LiteLLM replicas without Redis shared state.
- Never move from staging to production until staging proof gates pass.

## 16. First implementation order

Start implementation in this order:

1. Close Phase 0 decisions and proofs, especially LiteLLM-native public-origin risk acceptance and `/v1` auth/tool compatibility.
2. Create the scratch repo structure and CI secret/config gates.
3. Author LiteLLM config, aliases, denylist, and policy-as-code.
4. Provision durable Railway staging only.
5. Deploy LiteLLM with native auth and placeholder/low-cost provider config.
6. Configure public Railway/custom endpoint and prove missing/invalid LiteLLM keys are blocked.
7. Prove one real client can call `/v1/chat/completions` with LiteLLM auth, including streaming.
8. Configure LiteLLM Admin UI controls for admins/leads and prove developer keys cannot access admin/control routes.
9. Add backups, alerts, and restore drill.
10. Run full staging proof gates.
11. Only then create production variables and deploy production.
