# Railway service map for chat UI evaluation

**Status:** Approved and deployed in the existing Railway `staging` environment for UI evaluation. Future resource mutations still require explicit operator approval for the exact action.

All services must live in the existing staging environment as separate services/resources. They must not be merged into `litellm-proxy`, `backup-worker`, or LiteLLM Postgres.

## Shared gateway prerequisites

| Item | Requirement |
| --- | --- |
| LiteLLM endpoint | Use the approved staging public endpoint with `/v1`; keep literal hostnames out of tracked docs. |
| Open WebUI keys | Create separate scoped, budgeted LiteLLM virtual keys for `open-webui-eval-chat` and `open-webui-eval-rag`. |
| LibreChat key | Create a scoped, budgeted LiteLLM virtual key named for `librechat-eval`. |
| Allowed aliases | Start with `dev-fast`, `dev-code`, `dev-long-horizon`, and `dev-reasoning`; add `dev-search` or `dev-embed` only when the UI feature needs them. |
| Admin routes | UI keys must not access LiteLLM admin/control routes. |
| Budgets | Use low staging budgets, RPM/TPM limits, and max parallel request limits. |

## Open WebUI resources

| Resource | Type | Purpose |
| --- | --- | --- |
| `open-webui-eval` | App service from pinned upstream image | Open WebUI app and API. |
| `open-webui-data` | Railway volume or separate UI database | Open WebUI users, settings, chats, uploads, and local SQLite state if a database is not used. |

Image policy:

```text
ghcr.io/open-webui/open-webui:<pinned-version>@sha256:<digest>
```

Do not use `:main` for a shared staging evaluation.

Current implementation candidate:

```text
ghcr.io/open-webui/open-webui:v0.9.6@sha256:90eae5b419e40b4c3dd684582b2c83440b36f9ae2f6532c09639b2ba4ee65158
```

Required controls:

- Attach a Railway volume at `/app/backend/data`.
- Set `WEBUI_AUTH=True`, `ENABLE_LOGIN_FORM=True`, `DEFAULT_USER_ROLE=user`, `ENABLE_DIRECT_CONNECTIONS=False`, and `ENABLE_OLLAMA_API=False`.
- Set `ENABLE_EVALUATION_ARENA_MODELS=False`, `ENABLE_MODEL_FILTER=True`, and `MODEL_FILTER_LIST=dev-fast;dev-code;dev-long-horizon;dev-reasoning` so chat selection exposes only approved LiteLLM chat aliases.
- Use separate LiteLLM keys: `OPENAI_API_KEY` allows only chat aliases, while `RAG_OPENAI_API_KEY` allows only `dev-embed`.
- Route Open WebUI knowledge/RAG embeddings through LiteLLM with `RAG_EMBEDDING_ENGINE=openai`, `RAG_OPENAI_API_BASE_URL`, `RAG_OPENAI_API_KEY`, and `RAG_EMBEDDING_MODEL=dev-embed`.
- Use a stable sealed `WEBUI_SECRET_KEY`.
- Keep `ENABLE_SIGNUP=False` before tester access. If the first admin must be created through the UI, use a short operator-only setup window, then disable signup and redeploy before tester accounts are added.

## LibreChat resources

| Resource | Type | Purpose |
| --- | --- | --- |
| `librechat-api-eval` | App service from pinned upstream image | LibreChat API and web UI. |
| `librechat-mongodb-eval` | MongoDB service | LibreChat users, conversations, settings, and app state. |
| `librechat-meilisearch-eval` | Meilisearch service | Search index; may contain content-derived data. |
| `librechat-vectordb-eval` | pgvector service | Vector store for approved RAG/file features. |
| `librechat-rag-api-eval` | App service from pinned upstream image | LibreChat RAG API for approved file/knowledge features. |

Image policy examples:

```text
registry.librechat.ai/danny-avila/librechat-dev:<pinned-version>@sha256:<digest>
registry.librechat.ai/danny-avila/librechat-rag-api-dev-lite:<pinned-version>@sha256:<digest>
mongo:<pinned-version>@sha256:<digest>
getmeili/meilisearch:<pinned-version>@sha256:<digest>
pgvector/pgvector:<pinned-version>@sha256:<digest>
```

The exact versions and digests must be selected and recorded before deployment.

Current implementation candidates:

```text
registry.librechat.ai/danny-avila/librechat-dev@sha256:8cc2d5e83848636c1d985ffcc910dd257b450ce2f2a50bd2e443a6d87a11f2ec
registry.librechat.ai/danny-avila/librechat-rag-api-dev-lite:latest@sha256:6dfb6832661ff9c26fa329c823ce266059e33567670a763e9ecb9b566b8daa68
mongo:8.0.20@sha256:098862b1339f031900ca66cf8fef799e616d6324fa41b9a263f2ec899552c1ef
getmeili/meilisearch:v1.35.1@sha256:8b57fc3c7f46535ddef3828df1538465ac19d892eb57c9a10da6df0880bd5856
pgvector/pgvector:0.8.0-pg15-trixie@sha256:8809cfffff0082cf260c9ac752f1dd1afc77f6f0a55c4e6411321e78efc3d9a5
```

LibreChat API uses a tiny wrapper Dockerfile in `chat-ui-evaluation\librechat` so the tracked `librechat.yaml` is present at runtime. The config contains only environment-variable references for the LiteLLM endpoint and UI-scoped key.

