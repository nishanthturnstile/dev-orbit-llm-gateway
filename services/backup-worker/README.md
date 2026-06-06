# Backup worker

This directory contains the Phase 2 scaffold for the future scheduled backup worker service.

## Boundary

The backup worker runs logical LiteLLM Postgres backups and ships encrypted/versioned copies to an approved off-platform storage target.

Phase 2 provides local scripts only. Railway scheduling, storage credentials, restore drills, and production backup operations are later-phase work.

## Runtime variables

- `LITELLM_DATABASE_URL`: backup-worker database connection. It must reference the same Railway managed Postgres instance that `litellm-proxy` receives as `DATABASE_URL`.
- `BACKUP_ENCRYPTION_KEY`: encryption passphrase/key material, sealed in Railway.
- `BACKUP_RCLONE_DESTINATION`: rclone destination path for encrypted backup objects.
- `BACKUP_RETENTION_DAYS`: optional retention window.

The backup worker intentionally uses `LITELLM_DATABASE_URL`, not `DATABASE_URL`, so the database reference is scoped to this service and cannot be confused with the LiteLLM proxy runtime variable.

## Scripts

- `scripts\backup-postgres.sh` runs `pg_dump --format=custom --no-owner --no-acl`, encrypts the archive with OpenSSL PBKDF2, and uploads only the encrypted object.
- `scripts\restore-check.sh` downloads the latest encrypted object, decrypts it locally, and validates archive readability with `pg_restore --list`. It does not restore into a database.

Both scripts fail closed if required variables are missing.

## Security rules

Do not commit:

- Database URLs.
- Backup bucket endpoints tied to private accounts.
- Access keys or secret keys.
- Encryption keys.
- Backup dumps.
- Restore artifacts.
- SQL exports.
