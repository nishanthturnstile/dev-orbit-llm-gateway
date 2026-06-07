# Logical backup and restore runbook

This runbook covers encrypted logical LiteLLM Postgres backups produced by `backup-worker`.

The first staging proof may use Railway Object Storage in the same project. That target is S3-compatible but not final off-platform disaster recovery. Production requires R2/S3/B2 or another external or cross-account target unless a risk exception is approved.

## Required variables

| Variable | Purpose |
| --- | --- |
| `LITELLM_DATABASE_URL` | Private Railway Postgres reference for the live LiteLLM database. |
| `BACKUP_ENCRYPTION_KEY` | Sealed encryption key. Escrow outside the Railway project. |
| `BACKUP_RCLONE_DESTINATION` | rclone destination prefix for encrypted artifacts and manifests. |
| `BACKUP_TIER` | `daily`, `weekly`, or `monthly`; defaults to `daily`. |
| `BACKUP_RETENTION_DAYS` | Optional object retention window for the destination prefix. |
| `RCLONE_CONFIG_BACKUP_*` | S3-compatible rclone remote config. Access and secret keys must be sealed. |
| `RESTORE_DATABASE_URL` | Optional fresh restore-drill database reference for restore mode. |
| `RESTORE_TARGET_CONFIRMED` | Required non-secret guard value: `fresh-restore-drill`. |

## Backup procedure

1. Confirm `backup-worker` has no public domain.
2. Confirm `LITELLM_DATABASE_URL` references `${{Postgres.DATABASE_URL}}`.
3. Configure rclone using environment variables only.
4. Run `backup-postgres.sh` through the scheduled worker or an approved one-off Railway execution.
5. Confirm the encrypted `.dump.enc` artifact and `.manifest.json` file exist in the expected prefix.
6. Record artifact key, tier, size, checksum, and completion time. Do not record endpoints or credentials.

## Restore-check procedure

1. Run `restore-check.sh` without `RESTORE_DATABASE_URL` to download, checksum, decrypt, and list the archive.
2. Treat checksum mismatch, decrypt failure, or `pg_restore --list` failure as backup failure.
3. Trigger backup-failure alert response if the check fails.

## Restore-drill procedure

1. Create a fresh staging Postgres restore-drill service with no public TCP access.
2. Set `RESTORE_DATABASE_URL` only to the fresh restore-drill database reference.
3. Set `RESTORE_TARGET_CONFIRMED=fresh-restore-drill`.
4. Run `restore-check.sh`.
5. Validate LiteLLM auth through a disposable validation path pointed at the restored database.
6. Revoke or block the disposable validation key.
7. Measure RTO and record RPO from the restored artifact timestamp.

## Retention tiers

Use separate destination prefixes or scheduled worker services for daily, weekly, and monthly tiers. If only the daily logical tier is configured in staging, record weekly/monthly as native-snapshot coverage only and keep production blocked until logical tiering is completed or risk-accepted.

## Encryption-key custody

Keep `BACKUP_ENCRYPTION_KEY` sealed in Railway and escrowed outside the Railway project. Preserve old encryption keys until all artifacts encrypted with them have expired and a restore-check has passed for artifacts written with the replacement key.
