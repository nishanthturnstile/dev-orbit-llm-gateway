# Phase 0 launch-blocker decision record

**Status:** Phase 0 technical and policy checks complete except funded provider-backed chat/streaming validation  
**Date opened:** 2026-06-05  
**Roadmap phase:** Phase 0 - Launch-blocker validation and disposable proof spike  
**Tracker:** `docs\operations\implementation-status.md`

## Implementation control decision

Phase 0 may use disposable Railway, LiteLLM, Postgres, public-domain, optional Cloudflare, and provider resources, but no agent may create, deploy, mutate, or delete those resources without explicit operator approval for the exact action.

Until that approval and the required credentials are confirmed, Phase 0 work is limited to:

- Read-only Railway validation.
- Decision and access intake.
- Drafting Phase 0 artifacts.
- Documenting blockers and required evidence.

## Plan review

An Opus 4.8 review was completed before implementation on 2026-06-05. The review changed the execution plan in three ways:

1. Add a structured human decision and credential intake because most Phase 0 exit criteria require operator input.
2. Make live proof provisioning a hard gate instead of an implied next step.
3. Map every Phase 0 deliverable to a concrete artifact and status.

## Deliverable map

| Phase 0 deliverable | Artifact / section | Status |
| --- | --- | --- |
| Phase 0 decision record | This file | Done for Phase 0 except funded provider-backed validation |
| Disposable proof notes with resource IDs, commands, and teardown status | `docs\decisions\phase-0-disposable-proof-notes.md` | In progress; final chat/streaming proof blocked by OpenAI credits |
| Supported-tool validation notes | `docs\onboarding\supported-tools-matrix.md` | Drafted; final compatibility proof blocked by OpenAI credits |
| Public-origin risk acceptance | `docs\decisions\public-origin-risk-acceptance.md` | Done for Phase 0 |
| LiteLLM native-auth policy | `docs\security\litellm-native-auth-policy.md` | Drafted; blocked on operator approval |
| Static egress IP assessment | Static egress section in this file | Done for Phase 0 OpenAI proof; additional providers deferred |
| Initial budget and alert threshold proposal | Budget section in this file | Done for Phase 0 |
| Initial IdP/group mapping proposal | Access groups section in this file | Done for Phase 0 |
| Initial key distribution and revocation proposal | `docs\operations\key-distribution.md` | Done for Phase 0 |

## Decision and access intake

