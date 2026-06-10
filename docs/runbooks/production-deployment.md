# Production deployment runbook

**Status:** Draft. Do not run production mutations until Phase 7 and Phase 8 production blockers are closed or explicitly accepted through a production-grade risk exception.

This runbook covers production deployment of the Internal LLM Gateway, Open WebUI, and LibreChat in Railway. It intentionally avoids real secrets, generated keys, private hostnames, public hostnames, database URLs, and raw prompt/response data.

Production chat UI scope is recorded in `docs\decisions\production-chat-ui-scope.md`.

## Scope

Production will use:

- Existing Railway project `dev-orbit-llm-gateway`.
- Railway `production` environment.
- Asia/Singapore region: `asia-southeast1-eqsg3a`.
- Gateway core: LiteLLM Proxy, LiteLLM Postgres, backup-worker, LiteLLM Admin UI.
- Chat UI stack: Open WebUI and LibreChat with durable production data stores.

Staging runtime state must not be promoted. Production uses fresh resources, fresh sealed secrets, fresh virtual keys, production budgets, production backup policy, and production access controls.

Do not use Railway's full environment Sync for staging-to-production migration. Use `docs\runbooks\staging-to-production-promotion.md` for config/code promotion without copying staging secrets, domains, data stores, or UI content.

## Preconditions

1. `docs\operations\implementation-status.md` marks Phase 7 and Phase 8 exit criteria `Done`, or records an explicit production-grade risk exception.
2. Railway CLI/MCP access is available to the operator terminal.
3. The operator has approved each exact Railway mutation before it runs.
4. Production provider accounts, budgets, alert thresholds, and supported-tool list are approved.
5. Production UI data governance is approved for conversations, uploads, search indexes, embeddings, UI users, sessions, settings, and app state.
6. Production domain/DNS ownership is confirmed.
7. Production backup target, encryption, retention, restore owner, RPO, and RTO are approved.
8. Production rollback authority is assigned.

## Read-only preflight

Run only read-only checks first:

1. Confirm Railway authentication and workspace membership.
2. Confirm the project and `production` environment.
3. List staging and production services.
4. Confirm no production services already exist with conflicting names.
5. Inspect environment config for project-scoped shared variables.
6. Confirm target region is `asia-southeast1-eqsg3a`.
7. Confirm deployment source, Dockerfile paths, watch paths, healthcheck path, and current image pins.

Do not list or print resolved secrets. Do not paste private/public production hostnames into shared docs.

## Approval manifest

Record operator approval for each mutation category before execution:

| Mutation category | Approval required before action |
| --- | --- |
| Create production LiteLLM Postgres | Yes |
| Create/configure production `litellm-proxy` | Yes |
| Set production sealed variables | Yes |
| Deploy production `litellm-proxy` | Yes |
| Attach Railway/custom production domains | Yes |
| Create/configure production backup-worker | Yes |
| Create backup bucket/target credentials | Yes |
| Create production LiteLLM admin/lead/developer/UI keys | Yes |
| Create Open WebUI service and data store | Yes |
| Create LibreChat services and data stores | Yes |
| Attach UI public domains | Yes |
| Disable, delete, or migrate staging/evaluation resources | Yes |

## Deployment sequence

### 1. Confirm promotion artifact

1. Confirm the commit or artifact that passed staging validation.
2. Confirm the artifact contains only source-controlled config/code changes.
3. Confirm no production secret or data-store change is required, unless separately approved.

### 2. Provision gateway state

1. Create or confirm the production LiteLLM Postgres service.
2. Confirm it has no unintended public app ingress.
3. Confirm app-to-database traffic will use private/internal references only.
4. Do not use public TCP proxy URLs for app-to-database traffic.

### 3. Configure `litellm-proxy`

1. Configure source/build from committed artifacts.
2. Set Dockerfile path to `services/litellm/Dockerfile`.
3. Set healthcheck path to `/health/readiness`.
4. Set non-secret production variables.
5. Set sealed production secrets without printing values.
6. Confirm docs/ReDoc/OpenAPI are disabled or protected.
7. Confirm raw prompt/response logging is disabled.

