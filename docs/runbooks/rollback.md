# Production rollback runbook

**Status:** Draft. Use only after production exists and the operator approves the exact rollback action.

This runbook separates fast config/domain rollback from state restore. Database restore is a last-resort disaster-recovery action because it can lose users, keys, spend, revocations, UI conversations, uploads, indexes, and embeddings within the RPO window.

## Decision authority

Before any rollback, identify:

- Incident owner.
- Railway operator.
- LiteLLM admin owner.
- UI admin owner if Open WebUI or LibreChat is affected.
- Database restore approver.
- Communications owner.

Do not paste secrets, generated virtual keys, database URLs, private hostnames, public hostnames, raw prompts/responses, stack traces, or SQL into incident notes.

## Fast rollback path

Use this path for bad config, bad deploy, provider outage, leaked key, or unsafe public exposure:

1. Disable or remove the affected production custom domain if public exposure is unsafe.
2. Revoke affected LiteLLM virtual keys.
3. Disable the affected alias or provider route.
4. Redeploy the last known-good image/config.
5. Revert unsafe Railway variable reference shapes without printing values.
6. Validate `/health/readiness`.
7. Run the relevant smoke path.
8. Record sanitized evidence and user impact.

## Gateway rollback

For `litellm-proxy`:

1. Identify the last known-good deployment and config.
2. Redeploy or restore that deployment/config through Railway.
3. Confirm `DATABASE_URL` still points to the approved production Postgres reference.
4. Confirm docs/ReDoc/OpenAPI remain disabled or protected.
5. Confirm developer keys cannot access admin/control routes.
6. Confirm approved aliases still route correctly.

For provider or policy issues:

1. Disable the affected provider or alias.
2. Keep fallback same-tier only.
3. Confirm no premium alias silently downgrades to a weaker tier.
4. Notify pilot users of any temporary alias restrictions.

## Backup-worker rollback

1. Pause or disable the scheduled backup job if it is producing bad artifacts.
2. Preserve the last known-good encrypted backup and manifest.
3. Restore the previous backup-worker deployment/config.
4. Run a one-off backup.
5. Run restore-check.
6. Re-enable schedule only after validation.

## Database restore path

Use database restore only when forward-fix and config rollback cannot recover the system.

Gateway Postgres restore:

1. Confirm restore approver accepts the RPO data-loss window.
2. Restore into a fresh Postgres service where possible.
3. Validate LiteLLM readiness and database connectivity.
4. Validate virtual-key auth.
5. Reconcile revoked keys and keys created after the restore point.
6. Repoint `DATABASE_URL` only after validation and explicit approval.
7. Preserve the failed database until investigation is complete.

UI data restore:

1. Confirm which UI store is affected: Open WebUI data, LibreChat MongoDB, Meilisearch, pgvector, RAG data, uploads, or runtime volume.
2. Confirm restore approver accepts the RPO data-loss window.
3. Restore into a fresh store or volume where possible.
4. Validate login, non-admin restrictions, model restrictions, and representative UI flows.
5. Repoint the UI service only after validation and explicit approval.
6. Preserve failed stores until investigation is complete.

## UI rollback

For Open WebUI or LibreChat:

1. Disable the affected UI public domain if needed.
2. Revoke the UI-scoped LiteLLM keys if compromise is suspected.
3. Disable direct connection/provider-key features if they were accidentally exposed.
4. Redeploy the last known-good UI image/config.
5. Preserve or quarantine UI data stores according to the approved data policy.
6. Do not delete UI stores or volumes without explicit destructive-action approval.
7. Validate app auth, signup disabled, non-admin restrictions, model list, and LiteLLM route.

## Communication

Notify pilot users with:

- Affected surface: gateway API, Admin UI, Open WebUI, LibreChat, or all.
- Expected user action, such as rotate key or pause usage.
- Safe aliases or tools if any remain available.
- Whether prior UI conversations/uploads may be affected.
- When to resume usage.

Do not include secrets, hostnames, raw prompts, raw responses, or internal stack traces in user communications.