| ID | Needed decision or access | Status | Owner | Why it blocks Phase 0 |
| --- | --- | --- | --- | --- |
| D0-01 | Target Railway workspace access for validation. | Done | Operator | Operator selected a separate disposable project. `internal-llm-gateway-phase0` was created and linked in workspace `muthurema's Projects`. |
| D0-02 | Railway billing plan, target region, and expected monthly platform cost. | Done for Phase 0 | Operator / billing owner | Workspace is confirmed, target region is `asia-southeast1-eqsg3a`, and proof cap is USD 5. Durable staging/production billing plan remains a later decision. |
| D0-03 | Approval to create disposable Phase 0 Railway resources, including teardown owner and deadline. | Done | Operator | Resource creation was approved and completed; teardown owner is operator/project owner; deadline is within 24 hours after funded validation or by 2026-06-13 if validation is deferred. |
| D0-04 | Public-origin LiteLLM-native-auth risk acceptance. | Done for Phase 0 | Operator / security owner | Operator approved Phase 0 acceptance values: owner/monitoring owner, review date, proof budgets, temporary key rate limits, metadata-only logging, and strong admin credentials. |
| D0-05 | Admin UI exposure decision. | Done for Phase 0 | Operator / security owner | Strong LiteLLM admin credentials are accepted for Phase 0 only. SSO/edge gate decision must be revisited before staging/production. |
| D0-06 | Target API and admin hostnames. | Done for Phase 0 | Operator / product owner | Use the temporary Railway URL for Phase 0. Defer custom API/admin domains until staging. |
| D0-07 | Approved provider list and one low-cost proof model. | In progress | Product / operator | OpenAI `gpt-4o-mini` / `dev-fast` selected for proof; key is valid but lacks credits. |
| D0-08 | Provider static egress IP allowlisting requirements. | Done for Phase 0 OpenAI proof | Operator / provider account owner | OpenAI `/v1/models` succeeds from the proof environment and LiteLLM requests reach OpenAI. Additional providers still need assessment before production. |
| D0-09 | Company monthly budget, per-developer budget, and alert thresholds. | Done for Phase 0 | Product / finance owner | Operator approved Phase 0 proof cap and alert defaults. Durable company/developer budgets remain later staging/production decisions. |
| D0-10 | Admin/lead/developer access model. | Done for Phase 0 | Security / operator | Operator-only admin, no lead access, temporary generated developer virtual keys only, and no developer self-service. |
| D0-11 | Log retention and metadata-only logging policy. | Done for Phase 0 | Security / operator | Message logging is disabled, prompt sentinel was not found in Railway logs, and operator approved Railway default retention for proof. |
| D0-12 | Initial SLA target. | Done for Phase 0 | Product / operator | Best-effort internal proof; no production SLA. |
| D0-13 | Max request body, timeout, and streaming limits. | Done for Phase 0 | Product / operator | 60-second proof timeout, no production request-body limit in Phase 0, streaming only for approved aliases/keys. |
| D0-14 | Team sign-off that v1 uses LiteLLM Admin UI, not a custom admin portal. | Done for Phase 0 | Product / team leads | Operator approved LiteLLM Admin UI as the Phase 0 and MVP direction. |
| D0-15 | Public-origin native-auth risk acceptance. | Done for Phase 0 | Security / product owner | Phase 0 acceptance values are approved; staging/production must revisit before durable rollout. |

## Railway validation evidence

| Check | Status | Evidence |
| --- | --- | --- |
| Railway CLI installed | Done | Railway CLI 5.3.0 is installed at `C:\Users\v-mnmurugan\AppData\Roaming\npm\railway.cmd`. |
| Railway CLI authenticated | Done | `railway whoami --json` succeeded on 2026-06-05. |
| Current directory linked to Railway context | Done | `railway status --json` succeeded. Initial read-only validation saw project `gracious-surprise`; current linked proof context is `internal-llm-gateway-phase0`. |
| Project/environment/service visibility | Done | `railway service list --json` returned four services: `erpnext-docker`, `mariadb`, `redis-cache`, and `redis-queue`. |
| Latest deployment status visibility | Done | Latest deployment status is `SUCCESS` for `erpnext-docker`, `mariadb`, `redis-cache`, and `redis-queue`. |
| Disposable Phase 0 project created | Done | Project `internal-llm-gateway-phase0` was created and linked on 2026-06-05. Project ID: `c642da87-d8e5-40ec-ba54-bcd02ec1c64b`. |
| Disposable Phase 0 project empty before provisioning | Done | `railway service list --json` returned zero services after project creation. |
| Disposable Phase 0 initial resources | Done | Postgres and `litellm-proxy` were created after operator approval. Obsolete `cloudflared-tunnel` was deleted after the native-auth pivot. |
| LiteLLM deployment and readiness | Done | `litellm-proxy` deployment `09a513aa-d2f1-4eb0-bc29-fba29251cd07` is `SUCCESS`; `/health/readiness` returned healthy with DB connected. |
| LiteLLM native-auth controls | Done except provider-funded completion | Missing/invalid keys return 401, docs are disabled, generated virtual key reaches OpenAI, developer virtual key is denied admin route, `/v1/models` exposes only `dev-fast`, runtime secrets are present without being printed, and prompt sentinel was not found in logs. Valid chat/streaming is blocked by OpenAI credits. |

The linked Railway integration is readable and currently healthy for the linked ERPNext stack. This does not prove the Internal LLM Gateway architecture yet.

## Static egress assessment

**Status:** Done for Phase 0 OpenAI proof; additional providers deferred until staging/production provider selection.

The provider list is not confirmed. For each approved provider, record:

| Provider | Static egress allowlisting required? | Evidence source | Decision |
| --- | --- | --- | --- |
| OpenAI | Not required for Phase 0 proof | Direct `/v1/models` returned 200 from the injected key path; LiteLLM requests reach OpenAI | Done for Phase 0; revisit before production |
| Anthropic | Unconfirmed | Deferred until selected for staging/production | Deferred |
| Fireworks AI | Unconfirmed | Deferred until selected for staging/production | Deferred |
| Perplexity | Unconfirmed | Deferred until selected for staging/production | Deferred |

If any required provider needs static egress allowlisting that Railway cannot satisfy for this design, pause implementation and redesign egress before proceeding.

## Budget and alert threshold proposal

**Status:** Done for Phase 0; durable budgets deferred until staging/production.

Record approved values before live proof:

| Budget / alert | Proposed value | Status |
| --- | --- | --- |
| Company monthly budget | Deferred until staging | Done for Phase 0 |
| Per-developer daily budget | Deferred until staging | Done for Phase 0 |
| Per-developer monthly budget | Deferred until staging | Done for Phase 0 |
| Warning threshold | USD 3 proof spend review | Done for Phase 0 |
| Hard-stop threshold | USD 5 proof hard stop and key revocation | Done for Phase 0 |
| Proof spike max spend | USD 5 total | Done for Phase 0 |

Recommended Phase 0 defaults for approval:

| Budget / alert | Recommended Phase 0 value | Status |
| --- | --- | --- |
| Proof spike max spend | Keep under USD 5 total until teardown | Approved |
| Temporary proof virtual-key budget | USD 0.05 per generated proof key | Done for generated keys |
| Temporary proof rate limit | 10 RPM per generated proof key | Done for generated keys |
| Warning threshold | Manual review when proof spend exceeds USD 3 | Approved |
| Hard-stop threshold | Stop proof and revoke keys at USD 5 | Approved |

## Access groups proposal

**Status:** Done for Phase 0; durable IdP/group mapping deferred until staging/production.

| Role | Proposed IdP/group source | Status |
| --- | --- | --- |
| Admin | Operator only through LiteLLM master/admin credentials | Done for Phase 0 |
| Lead | Not enabled in Phase 0 proof | Done for Phase 0 |
| Developer | Temporary generated virtual key only; no shared durable developer key | Done for Phase 0 |

Recommended Phase 0 access defaults for approval:

| Role | Recommended Phase 0 source | Status |
| --- | --- | --- |
| Admin | Operator only through LiteLLM master/admin credentials | Approved |
| Lead | Not enabled in Phase 0 proof | Approved |
| Developer | Temporary generated virtual key only; no shared durable developer key | Approved |

## Recommended Phase 0 policy defaults

| Decision | Recommended Phase 0 value | Status |
| --- | --- | --- |
| Public-origin risk owner | Operator / project owner | Approved |
| Public-origin review date | 2026-06-13, or immediately after funded provider validation | Approved |
| Admin UI exposure/control | Use strong unique LiteLLM admin credentials for Phase 0 only; decide SSO/edge gate before staging/production | Approved |
| Log retention | Metadata-only; raw prompt/response logging off; rely on Railway default retention for proof only | Approved |
| Initial SLA | Best-effort internal proof; no production SLA | Approved |
| Max request body | Do not set production limit in Phase 0; revisit in staging hardening | Approved |
| Timeout | 60-second LiteLLM request timeout for proof | Approved |
| Streaming limit | Allow streaming only for approved aliases/keys; final success blocked by provider credits | Pending funded proof |
| Teardown deadline | Tear down disposable resources within 24 hours after funded provider validation, or by 2026-06-13 if validation is deferred | Approved |

## Current Phase 0 conclusion

Phase 0 is not complete. The repository now has planning, tracking, decision artifacts, successful Railway CLI validation, disposable Railway resources, a deployed LiteLLM proof with healthy Postgres connectivity, and validated native-auth rejection/admin-denial/logging controls. The live proof cannot complete until a funded provider key is available for successful chat and streaming responses, and Phase 1 should not start until the remaining risk/budget/admin/teardown decisions are closed or explicitly accepted.
