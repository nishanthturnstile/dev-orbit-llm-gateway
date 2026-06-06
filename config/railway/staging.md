# Railway staging configuration

Phase 4 created durable Railway staging infrastructure for the Internal LLM Gateway. This file records only non-secret names, IDs, service boundaries, and variable-reference shapes.

Do not store resolved Railway variables, database URLs, provider keys, LiteLLM keys, generated virtual keys, Cloudflare tunnel tokens, backup credentials, private hostnames, or public service domains in this file.

## Project and environment

| Item | Value |
| --- | --- |
| Workspace | `muthurema's Projects` |
| Durable project | `dev-orbit-llm-gateway` |
| Project ID | `0b1bc0ec-4ace-47c3-bd13-214256c27ad5` |
| Default production environment ID | `75066b79-f287-434f-958d-346179d568a2` |
| Staging environment | `staging` |
| Staging environment ID | `f188f687-8582-4308-9110-1d082dc31b89` |
| Region | `asia-southeast1-eqsg3a` |
| Spend guardrail | Use Railway default limits and monitor staging spend during Phase 4+ validation. |

The default `production` environment exists because Railway creates it automatically. It is intentionally unused until the production rollout phases.

## Services

| Service | Railway service ID | Status | Source attached | Public URL |
| --- | --- | --- | --- | --- |
| `Postgres` | `1494db55-53c1-4ff1-bbe0-312340190eb7` | Managed Postgres deployment `9187450c-4db4-4c43-bb79-5f1bc3611ffc` is `SUCCESS`; one replica running; volume `postgres-volume` is ready. | Railway managed image | None recorded |
| `litellm-proxy` | `335b0f28-2d4c-42b7-b3c9-063bcf296a25` | Deployment `dceac0a0-a478-4bc4-991d-45b124f56358` is `SUCCESS`; Phase 5 runtime policy validation is blocked only on `dev-search` provider authentication. | Local upload; no GitHub source attachment | None |
| `backup-worker` | `f1e6e49c-8320-4b30-a070-d59d285f520c` | Sourceless shell only; no deployment. | No | None |
| `cloudflared-tunnel` | `ec0b7723-219f-4f54-8896-3ed010ed1e3d` | Sourceless shell only; no deployment. | No | None |

The approved planning name for Postgres was `litellm-postgres`, but Railway's managed Postgres template created the service as `Postgres`. Because Railway variable references are service-name and case sensitive, Phase 4 uses the actual service name in references.

## Safe staging variables

Only non-secret values and Railway service-reference placeholders were set in Phase 4. Variable changes used `--skip-deploys`.

### `litellm-proxy`

| Variable | Shape |
| --- | --- |
| `ENVIRONMENT` | `staging` |
| `PORT` | `4000` |
| `NO_DOCS` | `True` |
| `NO_REDOC` | `True` |
| `NO_OPENAPI` | `True` |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `DISABLE_ADMIN_UI` | `true` in Phase 5 |
| `LITELLM_MASTER_KEY` | Required sealed value; must start with `sk-`; pending operator setup |
| `LITELLM_SALT_KEY` | Required sealed value; pending operator setup before first deploy while `store_model_in_db: true` |
| `OPENAI_API_KEY` | Required sealed approved staging key |
| `PERPLEXITY_API_KEY` | Required sealed approved staging key for `dev-search`; current staged value fails provider validation |

Railway readback confirms `DISABLE_ADMIN_UI`, `NO_DOCS`, `NO_REDOC`, `NO_OPENAPI`, `PORT`, and `DATABASE_URL` are present on `litellm-proxy`. Sealed `LITELLM_MASTER_KEY`, `LITELLM_SALT_KEY`, `OPENAI_API_KEY`, and `PERPLEXITY_API_KEY` are present. The staged Perplexity key currently fails provider validation and must be replaced before Phase 5 can close.

### `litellm-proxy` service config

Phase 5 configured and read back:

