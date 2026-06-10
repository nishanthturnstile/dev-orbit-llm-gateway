# Production chat UI scope

**Status:** Approved for production planning; Railway mutations remain blocked until exact operator approval per action  
**Related config:** `config\railway\production.md`  
**Related runbooks:** `docs\runbooks\production-deployment.md`, `docs\runbooks\rollback.md`  
**Related evaluation docs:** `chat-ui-evaluation\README.md`

## Decision

Production scope includes both Open WebUI and LibreChat as developer-facing UI add-ons connected to the production LiteLLM gateway.

These services are not a replacement for LiteLLM Proxy, LiteLLM Admin UI, or LiteLLM's policy source of truth. LiteLLM remains authoritative for provider routing, model aliases, virtual keys, teams, budgets, spend, rate limits, and admin operations.

## Production boundaries

- Use fresh production Railway services and data stores.
- Do not promote staging UI services, accounts, volumes, databases, virtual keys, or evaluation data.
- Use scoped LiteLLM virtual keys per UI service/function.
- Do not configure direct provider keys in Open WebUI or LibreChat.
- Do not configure LiteLLM master/admin keys in Open WebUI or LibreChat.
- Do not reuse LiteLLM Postgres for UI state.
- Disable public signup before developer access.
- Prevent non-admin users from adding arbitrary model endpoints or direct provider keys.
- Keep advanced features disabled until each integration is separately approved.

## Data posture

Open WebUI and LibreChat production stores are durable production data. They may contain:

- Conversations.
- Uploads and files.
- Search indexes.
- Embeddings and vector data.
- RAG service data.
- Users, sessions, settings, and app state.
- Operational logs and metadata.

These stores must be covered by production retention, access-control, backup, restore, RPO/RTO, and rollback planning before broad developer access.

## Required production stores

| Surface | Store | Production posture |
| --- | --- | --- |
| Open WebUI | Volume or database for users, chats, settings, uploads, and app state | Durable; include in backup/restore and retention policy. |
| LibreChat | MongoDB for users, sessions, conversations, and settings | Durable; include in backup/restore and retention policy. |
| LibreChat | Meilisearch for content-derived search indexes | Durable; include in backup/restore or approved rebuild policy. |
| LibreChat | pgvector for embeddings and content-derived vectors | Durable; include in backup/restore or approved rebuild policy. |
| LibreChat | RAG/uploads/runtime data | Durable unless explicitly classified as rebuildable; include in retention/deletion policy. |

## Non-decisions

- This does not approve Railway service creation, deployment, domain creation, variable changes, database creation, volume creation, or deletion.
- This does not approve direct provider keys in browser/UI services.
- This does not approve custom admin API/web development.
- This does not approve Redis or multiple LiteLLM replicas.
- This does not approve Cloudflare Tunnel/Access/WAF or edge-origin hardening.

## Production blockers

- Phase 7 backup/restore/alert blockers remain production blockers.
- Phase 8 staging proof/client compatibility blockers remain production blockers.
- UI backup/restore and retention details must be documented before broad developer access.
- Exact operator approval is still required before every Railway mutation.
