# Staging deployment runbook

This runbook defines the handoff from Phase 4 shell provisioning to Phase 5 runtime deployment. Phase 4 intentionally stops before app source attachment or LiteLLM runtime startup.

## Current Phase 4 staging state

| Component | State |
| --- | --- |
| Railway project | `dev-orbit-llm-gateway` (`0b1bc0ec-4ace-47c3-bd13-214256c27ad5`) |
| Environment | `staging` (`f188f687-8582-4308-9110-1d082dc31b89`) |
| Postgres | `Postgres` (`1494db55-53c1-4ff1-bbe0-312340190eb7`) is deployed and healthy. |
| `litellm-proxy` | Sourceless shell only; no deployment or public URL. |
| `backup-worker` | Sourceless shell only; no deployment or public URL. |

## Phase 4 boundary

Do not deploy the app services in Phase 4.

Do not attach source until Phase 5 verifies all required runtime controls:

- `LITELLM_MASTER_KEY` is generated and stored only as a sealed Railway variable.
- Provider API keys are stored only as sealed Railway variables and use non-production or approved staging keys.
- LiteLLM Admin UI exposure decision is re-approved for staging.
- Budgets, rate limits, and metadata-only logging are confirmed.
- Public exposure posture is approved.
- Staging smoke tests have explicit endpoint/key inputs.

## Future source attachment matrix

Current Dockerfiles use repository-root-relative `COPY` paths. Keep Railway build context at repository root when attaching source.

| Service | Source timing | Build context | Dockerfile path | Healthcheck |
| --- | --- | --- | --- | --- |
| `litellm-proxy` | Phase 5 | Repository root | `services/litellm/Dockerfile` | `/health/readiness` |
| `backup-worker` | Phase 7 | Repository root | `services/backup-worker/Dockerfile` | None until backup schedule and object storage are approved. |

## Phase 5 minimum checklist before first `litellm-proxy` deployment

1. Confirm Phase 3 gates still pass locally and in GitHub Actions.
2. Confirm no app service has a public domain before runtime policy is ready.
3. Set only sealed runtime secrets through Railway, never in repository docs or command output:
   - `LITELLM_MASTER_KEY` with required `sk-` prefix
   - `LITELLM_SALT_KEY` before first boot while `store_model_in_db: true` remains enabled
   - approved staging `OPENAI_API_KEY`
4. Confirm `DATABASE_URL` remains a Railway service reference:
   - `${{Postgres.DATABASE_URL}}`
5. Attach source for `litellm-proxy` only after secrets and deployment config are ready.
6. Use repository root as build context and `services/litellm/Dockerfile` as Dockerfile path.
7. Validate readiness with `/health/readiness`, not `/health`.
8. Keep Admin UI disabled for Phase 5 with `DISABLE_ADMIN_UI=true`.
9. Keep Swagger, ReDoc, and OpenAPI schema disabled with `NO_DOCS=True`, `NO_REDOC=True`, and `NO_OPENAPI=True`.
10. Validate through a private/internal Railway path; do not create a durable public domain in Phase 5.
11. Keep total Phase 5 provider validation spend below USD 1.

## Phase 5 secret setup helper

Run this only from an operator-controlled terminal. It prompts securely and sets values with `--skip-deploys`; it does not print secret values.

```powershell
pwsh -NoProfile -File scripts\phase5-set-railway-secrets.ps1
```

Phase 5 deployment must not run until this succeeds. The helper sets `LITELLM_MASTER_KEY`, `LITELLM_SALT_KEY`, `OPENAI_API_KEY`, and `PERPLEXITY_API_KEY` without printing values.

If provider-backed validation fails with an authentication error, rerun the same helper and enter corrected provider keys; keep deploys skipped, then restart or redeploy `litellm-proxy` and rerun private validation.

## Phase 5 private runtime validation

After `litellm-proxy` is deployed, use Railway SSH to run the bundled validator inside the service container:

```powershell
$railway = Join-Path $env:APPDATA 'npm\railway.cmd'
& $railway ssh --project 0b1bc0ec-4ace-47c3-bd13-214256c27ad5 --environment staging --service litellm-proxy -- python /app/phase5_validate_litellm.py --base-url http://127.0.0.1:4000 --include-rpm-enforcement
```

The validator prints redacted pass/fail JSON and blocks disposable validation keys before exiting. Do not use `--allow-dev-search-deferred` for Phase 5 completion; that flag is only for isolating OpenAI-backed validation while Perplexity credentials are being corrected.

## Private networking interpretation

Phase 4 validated topology and reference wiring:

- `Postgres`, `litellm-proxy`, and `backup-worker` exist in the same Railway project/environment.
- App variables reference `${{Postgres.DATABASE_URL}}`.
- No public app service URLs exist.
- No public Postgres URL is documented or used by app variables.

Live app-to-Postgres connectivity proof is deferred to Phase 5 because `litellm-proxy` has no source attached and no runtime deployment in Phase 4.

## Forbidden Phase 4 actions

Do not run these until the owning later phase explicitly approves them:

- `railway up`
- `railway service source connect`
- `railway add --repo`
- `railway add --image`
- `railway domain`
- Setting provider API keys
- Setting `LITELLM_MASTER_KEY`
- Setting backup object storage credentials
- Setting generated LiteLLM developer virtual keys

## Cloudflare tunnel cleanup note

Cloudflare Tunnel/Access/WAF and edge-origin services are not part of the current staging deployment path. An earlier sourceless Railway shell may still exist from Phase 4; deleting it requires explicit operator approval before any Railway mutation.