The LibreChat upstream registry did not expose the GitHub release tag for the app/RAG images during planning, so those references are pinned by immutable digest. Re-resolve and re-record the digest before any later deploy attempt.

Required controls:

- Set `ENDPOINTS=custom` and do not set direct provider keys.
- Keep `dev-embed` out of the chat model picker; use it only for embeddings/RAG.
- Set `ALLOW_REGISTRATION=false`, `ALLOW_SOCIAL_LOGIN=false`, `ALLOW_SOCIAL_REGISTRATION=false`, `ALLOW_PASSWORD_RESET=false`, and `ALLOW_UNVERIFIED_EMAIL_LOGIN=false` before tester access.
- Use authenticated MongoDB with `authSource=admin`; start MongoDB with `mongod --bind_ip_all`.
- Set shared secrets independently on each Railway service that needs them. Do not rely on cross-service references for sealed values.
- Use Railway variable references only for non-secret private hostnames, such as `RAILWAY_PRIVATE_DOMAIN`.
- Bind private services for Railway private networking, including Meilisearch `MEILI_HTTP_ADDR=[::]:7700`.
- Disable verbose LibreChat logs with `DEBUG_LOGGING=false` and `DEBUG_CONSOLE=false`.
- Route RAG embeddings through LiteLLM with `RAG_OPENAI_BASEURL`, `RAG_OPENAI_API_KEY`, `EMBEDDINGS_PROVIDER=openai`, and `EMBEDDINGS_MODEL=dev-embed`.

## Data-store isolation

| Store | Contains | Teardown requirement |
| --- | --- | --- |
| Open WebUI volume/database | Users, chats, settings, uploads, local app state | Delete after evaluation window. |
| LibreChat MongoDB | Users, sessions, conversations, settings | Delete after evaluation window. |
| LibreChat Meilisearch | Search indexes derived from content | Delete after evaluation window. |
| LibreChat vector DB | Embeddings and content-derived vectors | Delete after evaluation window. |
| LibreChat uploads/logs | Uploaded files and operational logs | Delete non-required data after evaluation window. |

None of these stores may use LiteLLM Postgres.

## Required pre-deploy approvals

1. Exact service/resource list.
2. Image versions and digests.
3. UI public domain creation.
4. LiteLLM virtual-key creation.
5. UI database/volume creation.
6. Advanced feature integrations.
7. Teardown owner and date.

## Approval manifest for staging deployment

This manifest was approved by the operator for the staging evaluation deployment.

| Step | Mutation |
| --- | --- |
| 1 | Create `open-webui-eval` from the pinned Open WebUI image. |
| 2 | Attach `open-webui-eval` volume at `/app/backend/data`. |
| 3 | Generate scoped LiteLLM virtual key aliases `open-webui-eval-chat` and `open-webui-eval-rag` with approved chat/RAG aliases and low staging budget/rate limits. |
| 4 | Set Open WebUI non-secret variables and sealed secrets without printing raw values. |
| 5 | Create a Railway public domain for `open-webui-eval` on port `8080`. |
| 6 | Create `librechat-mongodb-eval`, `librechat-meilisearch-eval`, `librechat-vectordb-eval`, `librechat-rag-api-eval`, and `librechat-api-eval`. |
| 7 | Attach LibreChat volumes for MongoDB, Meilisearch, pgvector, uploads, and any required app runtime data. |
| 8 | Generate a scoped LiteLLM virtual key alias `librechat-eval` with only approved chat aliases plus `dev-embed` for RAG. |
| 9 | Set LibreChat stack variables and sealed secrets without printing raw values. |
| 10 | Deploy `librechat-api-eval` from `chat-ui-evaluation\librechat` with `railway up`. |
| 11 | Create a Railway public domain for `librechat-api-eval` on port `3080`. |
| 12 | Validate auth, model restrictions, streaming, RAG embedding route, logs, and budget/rate limits before tester access. |

## Deployment evidence

| Check | Status | Evidence |
| --- | --- | --- |
| Open WebUI service | Done | Root page and `/health` returned HTTP 200 after deployment. |
| Open WebUI access controls | Done | Bootstrap admin login returned HTTP 200; signup is disabled; direct connections, Ollama, and evaluation arena models are disabled. |
| Open WebUI model restrictions | Needs update | Previous staging validation exposed `dev-fast`, `dev-code`, `dev-reasoning`, and `dev-long-context`; the local allowlist is updated to `dev-long-horizon` and requires fresh staging validation. |
| Open WebUI LiteLLM chat path | Done | Authenticated UI chat completion through `dev-fast` returned HTTP 200. |
| LibreChat services | Done | MongoDB, Meilisearch, pgvector, RAG API, and LibreChat API are running in staging. |
| LibreChat Mongo authentication | Done | Initial Mongo auth failure was repaired by creating the admin user from sealed Mongo service variables; LibreChat now connects to MongoDB successfully. |
| LibreChat access controls | Done | Bootstrap admin account was created, then `ALLOW_REGISTRATION=false` was applied; email login remains enabled, social login and password reset remain disabled. |
| LibreChat model restrictions | Needs update | Previous staging validation exposed `dev-fast`, `dev-code`, `dev-reasoning`, and `dev-long-context`; the local allowlist is updated to `dev-long-horizon` and requires fresh staging validation. |
| LibreChat LiteLLM chat path | Done | Authenticated chat through `/api/agents/chat/custom` with `dev-fast` returned HTTP 200. |
