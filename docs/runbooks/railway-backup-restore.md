# Railway native backup and restore runbook

This runbook covers Railway native backups for the LiteLLM managed Postgres service. It complements encrypted logical backups from `backup-worker`.

Do not record database URLs, backup credentials, private hostnames, snapshot internals, or raw restore output containing SQL.

## Staging target

| Item | Value |
| --- | --- |
| Project | `dev-orbit-llm-gateway` |
| Project ID | `0b1bc0ec-4ace-47c3-bd13-214256c27ad5` |
| Environment | `staging` |
| Environment ID | `f188f687-8582-4308-9110-1d082dc31b89` |
| Postgres service | `Postgres` |

## Native backup baseline

1. Verify the Postgres service is healthy.
2. Enable or confirm native Railway backups for the managed Postgres volume.
3. Configure or record the available daily, weekly, and monthly retention policy.
4. Record only schedule, retention, last successful backup time, and non-secret service identifiers.

If Railway does not expose schedule mutation through the CLI, use the Railway dashboard or approved API path and record the exact evidence collected.

## Native restore drill

1. Restore a native snapshot into a fresh staging Postgres service or Railway-supported restore target.
2. Keep public TCP/database access disabled.
3. Validate that the restored service starts and accepts private Railway connections.
4. Prefer disposable LiteLLM validation against the restored database. Do not leave the live `litellm-proxy` pointed at the restore-drill database.
5. Record start time, finish time, backup timestamp, outcome, and rollback confirmation.

## RPO and RTO

- RPO is the maximum age of the latest usable native snapshot or logical backup at restore time.
- RTO is the measured time from restore decision to a validated LiteLLM auth check against restored state.

Record measured values in `docs\operations\implementation-status.md` after every drill.

## Production gate

Native Railway backups are on-platform protection. Production still requires encrypted logical backups to an external or cross-account target, or an explicit accepted risk exception.
