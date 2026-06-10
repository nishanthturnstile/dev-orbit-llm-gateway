# Chat UI teardown checklist

Use this checklist after the staging evaluation window or immediately if a staging UI is exposed incorrectly.

This checklist applies to staging evaluation resources only. Production Open WebUI or LibreChat resources, if created, are durable production systems governed by `docs\decisions\production-chat-ui-scope.md`, `docs\runbooks\rollback.md`, and the approved production retention/backup policy. Do not delete production UI data stores with this checklist.

## LiteLLM cleanup

- Revoke or block `open-webui-eval` LiteLLM virtual key.
- Revoke or block `librechat-eval` LiteLLM virtual key.
- Verify both keys fail on `/v1/chat/completions`.
- Record only key cleanup status, never key values.

## Open WebUI cleanup

- Disable public access to `open-webui-eval`.
- Delete or detach the Open WebUI volume or separate UI database.
- Delete uploads, chats, local app state, and non-required logs.
- Confirm no provider keys or LiteLLM master/admin keys were ever configured.

## LibreChat cleanup

- Disable public access to `librechat-api-eval`.
- Delete LibreChat MongoDB data.
- Delete Meilisearch indexes/data.
- Delete vector DB data.
- Delete RAG API uploads/cache/data.
- Delete non-required logs.
- Confirm no provider keys or LiteLLM master/admin keys were ever configured.

## Railway cleanup

- Delete evaluation-only services after approval:
  - `open-webui-eval`
  - `librechat-api-eval`
  - `librechat-mongodb-eval`
  - `librechat-meilisearch-eval`
  - `librechat-vectordb-eval`
  - `librechat-rag-api-eval`
- Delete evaluation-only volumes/databases.
- Remove evaluation-only public domains.
- Record non-secret teardown evidence.

## Final evidence

| Item | Status | Evidence |
| --- | --- | --- |
| LiteLLM UI keys revoked | `<status>` | `<non-secret evidence>` |
| Open WebUI data destroyed | `<status>` | `<non-secret evidence>` |
| LibreChat data destroyed | `<status>` | `<non-secret evidence>` |
| Public domains removed | `<status>` | `<non-secret evidence>` |
| Services removed or disabled | `<status>` | `<non-secret evidence>` |
