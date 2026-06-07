# Provider configuration

Provider credentials must be configured as Railway variables, sealed where applicable, and referenced from LiteLLM config using `os.environ/VAR_NAME`.

## Runtime variables

| Variable | Used by | Purpose |
| --- | --- | --- |
| `OPENAI_API_KEY` | `litellm-proxy` | OpenAI-backed aliases including `dev-fast`. |
| `PERPLEXITY_API_KEY` | `litellm-proxy` | `dev-search`; Phase 5 keeps the alias present but blocks/defer runtime validation until an approved key exists. |
| `LITELLM_MASTER_KEY` | `litellm-proxy` | LiteLLM admin/master key. Must start with `sk-` but must never be committed. |
| `LITELLM_SALT_KEY` | `litellm-proxy` | Required before Phase 5 first boot while `store_model_in_db: true` remains enabled. Treat as sealed and do not rotate casually after DB state exists. |
| `DATABASE_URL` | `litellm-proxy` | Railway managed Postgres service reference for LiteLLM state. |
| `LITELLM_DATABASE_URL` | `backup-worker` | Backup-worker reference to the same LiteLLM Postgres instance. |
| `BACKUP_ENCRYPTION_KEY` | `backup-worker` | Sealed logical-backup encryption key. Escrow outside the Railway project before relying on backups for disaster recovery. |
| `BACKUP_RCLONE_DESTINATION` | `backup-worker` | rclone destination for encrypted backup artifacts and manifests. |
| `RCLONE_CONFIG_BACKUP_*` | `backup-worker` | rclone S3-compatible backup bucket configuration. Access and secret key values must be sealed. |
| `RESTORE_DATABASE_URL` | `backup-worker` | Optional restore-drill Postgres reference. Never point it at the live LiteLLM database. |
| `RESTORE_TARGET_CONFIRMED` | `backup-worker` | Non-secret guard that must equal `fresh-restore-drill` before restore mode runs. |

For Railway Object Storage, set `RCLONE_CONFIG_BACKUP_URL_STYLE=path`.

`DATABASE_URL` and `LITELLM_DATABASE_URL` intentionally have different names because they are injected into different services. They must point to the same `litellm-postgres` database when backup-worker is deployed.

## Validation gates before staging

- Verify each configured OpenAI model is available to the credited OpenAI account.
- Add and validate Perplexity credentials before marking `dev-search` complete.
- Validate embeddings before marking `dev-embed` supported.
- Validate vision input before marking `dev-vision` supported.
- Do not add same-tier fallbacks until fallback candidates are approved and tested.

## Phase 5 provider scope

Phase 5 validates OpenAI-backed aliases first under a total validation spend cap of USD 1. `dev-search` remains in the runtime config so policy metadata and validators stay consistent, but its runtime validation is blocked until `PERPLEXITY_API_KEY` is approved and sealed in Railway.

No provider key, generated virtual key, database URL, Redis URL, private host, backup credential, or backup encryption key belongs in repository files.
