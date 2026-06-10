# LiteLLM Postgres outage runbook

Use this runbook when LiteLLM readiness fails because Postgres is unavailable, degraded, or suspected corrupt.

Do not expose database URLs, SQL, private hostnames, or stack traces in shared evidence.

## Triage

1. Check `Postgres` deployment status and Railway metrics.
2. Check `litellm-proxy` readiness and bounded runtime logs.
3. Confirm whether the issue followed a deploy, config change, provider outage, or Railway incident.
4. Do not enable public TCP access to debug from outside Railway.

## Recovery paths

| Scenario | Preferred action |
| --- | --- |
| Temporary Postgres restart/degradation | Wait for managed service recovery; validate readiness and key auth after recovery. |
| Bad app config or database reference | Restore the previous Railway variable/config and redeploy. |
| Data loss or corruption | Restore native snapshot or encrypted logical backup into a fresh database, validate, reconcile revoked keys, then cut over. |
| Restore drill failure | Keep Phase 7 blocked and do not proceed to production. |

## Cutover after restore

Prefer validating restored state through a disposable LiteLLM service. If live `litellm-proxy` must be repointed, save the original `DATABASE_URL` reference, use a maintenance window, validate readiness and disposable-key auth, reconcile revoked keys, and keep rollback commands ready.

## Evidence

Record service status, backup artifact or snapshot timestamp, restore start/end time, readiness result, disposable-key validation result, and rollback or cutover decision.
