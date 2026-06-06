# Virtual-key distribution and revocation

**Status:** Approved for Phase 0; durable staging/production policy pending  
**Roadmap phase:** Phase 0  
**Tracker:** `docs\operations\implementation-status.md`

## Goals

- Keep provider keys and LiteLLM master/admin keys server-side.
- Give every developer a separate LiteLLM virtual key.
- Make revocation fast when a user leaves, a key is exposed, or a budget is abused.
- Avoid sending secrets through source control, issue comments, chat history, screenshots, or browser/client code.

## Draft distribution process

1. Operator verifies the requester is in the approved developer group.
2. Admin creates a LiteLLM virtual key for one developer, with approved aliases and budgets.
3. Admin delivers the virtual key through an approved secret-sharing channel only.
4. Developer stores the key in their local secret manager or ignored `.env` file.
5. Developer configures only supported tools from `docs\onboarding\supported-tools-matrix.md`.
6. Admin records non-secret metadata: owner, team, aliases, budget tier, creation date, and rotation date.

## Draft revocation process

1. Admin revokes the LiteLLM virtual key in LiteLLM Admin UI.
2. Admin confirms the key can no longer call `/v1/chat/completions`.
3. If exposure is suspected, admin reviews metadata-only spend and access logs for the affected key.
4. Admin issues a replacement key only after the local environment or tool configuration is cleaned up.
5. Admin records non-secret revocation metadata: owner, reason, revocation time, and replacement status.

## Open decisions

| Decision | Status |
| --- | --- |
| Approved secret-sharing channel for virtual keys | Approved for Phase 0: operator-controlled local handoff only; no chat, docs, tickets, or screenshots |
| Required rotation cadence | Approved for Phase 0: generated proof keys expire after 1 day |
| Owner for key inventory | Approved for Phase 0: operator / project owner |
| Emergency revocation contact/process | Approved for Phase 0: operator revokes immediately in LiteLLM Admin UI or with master key |
| Whether developers can self-serve keys in LiteLLM Admin UI | Approved for Phase 0: no self-service |

## Recommended Phase 0 defaults

| Decision | Recommended value | Status |
| --- | --- | --- |
| Approved secret-sharing channel for virtual keys | Operator-controlled local handoff only for Phase 0; no chat, docs, tickets, or screenshots | Approved |
| Required rotation cadence | Temporary proof keys expire after 1 day; durable rotation deferred to staging policy | Approved |
| Owner for key inventory | Operator / project owner during Phase 0 | Approved |
| Emergency revocation contact/process | Operator revokes in LiteLLM Admin UI or with master key immediately on suspected leak | Approved |
| Whether developers can self-serve keys in LiteLLM Admin UI | No self-service in Phase 0 | Approved |

## Non-negotiable rules

- Do not commit generated virtual keys.
- Do not store virtual keys in shared docs, tickets, or chat messages.
- Do not expose provider keys, LiteLLM master key, database URLs, Redis URLs, Cloudflare secrets, or Railway variables to developer tools.
- Do not use a shared team key for normal developer access unless explicitly risk-accepted for a time-boxed proof.
