# Staging to production promotion runbook

**Status:** Draft. Do not use Railway environment Sync for this project unless a later Railway feature supports a reviewed, selective, non-secret/non-data promotion path.

This runbook defines how to promote gateway and chat UI changes from staging to production without copying staging secrets, variables, domains, databases, volumes, buckets, or application data.

## Decision

Do not click Railway's full environment Sync from `staging` to `production`.

The current Railway UI appears to sync the full environment. That is not safe for this project because staging contains evaluation services, staging secrets, staging virtual keys, staging public domains, low budgets, temporary backup configuration, and content-bearing UI data.

## What may be promoted

Promote only source-controlled, non-secret artifacts:

| Area | Source-controlled artifact |
| --- | --- |
| LiteLLM runtime | `services\litellm\Dockerfile`, `services\litellm\config.yaml`, `services\litellm\scripts\*` |
| LiteLLM policy | `config\litellm\model-aliases.yaml`, `config\litellm\provider-denylist.yaml`, `config\litellm\policy.md` |
| Backup worker | `services\backup-worker\Dockerfile`, `services\backup-worker\scripts\*` |
| LibreChat wrapper/config | `chat-ui-evaluation\librechat\Dockerfile`, `chat-ui-evaluation\librechat\librechat.yaml` |
| Open WebUI / image services | Approved pinned image reference and non-secret service settings documented in `config\railway` |
| Validation | `scripts\*`, `tests\smoke\*`, and runbooks |

## What must never be promoted from staging

- Railway variables and sealed variables.
- Provider keys.
- LiteLLM master/admin keys.
- Generated LiteLLM virtual keys.
- Database URLs and credentials.
- Backup credentials or encryption keys.
- Public Railway domains or custom domains.
- Databases, volumes, buckets, or stored data.
- Open WebUI users, chats, uploads, indexes, embeddings, local app state, or logs.
- LibreChat MongoDB, Meilisearch, pgvector, RAG data, uploads, users, sessions, conversations, settings, or logs.
- Cron schedules unless production backup policy and alerting are approved.

## Promotion workflow

1. Make the change in the repository.
2. Run local validation:
   - secret scan,
   - LiteLLM config lint,
   - relevant tests.
3. Deploy the committed artifact to staging.
4. Run staging smoke tests and UI checks.
5. Record the known-good commit SHA or deployment artifact.
6. Apply the same committed artifact to the production service.
7. Keep production variables and data stores unchanged unless the change explicitly requires an approved production variable/data migration.
8. Run production smoke tests.
9. Announce availability only after production validation passes.

## Initial production provisioning

For the first production rollout, create fresh production resources manually:

1. Production LiteLLM Postgres.
2. Production `litellm-proxy`.
3. Production backup-worker and backup target.
4. Production Open WebUI service and durable data store.
5. Production LibreChat services and durable data stores.
6. Production scoped LiteLLM virtual keys.
7. Production domains only after validation.

Each Railway mutation still requires explicit operator approval for the exact action.

## Future config changes

Use the same pattern for future changes:

- Config/code changes move by Git commit and deployment artifact.
- Environment-specific values stay in Railway production variables.
- Data stays in production data stores.
- Secrets are set or rotated only through the approved production secret process.

This gives production parity with staging configuration without copying staging state.
