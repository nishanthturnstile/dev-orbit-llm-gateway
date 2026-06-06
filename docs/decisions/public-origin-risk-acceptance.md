# Public-origin LiteLLM risk acceptance

**Status:** Approved for Phase 0; selected for MVP direction, staging/production controls must be revisited  
**Date opened:** 2026-06-05  
**Related tracker:** `docs\operations\implementation-status.md`

## Decision

Phase 0 and the MVP will use a public Railway/custom endpoint for `litellm-proxy` protected by LiteLLM-native authentication and controls.

Cloudflare Tunnel, Cloudflare Access, WAF, or an edge origin guard are deferred hardening options, not the Phase 0 default.

## Why this can work

LiteLLM is designed to run as an OpenAI-compatible gateway with virtual keys, users, teams, budgets, model restrictions, rate limits, spend tracking, and admin workflows. For a small internal proof and MVP, this can satisfy the core requirement if every developer has an individual virtual key and the gateway is configured with strict budgets, rate limits, admin controls, and metadata-only logging.

## Accepted risk

Compared with the previous Cloudflare Tunnel + Access design, this accepts these residual risks:

| Risk | Impact | Required mitigation |
| --- | --- | --- |
| Public origin is reachable from the internet | Higher exposure to scanning, brute force, credential stuffing, and DoS attempts | Strong LiteLLM auth, per-key rate limits, 401/403 alerts, gateway 5xx alerts, and fast patching |
| Leaked virtual key works from any network | A leaked developer key can be abused until revoked or budget/rate limits stop it | Per-developer keys, low budgets, rate limits, revocation runbook, spend alerts |
| Admin UI/login surface may be reachable publicly | Admin credentials and LiteLLM vulnerabilities become higher-impact | Strong unique admin credentials or LiteLLM-supported SSO, no developer access to admin routes, disable public docs/Swagger |
| No Cloudflare WAF/Access identity layer | No edge identity gate, WAF, IP reputation, or Access logs | Documented risk owner, monitoring, optional future Cloudflare/edge hardening decision |

## Mandatory controls before public deployment

- `LITELLM_MASTER_KEY` is a sealed Railway variable and is never distributed to developers.
- Provider API keys are sealed Railway variables and are never committed or printed.
- Every developer receives a separate LiteLLM virtual key.
- Developer keys have approved model aliases only.
- Developer keys have daily and monthly budgets.
- Developer keys have rate limits and max request/concurrency limits.
- Admin UI uses strong unique credentials, LiteLLM-supported SSO, or another approved admin hardening layer.
- Developer virtual keys cannot access admin/control routes.
- Public docs/Swagger are disabled where supported.
- Raw prompt/response logging is off by default.
- Alerts exist for spend spikes, budget exhaustion, 401/403 spikes, provider failures, and gateway 5xx.
- Key distribution, revocation, and rotation are documented.
- The decision has an owner and a review/expiry date.

## Open approvals

| Item | Status |
| --- | --- |
| Risk owner | Approved for Phase 0: operator / project owner |
| Review/expiry date | Approved for Phase 0: 2026-06-13, or immediately after funded provider validation |
| Proof budget cap | Approved for Phase 0: USD 5 total |
| Per-developer budget | Approved for Phase 0: no durable developer budget; temporary proof keys use USD 0.05 |
| Rate-limit defaults | Approved for Phase 0: temporary proof keys use 10 RPM |
| Admin UI exposure/control decision | Approved for Phase 0: strong unique LiteLLM admin credentials; revisit SSO/edge gate before staging/production |
| Monitoring owner | Approved for Phase 0: operator / project owner |

## Recommended Phase 0 acceptance values

These values are proposed to close Phase 0 only. Staging and production must revisit them before durable rollout.

| Item | Recommended value | Status |
| --- | --- | --- |
| Risk owner | Operator / project owner | Approved |
| Review/expiry date | 2026-06-13, or immediately after funded provider validation | Approved |
| Proof budget cap | USD 5 total | Approved |
| Per-developer budget | No durable developer budget in Phase 0; temporary proof keys use USD 0.05 | Approved |
| Rate-limit defaults | Temporary proof keys use 10 RPM; production defaults deferred to staging | Approved |
| Admin UI exposure/control | Strong unique LiteLLM admin credentials for Phase 0 only; SSO/edge gate decision before staging/production | Approved |
| Monitoring owner | Operator / project owner during Phase 0 | Approved |

## Future hardening triggers

Revisit Cloudflare Tunnel/Access/WAF, IP allowlisting, or an edge origin guard if any of these happen:

- Public-origin scanning or credential-stuffing noise is operationally noisy.
- A virtual key leaks or is abused.
- Admin UI exposure is not acceptable.
- Production requires corporate SSO before traffic reaches LiteLLM.
- Railway/LiteLLM monitoring cannot provide adequate abuse visibility.
- Uptime or compliance requirements increase.