| Setting | Value |
| --- | --- |
| Builder | `DOCKERFILE` |
| Dockerfile path | `services/litellm/Dockerfile` |
| Healthcheck path | `/health/readiness` |
| Healthcheck timeout | `300` |
| Public URL/domain | None |

The LiteLLM Admin UI is disabled with `DISABLE_ADMIN_UI=true` and a container startup guard that returns 404 for `/ui`, `/ui/*`, and the UI asset prefix. This guard is required because the pinned LiteLLM image still served the UI shell when only the documented environment flag was present.

## Phase 5 runtime validation readback

| Check | Status |
| --- | --- |
| Deployment status | `SUCCESS`; one running replica |
| Public URL/domain | None |
| Readiness | Healthy; DB connected |
| Missing/invalid auth | Rejected |
| Disposable key generation/blocking | Passed |
| Developer key admin route denial | Passed |
| Forbidden alias denial | Passed |
| `/ui`, `/docs`, `/redoc`, `/openapi.json` | Disabled/protected |
| Recent log secret/private-host/traceback scan | Zero matches after log-redaction wrapper deployment |
| OpenAI-backed chat/stream/embedding | Passed |
| OpenAI-backed aliases | `dev-fast`, `dev-code`, `dev-reasoning`, `dev-long-context`, `batch-analysis`, `dev-vision`, and `dev-embed` passed |
| Key metadata persistence and RPM enforcement | Passed |
| `dev-search` | Blocked: staged `PERPLEXITY_API_KEY` returns provider `401` |

### `backup-worker`

| Variable | Shape |
| --- | --- |
| `ENVIRONMENT` | `staging` |
| `LITELLM_DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |

### `cloudflared-tunnel`

No user-provided variables were set in Phase 4.

## Variables intentionally not set

The following are intentionally deferred until their roadmap phase:

- `TUNNEL_TOKEN`
- Backup object storage credentials
- Backup encryption key
- Generated LiteLLM developer virtual keys
- Production credentials of any kind

## Future source/deploy matrix

Do not attach source until Phase 5+ explicitly approves runtime deployment and secrets.

| Service | Future build context | Future Dockerfile path | Future watch paths | Notes |
| --- | --- | --- | --- | --- |
| `litellm-proxy` | Repository root | `services/litellm/Dockerfile` | `services/litellm/**`, `config/litellm/**`, `scripts/validate-litellm-config.py` | Healthcheck path configured as `/health/readiness`; container port remains `4000`. |
| `backup-worker` | Repository root | `services/backup-worker/Dockerfile` | `services/backup-worker/**` | Do not deploy until backup storage, encryption, schedule, and restore-check policy are approved. |
| `cloudflared-tunnel` | Repository root | `services/cloudflared-tunnel/Dockerfile` | `services/cloudflared-tunnel/**`, `config/cloudflare/**` | Do not deploy until Cloudflare tunnel/access hardening is approved and `TUNNEL_TOKEN` is provided as a sealed Railway variable. |

Current Dockerfiles use repository-root-relative `COPY` paths. Keep Railway build context at the repository root when source is attached; do not set a service root directory to a service subfolder unless the Dockerfiles are changed first.

## Phase 4 validation notes

Readback checks confirmed:

- The durable project is separate from disposable Phase 0 project `internal-llm-gateway-phase0`.
- `staging` is linked and persistent.
- App services are sourceless, undeployed, and have no public URLs.
- `Postgres` is healthy and has no public URL recorded by `railway service list`.
- App service variables use `${{Postgres.DATABASE_URL}}` reference shapes, not resolved values.
- No provider keys, LiteLLM master key, Cloudflare token, backup credentials, or generated virtual keys were set.

Phase 4 validates private-network topology and variable-reference wiring only. Live app-to-Postgres connectivity proof is deferred to Phase 5 after source attachment, runtime secrets, LiteLLM policy, and deployment controls are configured.
