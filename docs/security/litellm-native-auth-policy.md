# LiteLLM native authentication policy

**Status:** Draft; required before public proof deployment  
**Related decision:** `docs\decisions\public-origin-risk-acceptance.md`

## Policy

The public Internal LLM Gateway endpoint must rely on LiteLLM-native authentication and authorization controls. No request from a developer tool should reach a provider unless LiteLLM accepts the request, the virtual key is valid, the model alias is allowed, and the key is within budget/rate limits.

## Required controls

| Control | Requirement |
| --- | --- |
| Master key | Store only as a sealed Railway variable. Do not distribute to developers. |
| Provider keys | Store only as sealed Railway variables. Reference via environment variables in config. |
| Salt key | Store `LITELLM_SALT_KEY` only as a sealed Railway variable before first boot while DB-backed model state is enabled. |
| Developer keys | One LiteLLM virtual key per developer. No shared production developer key. |
| Model access | Developers use approved aliases only; provider names are not exposed as the normal interface. |
| Budgets | Configure per-key daily and monthly budgets plus a company-level ceiling before production. |
| Rate limits | Configure per-key RPM/TPM and max concurrency/request limits before public use. |
| Admin UI | Disable for Phase 5 staging validation; protect with strong unique credentials, LiteLLM-supported SSO, or another approved hardening layer before any later exposure. |
| Admin routes | Developer virtual keys must not access `/ui`, `/key/*`, `/user/*`, `/team/*`, `/config/*`, `/admin*`, or equivalent control routes. |
| Docs/Swagger | Disable public docs/Swagger where supported, or explicitly protect it before production. |
| Logging | Keep raw prompt/response logging disabled by default. Use metadata-only logs. |
| Monitoring | Alert on spend spikes, budget exhaustion, 401/403 spikes, provider failures, and gateway 5xx. |
| Rotation | Document virtual-key and master-key rotation before production. |

Phase 5 sets `DISABLE_ADMIN_UI=true` and also loads a container startup guard that returns 404 for `/ui`, `/ui/*`, and the LiteLLM UI asset prefix. The guard is required for the pinned LiteLLM image because the UI shell remained reachable when only the documented environment flag was present.

## Phase 0 validation checklist

| Test | Status |
| --- | --- |
| Missing key is rejected on `/v1/chat/completions` | Done |
| Invalid key is rejected on `/v1/chat/completions` | Done |
| Valid developer key can call approved alias | Blocked on OpenAI credits; request reaches OpenAI and returns quota/billing 429 |
| Valid developer key can stream chat completion | Blocked on OpenAI credits; request reaches OpenAI and returns quota/billing 429 |
| Developer key cannot call admin/control routes | Done |
| Public docs/Swagger disabled or protected | Done |
| Provider key is not visible in `/v1/models` or logs | Done; `/v1/models` exposes only `dev-fast`, no secret marker found, and prompt sentinel was not found in latest logs |
| Prompt/response sentinel does not appear in Railway logs | Done |
