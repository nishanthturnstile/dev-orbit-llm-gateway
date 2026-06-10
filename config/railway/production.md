# Railway production notes

Production deployment is planned but not started. Production remains blocked until the Phase 7 backup/restore/alert gates and Phase 8 staging proof/client-compatibility gates are complete or explicitly accepted by a production-grade risk exception.

No production secrets, resolved Railway variables, provider keys, database URLs, generated virtual keys, backup credentials, private hostnames, public service domains, raw prompts, or raw responses belong in this file.

## Selected production scope

| Item | Decision |
| --- | --- |
| Railway project model | Use the existing Railway project `dev-orbit-llm-gateway` and its `production` environment. |
| Region | Use Asia/Singapore, matching staging: `asia-southeast1-eqsg3a`. |
| Gateway core | Production LiteLLM Proxy, LiteLLM Postgres, backup-worker, LiteLLM Admin UI, and per-developer virtual keys. |
| Production chat UIs | Productionize both Open WebUI and LibreChat. |
| UI data posture | Treat Open WebUI and LibreChat stores as durable production data covered by retention, access control, backup, restore, RPO/RTO, and rollback planning. |
| Staging state | Do not promote staging virtual keys, UI accounts, UI data stores, backup credentials, or evaluation data into production. |
| Railway Sync | Do not use full Railway environment Sync from staging to production. Promote source-controlled config/code and keep secrets/data environment-local. |

## Production resource plan

### Gateway core

| Resource | Type | Notes |
| --- | --- | --- |
| `Postgres` or final approved LiteLLM Postgres service name | Railway managed Postgres | Stores LiteLLM users, teams, keys, budgets, spend, and metadata. Use private/internal references only. |
| `litellm-proxy` | App service | Build from committed pinned artifacts. Healthcheck path must be `/health/readiness`. |
| `backup-worker` | Scheduled app service | Runs production backup jobs after backup target, encryption, retention, and restore policy are approved. |

### Chat UI production stack

| Resource | Type | Notes |
| --- | --- | --- |
| `open-webui` final production service name | App service | Uses scoped LiteLLM UI keys only; no direct provider keys or LiteLLM master/admin keys. |
| Open WebUI data store or volume | Volume or database | Durable production UI data. Covered by retention, backup, restore, and deletion policy. |
| `librechat-api` final production service name | App service | Uses scoped LiteLLM UI key only; registration disabled before developer access. |
| LibreChat MongoDB | Database service | Durable users, sessions, conversations, and settings. |
| LibreChat Meilisearch | Search service | Durable content-derived search indexes. |
| LibreChat pgvector | Vector database service | Durable embeddings and content-derived vectors. |
| LibreChat RAG API | App service | Routes embeddings through LiteLLM `dev-embed`; no direct provider key. |
| LibreChat upload/runtime volumes | Volumes | Durable or retained according to the approved UI data policy. |

## Variable and secret handling

- Use fresh production values for all sealed secrets.
- Do not duplicate staging variables blindly.
- Do not copy staging variables through Railway Sync.
- Do not rely on project-scoped shared variables unless each shared value is reviewed for production.
- Set secrets through Railway sealed variables, stdin, or the approved operator secret store.
- Keep tracked files placeholder-only.

Required production secret categories:

- LiteLLM master key and salt key.
- LiteLLM Admin UI credentials or SSO settings.
- Approved production provider keys.
- Production backup encryption and object-store credentials.
- Open WebUI application secret and scoped LiteLLM UI keys.
- LibreChat application secrets, database credentials, RAG secrets, and scoped LiteLLM UI keys.

## Domain and access guardrails

- Do not attach or announce production custom domains until auth, admin controls, budgets, rate limits, metadata-only logging, and secret handling are validated.
- Confirm public developer traffic requires valid LiteLLM virtual-key authentication.
- Confirm developer keys cannot access LiteLLM admin/control routes.
- Disable or protect docs, ReDoc, OpenAPI, and Swagger surfaces.
- Disable public signup in Open WebUI and LibreChat before developer access.
- Use admin-created accounts for production chat UI access.

## Production blockers

- Phase 7 production blockers: native backup evidence, fresh restore drill, restored database auth validation, RPO/RTO measurement, and backup-failure push alerting.
- Phase 8 production blockers: full staging smoke evidence, named developer-tool validation, blocked-tool exclusions, and production readiness review.
- UI production blockers: production decision record, data-retention/access policy, backup/restore policy for UI stores, cost owner, admin owner, and updated service-boundary documentation.

## Required runbooks and docs

- `docs\runbooks\production-deployment.md`
- `docs\runbooks\staging-to-production-promotion.md`
- `docs\runbooks\rollback.md`
- `docs\onboarding\production-usage-rules.md`
- `docs\operations\pilot-review.md` after pilot starts
- Updated `docs\operations\implementation-status.md`
