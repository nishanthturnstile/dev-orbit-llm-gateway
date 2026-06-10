# Scripts

This directory contains repository automation and validation scripts.

Current `phase0-*` scripts are retained for Phase 0 validation and proof operations. Phase 1 does not add functional scripts beyond documentation.

Future scripts should:

- Avoid printing secrets or generated virtual keys.
- Use bounded Railway logs if Railway inspection is needed.
- Prefer placeholders and environment references over literal values.
- Fail clearly on unsafe config.
- Avoid mutating Railway, provider, database, tunnel, or edge-service resources unless the operator approved the exact action.

Planned later-phase scripts include secret checks, LiteLLM config linting, Railway smoke checks, and virtual-key creation helpers.

## Phase 6 Admin UI helper

`phase6-enable-admin-ui.ps1` prompts locally for the LiteLLM Admin UI username and password, sets `UI_USERNAME`, `UI_PASSWORD`, and `DISABLE_ADMIN_UI=false` on staging `litellm-proxy`, then requests one redeploy. Do not paste the password into docs, chat, tickets, screenshots, or logs.

## Phase 7 backup worker scripts

`services\backup-worker\scripts\backup-postgres.sh` and `services\backup-worker\scripts\restore-check.sh` are intended to run inside the backup-worker container. They read database, encryption, and rclone configuration from environment variables, write only encrypted logical backups and non-secret manifests to object storage, and emit metadata-only JSON logs.

Do not run restore mode against the live LiteLLM database. `RESTORE_DATABASE_URL` is only for a fresh restore-drill Postgres service.
