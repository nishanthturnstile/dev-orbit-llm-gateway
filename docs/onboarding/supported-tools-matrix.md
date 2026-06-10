# Supported tools matrix

**Status:** Phase 8 in progress; OpenAI-compatible raw HTTP validation script is supported, named developer tools require live validation
**Roadmap phase:** Phase 0 and Phase 8 client compatibility
**Tracker:** `docs\operations\implementation-status.md`

## Status values

| Status | Meaning |
| --- | --- |
| Not tested | No live proof has been run. |
| Supported | Tool can call the gateway with the required LiteLLM virtual-key auth path. |
| Supported with wrapper | Tool works only through a documented local wrapper or equivalent. |
| Blocked | Tool cannot satisfy the required auth, route, or streaming behavior. |
| Not in v1 | Tool is intentionally excluded from initial production support. |

## Compatibility matrix

| Tool | Custom base URL support | LiteLLM `Authorization` support | Streaming support | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| Continue.dev | Not tested | Not tested | Not tested | Not tested | Provider credits are available; live tool validation has not been run. |
| Cline/Roo-style VS Code tool | Not tested | Not tested | Not tested | Not tested | Provider credits are available; live tool validation has not been run. |
| Aider or equivalent CLI | Not tested | Not tested | Not tested | Not tested | Provider credits are available; live tool validation has not been run. |
| OpenAI-compatible raw HTTP validation script | Works against public Railway base URL | Works with LiteLLM virtual key | Works | Supported | After OpenAI credits were added, `scripts\phase0-validate-litellm.ps1` and the Phase 6 public-origin validator proved chat and streaming through LiteLLM. |
| OpenAI SDK scripts | Not tested | Not tested | Not tested | Not tested | Raw HTTP validation is proven, but Python/JS SDK calls have not been validated against staging. |
| Copilot CLI BYOK-compatible usage | Not tested | Not tested | Not tested | Not tested | Provider credits are available; live tool validation has not been run. |

## Minimum Phase 0 proof

At least one primary developer tool must prove:

1. It can call `/v1/chat/completions`.
2. It can target the public Railway/custom LiteLLM base URL.
3. It can send the LiteLLM virtual key in `Authorization: Bearer ...`.
4. Streaming works end-to-end through LiteLLM.

Any wrapper requirement must be documented before the tool can be marked `Supported with wrapper`.

## Phase 0 follow-up

After adding OpenAI credits, `scripts\phase0-validate-litellm.ps1` succeeded for chat and streaming through the public LiteLLM endpoint.

The OpenAI-compatible raw HTTP validation script is accepted as sufficient for Phase 2 planning. Named-tool and SDK compatibility remains deferred to Phase 8 and must be validated before a tool is marked `Supported`.

## Phase 6 note

Phase 6 public-origin validation may prove the staging public API with the OpenAI-compatible validator and disposable LiteLLM virtual keys. This does not change named developer-tool status; Continue.dev, Cline/Roo-style tools, Aider, and Copilot CLI remain Phase 8 compatibility work unless explicitly pulled forward.

## Phase 8 note

Setup instructions and evidence templates live in `docs\onboarding\supported-developer-tool-setup.md`. Do not mark OpenAI SDK scripts or named IDE/CLI tools supported based only on raw HTTP validator evidence.