The first deploy must happen only after `DATABASE_URL` is wired, because readiness checks database connectivity and initial migrations may need a longer timeout.

### 4. Deploy and validate `litellm-proxy`

1. Deploy `litellm-proxy`.
2. Validate `/health/readiness`.
3. Validate missing and invalid keys are rejected.
4. Validate a disposable production test key can call approved aliases.
5. Validate streaming.
6. Validate `/v1/models` exposes aliases only.
7. Validate developer keys cannot access admin/control routes.
8. Validate docs/ReDoc/OpenAPI surfaces are closed or protected.
9. Validate log sentinel checks do not reveal raw prompts/responses.
10. Block or delete disposable test keys after validation.

### 5. Attach production domains

Attach Railway/custom production domains only after gateway validation passes.

Before announcement:

1. Confirm DNS records target the intended production service.
2. Confirm certificate issuance is complete.
3. Confirm no stale staging DNS records point to production.
4. Confirm Admin UI is available only to approved admins/leads.
5. Confirm developer API traffic requires valid LiteLLM virtual-key auth.

### 6. Deploy backup-worker and production backups

1. Configure backup-worker from committed artifacts.
2. Set production backup target and encryption variables through sealed variables.
3. Run a one-off backup.
4. Run restore-check or equivalent validation.
5. Confirm backup-failure alerting reaches the approved owner.
6. Record non-secret backup evidence.

### 7. Deploy Open WebUI

1. Confirm production data policy covers Open WebUI users, settings, chats, uploads, indexes, and app state.
2. Create Open WebUI app service and durable data store/volume.
3. Use a pinned upstream image or approved wrapper covered by image policy.
4. Set app authentication enabled.
5. Disable public signup before developer access.
6. Disable direct provider connections and arbitrary endpoint/provider-key entry for non-admin users.
7. Set scoped LiteLLM UI keys only.
8. Expose only approved model aliases.
9. Route embeddings/RAG through LiteLLM if enabled.
10. Validate login, non-admin restrictions, model list, chat, streaming if applicable, and logs.

### 8. Deploy LibreChat

1. Confirm production data policy covers MongoDB, Meilisearch, pgvector, RAG data, uploads, users, sessions, conversations, and settings.
2. Create LibreChat app/API service, MongoDB, Meilisearch, pgvector, RAG API, and required volumes.
3. Use pinned images or approved wrappers covered by image policy.
4. Keep registration, social login, social registration, password reset, and unverified email login disabled unless separately approved.
5. Use scoped LiteLLM UI keys only.
6. Do not configure direct provider keys.
7. Expose only approved chat aliases to users.
8. Keep `dev-embed` for embeddings/RAG only.
9. Validate auth, non-admin restrictions, model list, chat, RAG/embedding route if enabled, and logs.

### 9. Production smoke and pilot gate

Run the production smoke set before developer onboarding:

- Readiness passes.
- Missing/invalid auth blocked.
- Valid key succeeds on approved routes.
- Streaming works.
- Admin/control routes denied for developer keys.
- Budgets, rate limits, revocation, and model restrictions work.
- Docs/ReDoc/OpenAPI are closed or protected.
- Logs do not reveal sentinel prompts/responses or secrets.
- Gateway backup succeeds.
- UI backups and restore paths are documented and tested.
- UI signup and non-admin restrictions are validated.

Only then create pilot developer keys and begin controlled onboarding.

## Evidence to record

Record only non-secret evidence:

- Service names and non-secret IDs if approved for docs.
- Deployment status and deployment IDs.
- Sanitized HTTP status codes.
- Alias names tested.
- Whether streaming chunks were observed.
- Backup artifact counts or timestamps without object URLs or credentials.
- Restore result summary.
- Pilot cohort size and non-secret usage summary.

Do not record secrets, hostnames, database URLs, virtual keys, raw prompts, raw responses, stack traces, SQL, or screenshots containing sensitive data.
