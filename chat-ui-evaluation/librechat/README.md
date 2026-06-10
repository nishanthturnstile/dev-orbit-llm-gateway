# LibreChat staging evaluation

LibreChat is the fuller ChatGPT-like UI candidate. It has more services and more content-bearing stores than Open WebUI.

## Runtime shape

```text
librechat-api-eval -> LiteLLM staging /v1 -> approved providers
```

Use a scoped LiteLLM virtual key for this UI. Do not use provider keys or the LiteLLM master/admin key.

## Required services

| Service | Required? | Purpose |
| --- | --- | --- |
| `librechat-api-eval` | Yes | LibreChat API and web UI. |
| `librechat-mongodb-eval` | Yes | Users, conversations, settings, sessions. |
| `librechat-meilisearch-eval` | Yes for search | Content-derived search index. |
| `librechat-vectordb-eval` | Yes for RAG/files | Embedding/vector data. |
| `librechat-rag-api-eval` | Yes for RAG/files | File/knowledge retrieval API. |

Do not use LiteLLM Postgres for any LibreChat state.

## Required controls

- Configure only the LiteLLM custom endpoint in `librechat.example.yaml`.
- Keep provider keys out of LibreChat.
- Keep `ALLOW_REGISTRATION=false` before tester access.
- Keep `ALLOW_SOCIAL_LOGIN=false` unless a separate SSO integration is approved.
- Keep `ALLOW_PASSWORD_RESET=false` unless email delivery is safely configured.
- Confirm non-admin testers cannot configure arbitrary endpoints or provider keys.
- Route embeddings through LiteLLM `dev-embed`; do not add direct embedding provider keys.
- Destroy MongoDB, Meilisearch, vector data, uploads, logs, and the UI key after the evaluation window.

## Image policy

Use pinned upstream images in Railway and record exact versions and digests before deployment. Do not add Dockerfiles under this folder unless the repository image policy is expanded to cover them.

## Validation

Before tester UAT:

1. API, MongoDB, Meilisearch, vector DB, and RAG API can reach each other over private networking.
2. LibreChat model traffic uses only the LiteLLM custom endpoint.
3. Model picker shows only allowed LiteLLM aliases.
4. Chat and streaming work through LiteLLM.
5. File/RAG/knowledge features use LiteLLM-approved model and embedding aliases.
6. Registration is disabled.
7. Logs do not expose prompts, responses, virtual keys, provider keys, stack traces, SQL, or private hostnames.
8. LiteLLM budget/rate limits work for the UI key.
