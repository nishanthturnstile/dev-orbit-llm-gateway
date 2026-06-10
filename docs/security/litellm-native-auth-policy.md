# LiteLLM native authentication policy

**Status:** Draft; Phase 6 API-only public-origin preparation in progress
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
| Admin UI | Disable for Phase 5 staging validation unless explicitly testing private admin access. Phase 6 private Admin UI testing may use sealed strong `UI_USERNAME` / `UI_PASSWORD`; public Admin UI exposure remains gated until public-origin controls are explicitly approved and validated. |
| Admin routes | Developer virtual keys must not access `/ui`, `/key/*`, `/user/*`, `/team/*`, `/config/*`, `/admin*`, `/spend/*`, or equivalent control routes. |
| Docs/Swagger | Disable public docs/Swagger where supported, or explicitly protect it before production. |
| Logging | Keep raw prompt/response logging disabled by default. Use metadata-only logs. |
| Monitoring | Alert on spend spikes, budget exhaustion, 401/403 spikes, provider failures, and gateway 5xx. |
| Rotation | Document virtual-key and master-key rotation before production. |

Phase 5 sets `DISABLE_ADMIN_UI=true` and also loads a container startup guard that returns 404 for `/ui`, `/ui/*`, and the LiteLLM UI asset prefix. The guard is required for the pinned LiteLLM image because the UI shell remained reachable when only the documented environment flag was present.

## Phase 6 API-only public proof policy

The approved Phase 6 preparation posture is:

- Admin UI may be enabled for private staging testing with sealed strong credentials.
- Keep the container startup guard available so `/ui`, `/ui/*`, and the LiteLLM UI asset prefix are blocked whenever `DISABLE_ADMIN_UI=true`.
- Do not expose Admin UI publicly until public-origin controls are explicitly approved and validated.
- Do not expose a public endpoint until `dev-search` is validated or explicitly deferred/removed from the public alias set.
- Do not expose a public endpoint until exposed control-plane staging secrets are rotated.
- Require active baseline alerts for 401/403 spikes, spend spikes, budget exhaustion, provider failures, gateway 5xx, and endpoint availability before public exposure.
- Validate public error responses for secret, private-host, stack-trace, SQL, and raw prompt/response leakage.
- Use a Railway-generated public domain for the Phase 6 staging proof; custom domain setup is deferred.
- Allow public `/health/readiness` for the Phase 6 staging proof.
- Exclude Cloudflare Tunnel, Access, WAF, service tokens, and edge origin guards from Phase 6 scope.
- Use initial configurable limits of USD 5 max budget, 24h duration, 120 RPM, 300k TPM, and 5 max parallel requests for staging disposable validation keys.
- Use initial configurable MVP per-developer defaults of USD 10/day, USD 100/month, 120 RPM, 300k TPM, and 5 max parallel requests.

Phase 6 public validation must cover `/ui`, `/key/*`, `/user/*`, `/team/*`, `/config/*`, `/admin*`, `/spend/*`, docs routes, missing/invalid auth, valid approved `/v1` routes, and streaming/SSE.

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
