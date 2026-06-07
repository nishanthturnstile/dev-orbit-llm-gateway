# Runbooks

This directory is the home for operational runbooks required before production.

Current runbooks:

- `railway-project-service-setup.md` - durable Railway project, staging environment, managed Postgres, sourceless service shell, and safe variable-reference setup.
- `staging-deployment.md` - Phase 5 staging deployment, private validation, and redeploy guardrails.
- `litellm-virtual-key-creation.md` - non-secret virtual-key creation process.
- `litellm-virtual-key-revocation.md` - non-secret virtual-key revocation process.
- `railway-backup-restore.md` - Railway native Postgres backup, snapshot restore, RPO/RTO, and restore-drill evidence process.
- `off-platform-logical-backup-restore.md` - encrypted logical backup and restore procedure for the backup worker.
- `provider-key-rotation.md` - provider, LiteLLM, backup-encryption, and developer-key rotation procedure.
- `budget-spend-alert-response.md` - staging spend/error/manual-review and backup-failure alert response.
- `litellm-postgres-outage.md` - LiteLLM Postgres outage triage and recovery.
- `provider-outage-same-tier-fallback.md` - provider outage response and same-tier fallback gate.
- `railway-deploy-rollback.md` - Railway deployment rollback and bad-config recovery.
- `prompt-log-leakage-investigation.md` - prompt/response leakage investigation procedure.

Later phases will add runbooks for production deployment, custom-domain cutover, and optional Cloudflare/edge outage handling if that hardening layer is introduced.

Do not store secrets, generated virtual keys, database URLs, backup credentials, private hostnames, or raw incident payloads in runbooks.
