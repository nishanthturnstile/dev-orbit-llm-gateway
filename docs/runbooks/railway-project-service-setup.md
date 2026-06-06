# Railway project and service setup runbook

This runbook records the Phase 4 durable staging setup flow. It is intentionally non-secret: commands may show names and IDs, but must not print resolved Railway variables, database URLs, provider keys, Cloudflare tokens, LiteLLM keys, generated virtual keys, backup credentials, or private hostnames.

## Scope

Phase 4 owns durable Railway project, environment, database, and sourceless app service shell provisioning.

Phase 4 does not attach GitHub source, deploy app containers, create public domains, configure provider secrets, configure Cloudflare tunnel tokens, configure backup credentials, or generate LiteLLM developer keys.

## Approved target

| Item | Value |
| --- | --- |
| Workspace | `muthurema's Projects` |
| Workspace ID | `53590d57-24e3-4397-9740-6f22a913b811` |
| Project | `dev-orbit-llm-gateway` |
| Project ID | `0b1bc0ec-4ace-47c3-bd13-214256c27ad5` |
| Environment | `staging` |
| Environment ID | `f188f687-8582-4308-9110-1d082dc31b89` |
| Region | `asia-southeast1-eqsg3a` |
| Spend guardrail | Use Railway default limits and monitor staging spend. |

## Preflight

Run local gates before mutating Railway:

```powershell
pwsh -NoProfile -File scripts\lint-litellm-config.ps1
pwsh -NoProfile -File scripts\check-secrets.ps1
python -m pytest tests\smoke -q
```

Confirm the Railway CLI is authenticated and identify the current linked context:

```powershell
$railway = Join-Path $env:APPDATA 'npm\railway.cmd'
$env:RAILWAY_CALLER = 'skill:use-railway@1.2.2'
$env:RAILWAY_AGENT_SESSION = 'railway-skill-phase4-93980194'
& $railway whoami --json
& $railway status --json
& $railway project list --json
```

The linked context before Phase 4 was the disposable Phase 0 project. Do not mutate it.

## Duplicate-prevention checks

Before creating resources, list projects in the approved workspace and confirm no durable gateway project already exists:

```powershell
& $railway project list --json
```

If `dev-orbit-llm-gateway` exists, stop and confirm whether to reuse it. Do not create a duplicate project.

Before adding services, list services in `staging`:

```powershell
& $railway service list --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --json
```

If a matching service exists, read it back and reuse it unless the operator explicitly approves a replacement.

## Project and environment creation

Phase 4 created the durable project:

```powershell
& $railway init --name dev-orbit-llm-gateway --workspace 53590d57-24e3-4397-9740-6f22a913b811 --json
```

Phase 4 created the persistent staging environment:

```powershell
& $railway environment new staging --json
```

Railway also created a default `production` environment. Keep it unused until production rollout phases.

## Managed Postgres

Create exactly one managed Postgres service in staging:

```powershell
& $railway add --database postgres --json
```

Railway created service `Postgres` with ID `1494db55-53c1-4ff1-bbe0-312340190eb7`. The original plan requested `litellm-postgres`, but the managed Postgres template kept the default service name. Use the actual case-sensitive service name in references:

```text
${{Postgres.DATABASE_URL}}
```

Do not print or document the resolved `DATABASE_URL`.

## App service shells

Create empty services only:

```powershell
& $railway add --service litellm-proxy --json
& $railway add --service backup-worker --json
& $railway add --service cloudflared-tunnel --json
```

Created app shell IDs:

| Service | ID |
| --- | --- |
| `litellm-proxy` | `335b0f28-2d4c-42b7-b3c9-063bcf296a25` |
| `backup-worker` | `f1e6e49c-8320-4b30-a070-d59d285f520c` |
| `cloudflared-tunnel` | `ec0b7723-219f-4f54-8896-3ed010ed1e3d` |

Do not run `railway up`, connect repository source, connect Docker images, or generate domains in Phase 4.

## Safe variable references

Set only non-secret variables and Railway service references. Use `--skip-deploys`.

```powershell
& $railway variable set ENVIRONMENT=staging PORT=4000 NO_DOCS=True NO_REDOC=True 'DATABASE_URL=${{Postgres.DATABASE_URL}}' --service litellm-proxy --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --skip-deploys --json

& $railway variable set ENVIRONMENT=staging 'LITELLM_DATABASE_URL=${{Postgres.DATABASE_URL}}' --service backup-worker --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --skip-deploys --json
```

Do not set provider keys, `LITELLM_MASTER_KEY`, `TUNNEL_TOKEN`, backup credentials, encryption keys, production secrets, or generated virtual keys in Phase 4.

## Future-safe service settings

The app shells may store non-secret build/deploy settings before source is attached:

```powershell
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config litellm-proxy build.builder DOCKERFILE --json
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config litellm-proxy build.dockerfilePath services/litellm/Dockerfile --json
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config litellm-proxy deploy.healthcheckPath /health/readiness --json
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config litellm-proxy deploy.healthcheckTimeout 300 --json
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config backup-worker build.builder DOCKERFILE --json
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config backup-worker build.dockerfilePath services/backup-worker/Dockerfile --json
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config cloudflared-tunnel build.builder DOCKERFILE --json
& $railway environment edit --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service-config cloudflared-tunnel build.dockerfilePath services/cloudflared-tunnel/Dockerfile --json
```

These settings do not attach source. Source attachment is Phase 5+.

## Readback checks

Use readback commands after each mutation:

```powershell
& $railway service list --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --json
& $railway variable list --service litellm-proxy --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --json
& $railway variable list --service backup-worker --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --json
& $railway environment config --environment staging --json
```

When sharing evidence, print keys and non-secret IDs only. Do not print resolved variable values.

Expected Phase 4 end state:

- Durable project exists and is separate from Phase 0.
- Persistent `staging` environment exists.
- `Postgres` is `SUCCESS`.
- App services are sourceless, undeployed, and have no public URLs.
- No app service has public domains.
- App service variables use `${{Postgres.DATABASE_URL}}`.
- No provider, Cloudflare, LiteLLM master, backup, production, or generated developer credentials are set.

