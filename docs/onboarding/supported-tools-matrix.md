# Supported tools matrix

**Status:** Draft; Phase 0 OpenAI-compatible script path is blocked only by provider credits  
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
| Continue.dev | Not tested | Not tested | Not tested | Not tested | Blocked until provider credits allow a real completion. |
| Cline/Roo-style VS Code tool | Not tested | Not tested | Not tested | Not tested | Blocked until provider credits allow a real completion. |
| Aider or equivalent CLI | Not tested | Not tested | Not tested | Not tested | Blocked until provider credits allow a real completion. |
| OpenAI-compatible validation script | Works against public Railway base URL | Works with LiteLLM virtual key | Request reaches provider | Blocked | LiteLLM accepts the virtual key and forwards to OpenAI; OpenAI returns quota/billing `429` because the key has no credits. |
| Copilot CLI BYOK-compatible usage | Not tested | Not tested | Not tested | Not tested | Blocked until provider credits allow a real completion. |

## Minimum Phase 0 proof

At least one primary developer tool must prove:

1. It can call `/v1/chat/completions`.
2. It can target the public Railway/custom LiteLLM base URL.
3. It can send the LiteLLM virtual key in `Authorization: Bearer ...`.
4. Streaming works end-to-end through LiteLLM.

Any wrapper requirement must be documented before the tool can be marked `Supported with wrapper`.

## Phase 0 follow-up

After adding OpenAI credits or switching to another funded low-cost provider, rerun `scripts\phase0-validate-litellm.ps1`. If chat and streaming succeed, mark the OpenAI-compatible validation script as `Supported`, then test one actual primary developer tool before Phase 1 is treated as unblocked.
