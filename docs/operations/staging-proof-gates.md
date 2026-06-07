# Phase 8 staging proof gates

**Status:** In progress under Phase 7 staging risk exception  
**Date:** 2026-06-07  
**Auth path:** Public Railway/custom LiteLLM endpoint with LiteLLM-native virtual-key authentication  
**Related decision:** `docs\decisions\phase-7-staging-risk-exception.md`

## Scope

This document tracks Phase 8 staging proof evidence without printing endpoints, virtual keys, provider keys, database URLs, private hostnames, raw prompts, responses, SQL, stack traces, or backup credentials.

Phase 8 may proceed in staging because the operator accepted a staging-only exception for the remaining Phase 7 disaster-recovery and alerting blockers. That exception does not satisfy production readiness by itself.

## Evidence status values

| Status | Meaning |
| --- | --- |
| Passed | Direct public-staging evidence exists for this Phase 8 gate. |
| Previously validated | Earlier public-staging evidence exists and should be rerun before final Phase 8 signoff if inputs are available. |
| Needs run | Requires endpoint/key input, a live tool run, or read-only staging evidence. |
| Deferred by staging exception | Accepted for staging Phase 8 progress only; remains a production blocker. |
| Blocked | Cannot proceed without explicit operator approval or unavailable external input. |

## Mandatory smoke-test gates

| Gate | Current status | Evidence / next action |
| --- | --- | --- |
| `GET /health/readiness` passes for LiteLLM. | Previously validated | Phase 5 private readiness and Phase 6 public-origin validation passed. Rerun against public staging endpoint when endpoint input is available. |
| Anonymous public request is blocked. | Previously validated | Phase 6 public validation showed missing/anonymous auth rejected. Rerun with `scripts\phase6-validate-public-origin.ps1` or smoke tests before final signoff. |
| Missing LiteLLM key is blocked. | Previously validated | Phase 6 public validation showed missing key rejected. |
| Invalid LiteLLM key is blocked. | Previously validated | Phase 6 public validation showed invalid key rejected. |
| Valid LiteLLM virtual key can call `/v1/chat/completions`. | Previously validated | Phase 6 public validation succeeded with disposable validation key; do not reuse or print old key. |
| `/v1/models` exposes aliases, not provider credentials. | Previously validated | Phase 6 public validation covered model-list output with redaction checks. |
| Disallowed model/provider names are blocked for developer keys. | Previously validated | Phase 6 public validation denied `sensitive-code` and direct provider model names. |
| Streaming SSE works through the public/custom LiteLLM endpoint. | Previously validated | Phase 6 public validation returned SSE chunks. |
| Public docs are blocked. | Previously validated | Phase 6 public validation showed `/docs`, `/redoc`, and `/openapi.json` blocked. |
| Developer virtual keys cannot access Admin UI or admin/control routes. | Previously validated | Phase 6 public validation denied developer access to `/key/list`, `/user/info`, `/team/list`, `/config/list`, `/spend/logs`, and `/admin`; `/ui/` shell behavior must remain admin-controlled. |
| Response cache remains off for code prompts unless explicitly approved. | Needs run | Verify via config lint and runtime config review; no runtime cache proof is recorded yet. |
| Per-key daily/monthly budget windows block over-budget requests. | Needs run | Requires an explicitly created exhausted or near-exhausted test key. Do not create keys without operator approval. |
| Same-tier fallback works for controlled simulated provider failure. | Needs run | Requires a safe simulation plan that does not leak provider details or mutate production-like policy without approval. |
| No fallback silently downgrades premium aliases to weaker tiers. | Needs run | Requires config and runtime evidence for fallback policy. |
| Railway logs do not contain known prompt/response sentinels. | Needs run | Requires bounded read-only log check after a new sentinel-based public validation run. Do not print raw logs. |
| Backup worker creates off-platform logical backups. | Passed for staging backup path | Phase 7 evidence records encrypted backup upload and archive-list restore-check for the staging bucket. Production-grade external/cross-account backup choice remains unresolved. |
| Restore drill works into a fresh staging database. | Deferred by staging exception | Production blocker. Requires fresh restore-drill Postgres and restore execution. |
| Restored database supports LiteLLM virtual-key auth. | Deferred by staging exception | Production blocker. Requires restored database validation or approved controlled repoint. |
| RPO/RTO are measured. | Deferred by staging exception | Production blocker. Requires restore drill timing. |
| Backup-failure push alerting is configured. | Deferred by staging exception | Production blocker. Requires dead-man success ping, Railway cron-failure notification, or equivalent sealed configuration. |
| Provider key rotation runbook works for one provider. | Needs run | Requires explicit operator-approved rotation. Do not rotate provider keys during Phase 8 without approval. |

## Recommended validation commands

Shape-only checks:

```powershell
pwsh -NoProfile -File scripts\phase6-validate-public-origin.ps1 -ValidateOnly
python -m pytest tests\smoke --collect-only -q
```

Public staging checks require operator-provided environment variables. Do not paste values into docs, chat, tickets, screenshots, or shell history.

```powershell
$env:SMOKE_LITELLM_BASE_URL = '<staging-public-base-url>'
$env:SMOKE_LITELLM_API_KEY = '<disposable-liteLLM-virtual-key>'
$env:SMOKE_LITELLM_CHAT_MODEL = 'dev-fast'
python -m pytest tests\smoke -q
```

The PowerShell public-origin validator can cover the route matrix:

```powershell
pwsh -NoProfile -File scripts\phase6-validate-public-origin.ps1 `
  -GatewayBaseUrl '<staging-public-base-url>' `
  -VirtualKey '<disposable-liteLLM-virtual-key>' `
  -ReadinessPolicy Public `
  -AdminUiMode Enabled `
  -IncludeModels `
  -IncludeEmbeddings
```

## Phase 8 completion rule

Phase 8 can be `In progress` while staging-only exceptions exist. It must not be marked fully `Done` until either:

1. All mandatory smoke-test gates are `Passed`, or
2. Any remaining deferred gates have an explicit production-grade risk exception that satisfies the roadmap risk-exception requirements.

Phase 9 production creation remains blocked until the deferred Phase 7 disaster-recovery and alerting items are closed or separately accepted for production.
