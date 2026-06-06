# Runbooks

This directory is the home for operational runbooks required before production.

Current runbooks:

- `railway-project-service-setup.md` - durable Railway project, staging environment, managed Postgres, sourceless service shell, and safe variable-reference setup.
- `staging-deployment.md` - Phase 5 staging deployment, private validation, and redeploy guardrails.
- `litellm-virtual-key-creation.md` - non-secret virtual-key creation process.
- `litellm-virtual-key-revocation.md` - non-secret virtual-key revocation process.

Later phases will add runbooks for production deployment, rollback, provider key rotation, budget changes, spend alerts, provider outage handling, backups, restore, and prompt/log leakage investigation.

Do not store secrets, generated virtual keys, database URLs, backup credentials, private hostnames, or raw incident payloads in runbooks.
