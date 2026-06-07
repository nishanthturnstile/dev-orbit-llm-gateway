# Phase 7 staging risk exception

**Status:** Accepted for Phase 8 staging execution only  
**Date:** 2026-06-07  
**Related tracker:** `docs\operations\implementation-status.md`  
**Related roadmap phases:** Phase 7, Phase 8, Phase 9

## Decision

Phase 8 staging proof-gate implementation may proceed before the remaining Phase 7 disaster-recovery and alerting blockers are fully closed.

This is a staging-only exception. It does not approve production cutover, production traffic, or deletion of any existing Railway resources.

## Deferred Phase 7 items

| Deferred item | Current state | Required before production |
| --- | --- | --- |
| Railway native Postgres backup evidence | Blocked pending Railway backup schedule/readback evidence. | Confirm native backup schedule or record an explicit production DR exception. |
| Fresh restore drill | Blocked pending a fresh restore-drill Postgres target and restore execution. | Restore an encrypted logical backup into a fresh staging database and record evidence. |
| Restored LiteLLM auth validation | Blocked pending validation against the restored database. | Prove LiteLLM virtual-key auth works against the restored database or an approved controlled repoint. |
| RPO/RTO measurement | Blocked pending restore drill timing. | Record measured RPO/RTO from a restore drill. |
| Backup-failure push alerting | Blocked pending dead-man success ping, Railway cron-failure notification, or equivalent sealed configuration. | Configure and verify backup-failure visibility. |

## Accepted staging scope

The exception allows Phase 8 to implement and run non-destructive staging proof work for:

- Public LiteLLM-native auth and route behavior.
- Client compatibility documentation and testing.
- Smoke-test reporting.
- Production readiness review preparation.

The exception does not allow:

- Production environment creation.
- Production cutover.
- Provider key rotation.
- New virtual-key creation.
- Restore-drill database creation.
- Railway service deletion, including any existing `cloudflared-tunnel` shell.
- Any Railway, provider, database, bucket, or tunnel mutation without explicit approval for the exact action.

## Risk controls

| Control | Value |
| --- | --- |
| Risk owner | Operator / project owner |
| Scope | Staging Phase 8 only |
| Expiry / review | Before Phase 9 production creation, or by 2026-06-13, whichever comes first |
| Budget limits | Existing staging disposable key limits and MVP defaults remain the ceiling until changed by an explicit operator decision |
| Rate limits | Existing LiteLLM key/team rate limits remain required for all public validation keys |
| Monitoring | Manual staging review remains accepted temporarily; active spend/error/backup alerts remain production blockers |
| Production gate | Blocked until deferred Phase 7 items are closed or a separate production-grade risk exception is accepted |

## Evidence handling

Phase 8 evidence must separate:

- `Passed` checks with direct public-staging evidence.
- `Previously validated` checks backed by earlier public-staging proof.
- `Needs run` checks requiring endpoint/key or operator action.
- `Deferred by staging exception` checks that remain production blockers.

Do not mark Phase 8 fully `Done` while any mandatory smoke-test item is only deferred by this exception.
