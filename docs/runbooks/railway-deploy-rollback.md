# Railway deploy and config rollback runbook

Use this runbook when a Railway deployment or configuration change breaks LiteLLM, backup-worker, or related staging services.

Do not paste sealed variable values, public staging hostnames, private hostnames, or stack traces into shared docs.

## Bad deployment

1. Identify the affected service and latest deployment status.
2. Fetch bounded build/runtime logs.
3. Redeploy the last known-good commit or restore the previous service source/config through Railway.
4. Validate readiness and the relevant smoke path.
5. Record deployment IDs, commit IDs if safe, and validation result.

## Bad variable/config change

1. Identify the changed variable or service config path.
2. Restore the previous safe reference shape, not a resolved secret value.
3. Redeploy or restart if Railway does not do so automatically.
4. Validate the affected service.

## Backup-worker rollback

1. Disable or pause cron if it is producing bad artifacts.
2. Keep the last known-good encrypted artifact and manifest.
3. Restore the previous backup-worker deployment/config.
4. Run a one-off backup and restore-check before re-enabling schedule.

## Production cutover draft gate

Before production cutover, this runbook must include production service IDs, custom-domain rollback steps, alert owner, and explicit database restore decision authority. Do not fill those values until production exists.
