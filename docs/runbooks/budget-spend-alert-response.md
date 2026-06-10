# Budget, spend, and backup-failure alert response

Phase 7 staging uses manual Railway/LiteLLM review for spend and error checks, plus push-style visibility for backup failures. Production requires automated push alerts or an explicit risk exception.

## Staging review cadence

| Signal | Source | Minimum response |
| --- | --- | --- |
| Company budget threshold | LiteLLM spend metadata/Admin UI | Review spend, identify owner/team, lower budgets or revoke keys if needed. |
| Per-key spend spike | LiteLLM key metadata/Admin UI | Confirm expected usage; block suspicious keys. |
| Provider error rate | LiteLLM metadata and bounded Railway logs | Check provider status, credentials, and alias health. |
| LiteLLM 5xx/error rate | Railway HTTP/runtime logs and metrics | Triage deployment health, config changes, provider failures, and Postgres connectivity. |
| Backup failure | Dead-man success ping, Railway cron failure notification, or equivalent | Treat as urgent; run backup-worker logs and restore-check before the next scheduled backup window. |

## Response steps

1. Preserve bounded, redacted evidence only.
2. Identify affected service, alias, key metadata, provider, or backup tier.
3. Stop spend or abuse first by blocking virtual keys or lowering budgets.
4. Restore service health using the relevant outage or rollback runbook.
5. Record action taken, owner, and follow-up date without secrets or raw prompts.

## Backup-failure response

1. Check latest `backup-worker` deployment/job status.
2. Fetch bounded logs and confirm no secrets are present before sharing summaries.
3. Run `restore-check.sh` against the latest successful artifact if one exists.
4. If no recent usable backup exists, keep Phase 7 blocked and escalate before production cutover.

## Production gate

Manual review is not enough for production. Before Phase 9, configure push alerts for budget, per-key spend, provider errors, LiteLLM 5xx, and backup failures, or record an explicit risk exception.
