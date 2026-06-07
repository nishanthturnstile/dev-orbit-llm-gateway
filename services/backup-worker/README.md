# Backup worker

This directory contains the Phase 2 scaffold for the future scheduled backup worker service.

## Boundary

The backup worker runs logical LiteLLM Postgres backups and ships encrypted/versioned copies to an approved off-platform storage target.

Phase 7 hardens the local scripts for scheduled Railway execution, restore drills, and metadata-only operational evidence. Railway scheduling, object-storage credentials, and restore-drill database creation still require operator approval before mutation.

## Runtime variables

- `LITELLM_DATABASE_URL`: backup-worker database connection. It must reference the same Railway managed Postgres instance that `litellm-proxy` receives as `DATABASE_URL`.
- `BACKUP_ENCRYPTION_KEY`: encryption passphrase/key material, sealed in Railway.
- `BACKUP_RCLONE_DESTINATION`: rclone destination path for encrypted backup objects and manifests.
- `BACKUP_TIER`: optional backup tier label. Accepted values are `daily`, `weekly`, and `monthly`; default is `daily`.
- `BACKUP_RETENTION_DAYS`: optional retention window for encrypted dump and manifest objects in the destination prefix.
- `RESTORE_DATABASE_URL`: optional restore-drill database connection used only by `restore-check.sh` when intentionally restoring into a fresh database.
- `RESTORE_TARGET_CONFIRMED`: must be set to `fresh-restore-drill` before `restore-check.sh` will run destructive restore mode.
- `RCLONE_CONFIG_BACKUP_*`: environment-only rclone remote configuration for the backup bucket. Use sealed variables for access and secret keys.
  - Railway Object Storage requires `RCLONE_CONFIG_BACKUP_URL_STYLE=path`.

The backup worker intentionally uses `LITELLM_DATABASE_URL`, not `DATABASE_URL`, so the database reference is scoped to this service and cannot be confused with the LiteLLM proxy runtime variable.

For the first staging proof, Railway Object Storage is allowed as the fastest S3-compatible target. It is not the final off-platform production resilience target unless a separate production risk exception is recorded.

## Scripts

- `scripts\backup-postgres.sh` runs `pg_dump --format=custom --compress=6 --no-owner --no-acl`, encrypts the archive with OpenSSL PBKDF2, uploads only the encrypted object, and uploads a non-secret manifest with checksum and size metadata.
- `scripts\restore-check.sh` downloads the latest encrypted object, verifies the manifest checksum when present, decrypts it locally, and validates archive readability with `pg_restore --list`. When `RESTORE_DATABASE_URL` is set, it restores into that fresh restore-drill database.

Both scripts fail closed if required variables are missing.

## Restore drill rules

Use `RESTORE_DATABASE_URL` only for a fresh staging restore-drill database. Do not point it at the live LiteLLM Postgres service. The restore script refuses restore mode when `RESTORE_DATABASE_URL` matches `LITELLM_DATABASE_URL` and also requires `RESTORE_TARGET_CONFIRMED=fresh-restore-drill`. Validate restored LiteLLM auth through a disposable LiteLLM validation path or a documented maintenance-window repoint, then revoke the disposable validation key.

## Security rules

Do not commit:

- Database URLs.
- Backup bucket endpoints tied to private accounts.
- Access keys or secret keys.
- Encryption keys.
- Backup dumps.
- Restore artifacts.
- SQL exports.
- Raw backup encryption keys or key escrow material.
