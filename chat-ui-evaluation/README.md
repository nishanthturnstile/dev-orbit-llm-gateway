# Chat UI evaluation

**Status:** Staging evaluation support for deployed Open WebUI and LibreChat services. This folder is not part of the LiteLLM gateway runtime or v1 gateway control plane. Future Railway mutations still require explicit operator approval for the exact action.

This folder contains placeholder-only configuration and operational checklists for evaluating Open WebUI and LibreChat as separate UI services connected to the existing LiteLLM staging gateway.

```text
Open WebUI eval service -> LiteLLM staging /v1 -> approved providers
LibreChat eval stack    -> LiteLLM staging /v1 -> approved providers
LiteLLM Admin UI        -> gateway administration only
LiteLLM Postgres        -> LiteLLM state only
UI data stores          -> UI state/content only; never share LiteLLM Postgres
```

## Decisions

1. Use admin-created accounts with signup disabled for staging evaluation.
2. Use scoped LiteLLM virtual keys per UI app for staging; Open WebUI uses separate chat and RAG keys.
3. Include advanced features only when they can be configured safely.
4. Disable any feature that requires direct provider keys, search-provider keys, execution secrets, external connectors, or unreviewed plugins until that exact integration is separately approved.
5. Destroy all UI evaluation data after the test window, including chats, uploads, indexes, vector data, service volumes/databases, and non-required logs.

## Staging login access

Do not commit bootstrap passwords or environment-specific Railway hostnames to repository docs. The exact login URLs and passwords are stored only in the operator-local session artifact listed below and must be shared through the approved secure handoff channel.

| UI | Login URL source | Default email ID | Password source |
| --- | --- | --- | --- |
| Open WebUI | Railway public domain for `open-webui-eval`; exact URL in the operator-local artifact | `open-webui-admin@thaarei.local` | Operator-local artifact: `C:\Users\v-mnmurugan\.copilot\session-state\8c26dbb0-ee1e-4722-9ade-b2ee4eb81822\files\chat-ui-evaluation-login-handoff.txt` |
| LibreChat | Railway public domain for `librechat-api-eval`; exact URL in the operator-local artifact | `librechat-admin@thaarei.local` | Operator-local artifact: `C:\Users\v-mnmurugan\.copilot\session-state\8c26dbb0-ee1e-4722-9ade-b2ee4eb81822\files\chat-ui-evaluation-login-handoff.txt` |

## Folder contents

| Path | Purpose |
| --- | --- |
| `open-webui\` | Open WebUI staging template and notes. |
| `librechat\` | LibreChat staging template and notes. |
| `railway-services.md` | Proposed Railway service/resource map. |
| `validation\security-checklist.md` | Pre-UAT security and privacy checks. |
| `validation\uat-feedback-template.md` | Tester feedback template. |
| `validation\teardown-checklist.md` | Cleanup checklist for keys, services, and UI data stores. |

## Non-negotiable boundaries

- Do not place provider keys in UI config.
- Do not place LiteLLM master/admin keys in UI config.
- Do not reuse LiteLLM Postgres for UI state.
- Do not expose signup to the public internet.
- Do not allow non-admin testers to add arbitrary model endpoints or direct provider keys.
- Do not commit UI data, uploads, logs, indexes, vector stores, generated keys, or environment-specific hostnames.
- Do not create, deploy, mutate, or delete Railway resources from this folder without explicit operator approval for the exact action.

## Deployment stance

Use upstream images or Railway image services for evaluation. Dockerfiles are allowed only for thin wrappers that copy placeholder/config files into pinned upstream images and remain covered by the repository image pinning policy.

Before any deployment, replace placeholders only in Railway sealed variables or local ignored files. Keep tracked files placeholder-only.
