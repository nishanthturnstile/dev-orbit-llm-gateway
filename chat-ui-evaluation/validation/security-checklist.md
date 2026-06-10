# Chat UI security validation checklist

Run this checklist before any internal tester receives access to Open WebUI or LibreChat.

## Static repository checks

- Tracked files contain placeholders only.
- No provider keys, LiteLLM keys, generated virtual keys, database URLs, private hostnames, public Railway hostnames, raw prompts/responses, stack traces, SQL, backup credentials, or UI secrets are committed.
- No Dockerfiles exist under `chat-ui-evaluation` unless the image policy gate is updated to enforce digest pinning for this folder.
- `chat-ui-evaluation\librechat\librechat.example.yaml` parses as YAML.

Suggested local checks:

```powershell
pwsh -NoProfile -File scripts\check-secrets.ps1
python -c "import yaml, pathlib; yaml.safe_load(pathlib.Path('chat-ui-evaluation/librechat/librechat.example.yaml').read_text())"
```

## Gateway checks

- Each UI uses a scoped LiteLLM virtual key, not `LITELLM_MASTER_KEY`.
- UI keys have explicit model allowlists.
- UI keys have low staging budgets, RPM/TPM limits, and max parallel request limits.
- UI keys are denied on LiteLLM admin/control routes.
- UI model lists expose aliases only.

## UI access checks

- App authentication is enabled.
- Initial operator/admin account is created.
- Public self-signup is disabled before tester access.
- Testers are non-admin users.
- Non-admin testers cannot add arbitrary OpenAI-compatible endpoints.
- Non-admin testers cannot paste direct provider keys.

## Advanced feature checks

- File uploads, RAG, knowledge, web search, code execution, tools, connectors, and plugins are individually reviewed.
- Any feature requiring direct provider keys, search-provider keys, execution secrets, external connectors, or unreviewed plugins remains disabled until separately approved.
- Embeddings route through LiteLLM `dev-embed`.
- No direct embedding provider key is configured in either UI.

## Logging and data checks

- Logs do not expose raw prompts, raw responses, provider keys, LiteLLM keys, private hostnames, stack traces, SQL, or database URLs.
- Content stores are inventoried:
  - Open WebUI volume/database.
  - LibreChat MongoDB.
  - LibreChat Meilisearch.
  - LibreChat vector DB.
  - LibreChat uploads/logs.
- Teardown owner and date are recorded before tester access.
