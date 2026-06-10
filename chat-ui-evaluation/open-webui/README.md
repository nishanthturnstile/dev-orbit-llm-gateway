# Open WebUI staging evaluation

Open WebUI is the first UI candidate because it can run as a single app service and connect to the LiteLLM OpenAI-compatible `/v1` endpoint.

## Runtime shape

```text
open-webui-eval -> LiteLLM staging /v1 -> approved providers
```

Use a scoped LiteLLM virtual key for this UI. Do not use provider keys or the LiteLLM master/admin key.

## Required storage

Open WebUI stores user accounts, settings, chat history, uploads, and local application data. For staging evaluation, use one of:

1. Railway volume mounted at `/app/backend/data`.
2. Separate Open WebUI database referenced through `DATABASE_URL`.

Do not use LiteLLM Postgres.

## Required controls

- `WEBUI_AUTH=True`.
- Create the operator/admin account first.
- Set `ENABLE_SIGNUP=False` before tester access.
- Keep testers as non-admin users.
- Confirm non-admins cannot add arbitrary OpenAI-compatible endpoints or provider keys.
- Keep all advanced features disabled unless they route through LiteLLM or have separate approval.
- Destroy the Open WebUI data store after the evaluation window.

## Image

Use a pinned upstream image in Railway, for example:

```text
ghcr.io/open-webui/open-webui:<pinned-version>@sha256:<digest>
```

Do not deploy a floating tag for shared staging evaluation.

## Validation

Before tester UAT:

1. The service boots and responds.
2. WebSocket streaming works through Railway.
3. Signup is disabled.
4. Non-admin users cannot add arbitrary connections.
5. Model picker shows only LiteLLM aliases allowed by the UI key.
6. Chat and streaming route through LiteLLM.
7. File/knowledge features route model and embedding calls through LiteLLM.
8. Logs do not expose prompts, responses, virtual keys, provider keys, stack traces, SQL, or private hostnames.
9. LiteLLM budget/rate limits work for the UI key.
