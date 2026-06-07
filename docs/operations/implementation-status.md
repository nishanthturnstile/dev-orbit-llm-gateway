# Implementation status tracker

**Status date:** 2026-06-07
**Current phase:** Phase 8 - Staging proof gates and client compatibility (In progress under Phase 7 staging risk exception; production remains blocked by deferred DR/alerting gates)
**Primary roadmap:** `docs\internal-llm-gateway-implementation-roadmap.md`

## Status rules

| Status | Meaning |
| --- | --- |
| Not started | Work has not begun. |
| In progress | Work is actively being planned, validated, or implemented. |
| Blocked | Work cannot proceed without an explicit decision, credential, approval, or external resource. |
| Done | Work has evidence recorded and satisfies the relevant roadmap requirement. |

Do not mark a task `Done` without evidence in this file or a linked Phase 0 artifact. Do not advance a later phase until all current-phase exit criteria are `Done` or explicitly accepted as a documented risk exception.

## Phase overview

| Phase | Name | Status | Evidence / blocker |
| ---: | --- | --- | --- |
| 0 | Launch-blocker validation and disposable proof spike | Done | Railway + LiteLLM native-auth proof is validated with credited OpenAI chat and streaming through the OpenAI-compatible validation script. Operator accepted script validation for Phase 2 planning and deferred named developer-tool compatibility to Phase 8. Disposable resources are explicitly Phase 0 only and not staging/production despite Railway's default environment name. |
| 1 | Repository and project structure | Done | Repository-only gate exception accepted while Phase 0 funded provider proof remains blocked. Structure/docs/placeholders added; no Railway/provider resources mutated. |
| 2 | Local service scaffolding and policy/config authoring | Done | Local scaffolds, LiteLLM runtime config, policy metadata, smoke skeletons, and validation docs are complete. Local YAML/verifier/shell syntax/pytest validation passed. GPT-5.5 and Opus 4.8 reviews approved with no blockers. Cloudflare tunnel scaffolds were later removed from the current implementation path during Phase 8 planning cleanup. No Railway/provider/tunnel resources were mutated by that cleanup. |
| 3 | CI/CD, secret scanning, and policy gates | Done | Local/CI enforcement scripts, GitHub Actions workflows, secret scanning, and image policy gates are complete. Local validation passed; GPT-5.5 approved as-is and Opus 4.8 approved with minor hardening notes that were addressed. No Railway/provider/Cloudflare/GitHub settings were mutated. |
| 4 | Durable Railway staging provisioning | Done | Durable Railway project `dev-orbit-llm-gateway` and `staging` environment exist. Managed Postgres is healthy; app service shells are sourceless, undeployed, and domainless. Local validation passed; GPT-5.5 and Opus 4.8 reviewed with no blockers. |
| 5 | LiteLLM deployment and runtime policy validation | Done | `litellm-proxy` deployment `095bc349-2e77-4552-9ab4-ff36d54bb506` is `SUCCESS` with one running replica and no public URL. Private validation passes for readiness, missing/invalid auth, OpenAI-backed aliases, streaming, embeddings, key metadata persistence, admin route denial, forbidden/direct-provider alias denial, spend metadata access, disposable-key blocking, docs/ReDoc/OpenAPI closure, Admin UI private reachability with sealed credentials, and targeted `dev-search` validation with the rotated Perplexity key. |
| 6 | Public-origin hardening and access validation | Done | Railway-generated staging endpoint is live. Missing/invalid auth is blocked, valid disposable keys succeed on approved `/v1` chat/search/embedding routes, developer key admin route is denied, docs/ReDoc/OpenAPI are blocked, Admin UI loads at `/ui/` with sealed credentials, and disposable public validation key was blocked. Active alerting is explicitly risk-accepted as deferred for this staging proof. |
| 7 | Backups, restore, alerts, and runbooks | In progress | Staging backup-worker path is validated, and the operator accepted a staging-only risk exception to defer native backup evidence, fresh restore drill, restored DB auth validation, RPO/RTO measurement, and backup-failure push alerting to the final pre-production gate. These remain production blockers. |
| 8 | Staging proof gates and client compatibility | In progress | Phase 8 plan has GPT-5.5 and Opus 4.8 review. Staging risk exception, proof-gate checklist, developer-tool setup doc, and production readiness draft are added. Runtime/client evidence still needs operator endpoint/key/tool inputs. |
| 9 | Production deployment, cutover, and pilot | Not started | Depends on all staging proof gates. |
| 10 | Post-pilot hardening and deferred capabilities | Not started | Depends on production pilot findings. |

## Current direction correction

| Item | Status | Evidence / blocker |
| --- | --- | --- |
| Remove Cloudflare tunnel/access/edge from current implementation path. | Done | Repository scaffold cleanup and source-doc alignment are complete. `services\cloudflared-tunnel`, `config\cloudflare`, `tests\smoke\test_cloudflare_block.py`, the `.env.example` tunnel placeholder, and the hard-coded cloudflared YAML lint path were removed. Historical evidence and defensive secret-scanning rules are preserved. Local lint, secret scan, and smoke collection/tests passed. |
| Railway `cloudflared-tunnel` shell cleanup. | Blocked | A sourceless shell may still exist from earlier Phase 4 work. Deletion is a Railway mutation and requires explicit operator approval before action. |
| Phase 8 proof execution. | In progress | Proceeding under `docs\decisions\phase-7-staging-risk-exception.md`; deferred Phase 7 items remain production blockers. |

## Chat UI evaluation add-on

| Item | Status | Evidence / blocker |
| --- | --- | --- |
| Open WebUI and LibreChat staging evaluation scaffold. | Done | `chat-ui-evaluation` documents separate staging UI services, UI-only data stores, teardown requirements, scoped LiteLLM UI keys, exact Railway approval boundaries, deployed controls, and validation evidence. |
| Open WebUI and LibreChat staging deployment. | Done | Operator approved the staging deployment. Open WebUI and LibreChat evaluation services, volumes/data stores, public Railway domains, scoped LiteLLM UI keys, and sealed service variables are configured in `staging`. Open WebUI uses separate chat and RAG LiteLLM keys; root/health, admin login, restricted chat model list, and chat via `dev-fast` returned HTTP 200. LibreChat API, MongoDB, Meilisearch, pgvector, and RAG API are running; LibreChat admin bootstrap is complete, registration is disabled, the `LiteLLM Staging` endpoint exposes only approved chat aliases, and chat via `/api/agents/chat/custom` returned HTTP 200. |

## Phase 0 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P0-01 | Review Phase 0 plan with a second model before implementation. | Done | Opus 4.8 review completed on 2026-06-05; plan updated with a hard no-provisioning gate, decision/access intake, and deliverable mapping. | This file; `docs\decisions\phase-0-launch-blockers.md` |
| P0-02 | Confirm Railway CLI access and current linked context using read-only validation. | Done | Railway CLI 5.3.0 is installed and authenticated. Initial read-only validation saw `gracious-surprise`; the former proof context was `internal-llm-gateway-phase0`; the repository is now linked to durable project `dev-orbit-llm-gateway`. | `docs\decisions\phase-0-launch-blockers.md` |
| P0-03 | Confirm Railway workspace, billing plan, target region, and expected monthly platform cost. | Done for Phase 0 | Workspace is `muthurema's Projects`; proof project is `internal-llm-gateway-phase0`; active services run in `asia-southeast1-eqsg3a`; operator approved a USD 5 proof cap. Durable staging/production billing must be revisited later. | `docs\decisions\phase-0-launch-blockers.md` |
| P0-04 | Confirm public-origin LiteLLM-native-auth risk acceptance. | Done for Phase 0 | Operator approved public-origin LiteLLM-native auth defaults for Phase 0: risk owner/monitoring owner is operator/project owner, review by 2026-06-13 or immediately after funded validation, USD 5 cap, strict temporary key budget/rate limit, metadata-only logging, and strong admin credentials. | `docs\decisions\phase-0-launch-blockers.md`; `docs\decisions\public-origin-risk-acceptance.md` |
| P0-05 | Confirm target domain names for developer API and admin UI. | Done for Phase 0 | Operator approved using the temporary Railway URL for Phase 0 and deferring custom API/admin domains until staging. The temporary proof URL belonged to the deleted disposable Phase 0 project. | `docs\decisions\phase-0-launch-blockers.md` |
| P0-06 | Confirm provider accounts and low-cost proof model. | Done | OpenAI `gpt-4o-mini` / `dev-fast` selected. Credited OpenAI key validated through LiteLLM chat and streaming. | `docs\decisions\phase-0-launch-blockers.md`; `docs\decisions\phase-0-disposable-proof-notes.md` |
| P0-07 | Confirm provider static egress IP allowlisting requirements. | Done | OpenAI `/v1/models` succeeds from the Railway-injected environment and LiteLLM requests reach OpenAI; no static egress blocker observed for the Phase 0 OpenAI proof. Additional providers must still be assessed before production use. | `docs\decisions\phase-0-launch-blockers.md` |
| P0-08 | Confirm company budget, per-developer budget, and alert thresholds. | Done for Phase 0 | Operator approved Phase 0 proof budget defaults: USD 5 total cap, USD 3 warning review point, USD 5 hard stop/revoke point, temporary generated keys at USD 0.05 and 10 RPM. Durable company/developer budgets are deferred to staging. | `docs\decisions\phase-0-launch-blockers.md` |
| P0-09 | Confirm admin/lead/developer access model. | Done for Phase 0 | Operator approved Phase 0 access defaults: operator-only admin, no lead access, temporary generated developer virtual keys only, and no developer self-service. | `docs\decisions\phase-0-launch-blockers.md`; `docs\operations\key-distribution.md` |
| P0-10 | Confirm secure virtual-key distribution and revocation process. | Done for Phase 0 | Operator approved Phase 0 key defaults: local operator-controlled handoff only, no chat/docs/tickets/screenshots, temporary 1-day proof keys, operator-owned inventory, and immediate LiteLLM revocation on suspected leak. | `docs\operations\key-distribution.md` |
| P0-11 | Confirm log retention and metadata-only logging policy. | Done for Phase 0 | Operator approved metadata-only proof logging with raw prompt/response logging off and Railway default retention for Phase 0. Prompt sentinel was not found in latest Railway logs. | `docs\decisions\phase-0-launch-blockers.md` |
| P0-12 | Confirm initial SLA target. | Done for Phase 0 | Operator approved best-effort internal proof SLA with no production SLA commitment. | `docs\decisions\phase-0-launch-blockers.md` |
| P0-13 | Confirm max request body, timeout, and streaming limits. | Done for Phase 0 | Operator approved Phase 0 defaults: 60-second proof timeout, no production request-body limit in Phase 0, and streaming allowed only for approved aliases/keys. Credited streaming validation now succeeds through LiteLLM. | `docs\decisions\phase-0-launch-blockers.md`; `docs\decisions\phase-0-disposable-proof-notes.md` |
| P0-14 | Stand up disposable proof with LiteLLM, Postgres, public Railway endpoint, and one low-cost provider/model. | Done | Disposable Railway project `internal-llm-gateway-phase0`, Postgres, and `litellm-proxy` exist. Latest deployment `2cba1ae5-6bb6-4043-8630-d389c1861ae4` is `SUCCESS`; readiness is healthy; missing/invalid keys are rejected; docs are disabled; developer key is denied admin route; credited provider chat and streaming succeed. | `docs\decisions\phase-0-disposable-proof-notes.md` |
| P0-15 | Prove one primary developer tool can call `/v1/chat/completions` with a LiteLLM virtual key. | Done | OpenAI-compatible validation script succeeds with generated LiteLLM virtual key and public Railway base URL. Operator accepted this as sufficient for Phase 2 planning; named developer-tool compatibility is deferred to Phase 8. | `docs\onboarding\supported-tools-matrix.md`; `docs\decisions\phase-2-developer-tool-validation-deferral.md` |
| P0-16 | Prove streaming through the temporary public LiteLLM endpoint. | Done | OpenAI-compatible validation script returned `200` and received stream chunks through LiteLLM with a generated virtual key. | `docs\onboarding\supported-tools-matrix.md`; `docs\decisions\phase-0-disposable-proof-notes.md` |
| P0-17 | Record public-origin LiteLLM-native-auth risk acceptance. | Done for Phase 0 | Public-origin risk acceptance values are recorded and approved for Phase 0 only; staging/production must revisit before durable rollout. | `docs\decisions\phase-0-launch-blockers.md`; `docs\decisions\public-origin-risk-acceptance.md` |
| P0-18 | Tear down disposable proof resources or mark them non-production/non-staging. | Done | Disposable resources were explicitly Phase 0 only. Railway accepted deletion for project `internal-llm-gateway-phase0` (`c642da87-d8e5-40ec-ba54-bcd02ec1c64b`); readback shows `deletedAt=2026-06-08T06:40:12.528Z`. | `docs\decisions\phase-0-disposable-proof-notes.md` |

## Phase 0 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| Public Railway/custom LiteLLM endpoint works only with valid LiteLLM-native authentication. | Done | Readiness is healthy. Missing/invalid keys are rejected. A generated virtual key is accepted by LiteLLM and credited OpenAI-backed chat and streaming succeed. |
| `/v1` access strategy is proven with at least one real developer tool. | Done | OpenAI-compatible validation script succeeds with generated LiteLLM virtual key and public Railway base URL. Operator accepted this as sufficient for Phase 2 planning; named developer-tool compatibility is deferred to Phase 8. |
| Streaming works through the temporary public LiteLLM endpoint. | Done | OpenAI-compatible validation script returned `200` and received stream chunks through LiteLLM with a generated virtual key. |
| Missing/invalid LiteLLM keys are rejected. | Done | Missing and invalid keys return 401 on `/v1/chat/completions`. |
| Developer virtual keys cannot access LiteLLM admin/control routes. | Done | Temporary developer virtual key receives 403 on `/key/list`. |
| Public-origin risk is accepted with owner, budget limits, rate limits, monitoring, and review/expiry date. | Done for Phase 0 | Operator approved Phase 0 acceptance values: owner/monitoring owner is operator/project owner, review by 2026-06-13 or immediately after funded validation, USD 5 proof cap, temporary key budgets/rate limits, metadata-only logging, and strong admin credentials. |
| Provider static egress IP requirements are confirmed. | Done | OpenAI key is recognized via direct `/v1/models`; no static egress blocker observed in Phase 0 tests. |
| The team agrees the MVP uses LiteLLM Admin UI, not a custom admin portal. | Done for Phase 0 | Operator approved LiteLLM Admin UI for Phase 0 and MVP direction; custom admin portal remains deferred unless LiteLLM Admin UI proves insufficient. |
| Disposable proof resources are torn down or explicitly marked non-production/non-staging. | Done | Railway accepted deletion for the disposable Phase 0 project; readback shows a scheduled `deletedAt`. Durable staging is separate. |

## Phase 0 handoff before Phase 1

Phase 1 should not start until the following are closed or explicitly risk-accepted:

| Required before Phase 1 | Status | Notes |
| --- | --- | --- |
| Funded provider proof | Done | OpenAI credits added; `railway run --service litellm-proxy --environment production -- pwsh -NoProfile -File .\scripts\phase0-validate-litellm.ps1` returned `200` for chat and streaming. |
| Real `/v1/chat/completions` response | Done | Credited OpenAI-backed chat through LiteLLM returned `200`. |
| Real streaming response | Done | Credited OpenAI-backed streaming through LiteLLM returned `200` with stream chunks received. |
| Public-origin risk owner and review date | Done for Phase 0 | Operator/project owner owns risk and monitoring; review by 2026-06-13 or immediately after funded validation. |
| Proof budget and alert thresholds | Done for Phase 0 | USD 5 total cap, USD 3 warning review, USD 5 hard stop/revoke point, generated proof keys at USD 0.05 and 10 RPM. |
| Admin UI exposure/control decision | Done for Phase 0 | Strong LiteLLM admin credentials for Phase 0 only; SSO/edge gate decision deferred before staging/production. |
| Teardown owner/deadline for Phase 0 resources | Done | Operator/project owner; Railway accepted deletion for the disposable proof project after funded validation. |
| Phase 1 scope confirmation | Done | Operator accepted repository-only Phase 1 work before funded provider proof completion, with functional config/scripts/tests/CI deferred to Phase 2/3. Decision recorded in `docs\decisions\phase-1-repository-gate-exception.md`. |

## Phase 1 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P1-01 | Confirm Phase 1 can proceed while Phase 0 provider proof remains blocked. | Done | Operator approved repository-only Phase 1 work with no Railway/provider mutations and no claim that Phase 0 runtime proof is complete. | `docs\decisions\phase-1-repository-gate-exception.md` |
| P1-02 | Confirm final service list and deferred components. | Done | V1 boundary keeps LiteLLM Proxy, Railway managed Postgres, and backup worker. Custom admin, edge-origin services, Redis, and Cloudflare Tunnel/Access/WAF remain out of current implementation unless a later design decision reintroduces them. | `docs\decisions\v1-service-boundaries.md` |
| P1-03 | Add root repository README. | Done | Root README describes purpose, Railway target, service list, local development approach, deployment model, and source docs. | `README.md` |
| P1-04 | Add `.env.example` with placeholder variable names only. | Done | Placeholder env file contains no real secrets, generated virtual keys, URLs, or private hostnames. | `.env.example` |
| P1-05 | Add service README placeholders. | Done | LiteLLM and backup-worker service boundaries are documented. The earlier cloudflared placeholder was removed from the current implementation path during Phase 8 planning cleanup. | `services\litellm\README.md`; `services\backup-worker\README.md` |
| P1-06 | Add config and docs homes. | Done | Railway, LiteLLM config notes, runbooks, scripts, and tests homes are tracked. The earlier Cloudflare docs home was removed from the current implementation path during Phase 8 planning cleanup. | `config\railway\README.md`; `config\litellm\README.md`; `docs\runbooks\README.md`; `scripts\README.md`; `tests\README.md` |
| P1-07 | Record repository structure. | Done | Current tree, Phase 0 artifacts, Phase 1 additions, deferred directories, and config source-of-truth decision documented. | `docs\operations\repository-structure.md` |

## Phase 1 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| The repo documents Railway + LiteLLM architecture, service boundaries, and deferred components. | Done | Root README, service READMEs, config docs, `v1-service-boundaries.md`, and `repository-structure.md` document included and deferred components. Cloudflare tunnel/access/edge is not part of current implementation. |
| No real secrets or generated credentials are present. | Done | Phase 1 files use placeholders only and do not add real secrets or generated virtual keys. |
| Deferred directories are not created unless approved. | Done | `apps\admin-web`, `services\admin-api`, and `services\llm-edge` remain absent. |
| The repository can be checked out cleanly by another developer. | Done | Required Phase 1 directories contain tracked README or `.gitkeep` files. |

## Phase 2 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P2-01 | Review Phase 2 plan with GPT and Opus before implementation. | Done | GPT-5.5 and Opus 4.8 reviewed the plan; feedback was incorporated before implementation. | Session `plan.md` |
| P2-02 | Move LiteLLM runtime config source of truth. | Done | `services\litellm\config.yaml` exists, `services\litellm\Dockerfile` copies it, and former `config\litellm\config.yaml` is removed. | `services\litellm\Dockerfile`; `services\litellm\config.yaml` |
| P2-03 | Create LiteLLM config validation script. | Done | `bash services/litellm/scripts/verify-config.sh` passed; script fails closed on missing Python/PyYAML and policy violations. | `services\litellm\scripts\verify-config.sh` |
| P2-04 | Create model alias, provider denylist, and policy artifacts. | Done | Verifier confirms alias metadata matches runtime aliases and denylist rules are enforced. Opus review naming note was addressed by renaming wildcard-route metadata. | `config\litellm\model-aliases.yaml`; `config\litellm\provider-denylist.yaml`; `config\litellm\policy.md` |
| P2-05 | Create deferred Cloudflare tunnel scaffold. | Done | Historical Phase 2 scaffold was created and reviewed, then removed from the current implementation path during Phase 8 planning cleanup after the no-Cloudflare-current-implementation decision. | `docs\operations\repository-structure.md` |
| P2-06 | Create backup worker scaffold. | Done | Bash syntax validation passed; scripts fail closed on missing env, encrypt backup output, and do not upload unencrypted dumps. | `services\backup-worker\Dockerfile`; `services\backup-worker\scripts\backup-postgres.sh`; `services\backup-worker\scripts\restore-check.sh` |
| P2-07 | Create smoke test skeletons. | Done | `python -m pytest tests\smoke -q` passed with 5 skipped by explicit env gates. | `tests\smoke\*.py`; `pytest.ini` |
| P2-08 | Add required Phase 2 docs outputs. | Done | Provider config, local validation, model alias policy, fallback deferral, service docs, and repository structure docs are updated. | `docs\security\model-alias-policy.md`; `docs\operations\provider-config.md`; `docs\operations\local-config-validation.md`; `docs\decisions\phase-2-fallback-deferral.md` |

## Phase 2 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| Local config parses. | Done | PyYAML parses `services\litellm\config.yaml`, `config\litellm\model-aliases.yaml`, and `config\litellm\provider-denylist.yaml`. |
| All secrets are represented as environment references or placeholders. | Done | Verifier passed and targeted scans found no literal provider keys, database URLs, private keys, or concrete Railway/private hostnames in Phase 2 service/config/test artifacts. |
| Required aliases exist. | Done | Verifier confirms all eight required aliases exist and alias metadata matches runtime aliases. |
| `sensitive-code` and `sensitive-*` aliases are absent. | Done | Verifier blocks `sensitive-*`; scans show mentions only in policy/roadmap docs, not runtime config. |
| Service scaffolds include README notes for deployment and security boundaries. | Done | LiteLLM and backup-worker READMEs document runtime source, deployment boundaries, and deferred gates. |
| No service exposes or assumes a public Railway domain for `litellm-proxy`. | Done | Targeted Phase 2 service/config/test scan found no `.up.railway.app` values outside historical Phase 0 docs/status. |
| GPT and Opus implementation reviews are complete. | Done | GPT-5.5 approved as-is. Opus 4.8 approved with one non-blocking denylist clarity note, which was addressed before final validation. |

## Phase 3 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P3-01 | Review Phase 3 plan with GPT and Opus before implementation. | Done | GPT-5.5 and Opus 4.8 reviewed the plan; feedback was incorporated before implementation. | Session `plan.md` |
| P3-02 | Add shared LiteLLM config linting. | Done | Shared Python validator, shell launcher, and PowerShell lint gate created. `python scripts\validate-litellm-config.py`, `bash services/litellm/scripts/verify-config.sh`, and `pwsh -NoProfile -File scripts\lint-litellm-config.ps1` passed. | `scripts\validate-litellm-config.py`; `services\litellm\scripts\verify-config.sh`; `scripts\lint-litellm-config.ps1` |
| P3-03 | Add secret scanning. | Done | `.gitleaks.toml` and `scripts\check-secrets.ps1` created. Pinned Gitleaks working-tree scan returned no leaks. | `.gitleaks.toml`; `scripts\check-secrets.ps1` |
| P3-04 | Add CI policy workflow. | Done | Read-only, secret-free CI workflow created with SHA-pinned actions, `persist-credentials: false`, no path filters, and no `pull_request_target`. Workflow policy lint passed. | `.github\workflows\ci.yml` |
| P3-05 | Add image policy workflow. | Done | Image policy workflow created; all service Dockerfiles use digest-pinned base images, including backup-worker. | `.github\workflows\image-policy.yml`; `services\backup-worker\Dockerfile` |
| P3-06 | Add staging smoke workflow skeleton. | Done | Validate-only workflow and script created; no network, Railway CLI, provider, or secret usage. | `.github\workflows\staging-smoke.yml`; `scripts\smoke-railway.ps1` |
| P3-07 | Add Phase 3 docs. | Done | CI policy and secret-scanning docs created; README, repository structure, local validation, and status docs updated. | `docs\operations\ci-policy-gates.md`; `docs\security\secret-scanning.md` |
| P3-08 | Validate and review implementation. | Done | Full local validation passed. GPT-5.5 approved as-is; Opus 4.8 approved with two non-blocking hardening notes, both addressed before final validation. | This file |

## Phase 3 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| Unsafe config cannot merge. | Done | `ci.yml`, shared validator, PowerShell lint, workflow static checks, and repository hygiene gates are present and validated locally. |
| Secret scanning runs locally and in CI. | Done | `scripts\check-secrets.ps1` runs locally and in `ci.yml`; pinned Gitleaks working-tree scan returned no leaks. |
| LiteLLM config linting runs locally and in CI. | Done | Shared Python validator runs via shell and PowerShell wrappers locally and in `ci.yml`. |
| Image pinning checks run in CI. | Done | `image-policy.yml` runs the image policy checks; all service Dockerfiles are digest-pinned. |
| Smoke-test workflow can be run once staging exists. | Done | `staging-smoke.yml` is validate-only in Phase 3 and calls `scripts\smoke-railway.ps1 -ValidateOnly`. |

## Phase 4 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P4-01 | Review Phase 4 plan with GPT and Opus before implementation. | Done | GPT-5.5 and Opus 4.8 reviewed the plan. Feedback was incorporated: no source attachment, no app deployment, private-network proof deferred to Phase 5 runtime validation, and root build context retained for current Dockerfiles. | Session `plan.md` |
| P4-02 | Create durable Railway project and persistent staging environment. | Done | Project `dev-orbit-llm-gateway` (`0b1bc0ec-4ace-47c3-bd13-214256c27ad5`) exists in workspace `muthurema's Projects`; persistent `staging` environment (`f188f687-8582-4308-9110-1d082dc31b89`) exists. Default `production` environment remains unused. | `config\railway\staging.md` |
| P4-03 | Provision managed Postgres for LiteLLM state. | Done | Managed Postgres service `Postgres` (`1494db55-53c1-4ff1-bbe0-312340190eb7`) is deployed in staging with latest deployment `9187450c-4db4-4c43-bb79-5f1bc3611ffc` in `SUCCESS`; one replica is running and volume `postgres-volume` is ready. Railway template kept service name `Postgres`, so variable references use `${{Postgres.DATABASE_URL}}`. | `config\railway\staging.md` |
| P4-04 | Create sourceless app service shells. | Done | `litellm-proxy` (`335b0f28-2d4c-42b7-b3c9-063bcf296a25`) and `backup-worker` (`f1e6e49c-8320-4b30-a070-d59d285f520c`) exist. Earlier `cloudflared-tunnel` shell `ec0b7723-219f-4f54-8896-3ed010ed1e3d` is out of current scope and requires explicit operator approval before deletion. | `config\railway\staging.md`; `docs\runbooks\railway-project-service-setup.md` |
| P4-05 | Configure safe staging variables and service references. | Done | `litellm-proxy` has non-secret staging flags and `DATABASE_URL=${{Postgres.DATABASE_URL}}`; `backup-worker` has `LITELLM_DATABASE_URL=${{Postgres.DATABASE_URL}}`; no provider keys, LiteLLM master key, tunnel token, backup credentials, production secrets, or generated developer keys were set. | `config\railway\staging.md` |
| P4-06 | Configure non-secret future deployment settings. | Done | App service shells have Dockerfile paths configured for future source attachment. `litellm-proxy` has healthcheck path `/health/readiness` and timeout `300`. Source remains unattached. | `config\railway\staging.md`; `docs\runbooks\staging-deployment.md` |
| P4-07 | Add Phase 4 docs and runbooks. | Done | Staging config and runbooks document non-secret IDs, setup commands, shell-only boundary, safe variable references, public exposure closure, private-networking interpretation, and Phase 5 handoff. | `config\railway\staging.md`; `docs\runbooks\railway-project-service-setup.md`; `docs\runbooks\staging-deployment.md` |
| P4-08 | Validate and review implementation. | Done | Railway readback confirms app shells are sourceless, undeployed, and domainless; Postgres is `SUCCESS`. Local gates passed. GPT-5.5 and Opus 4.8 reviewed with no material blockers; optional README status polish was applied. | This file |

## Phase 4 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| Durable Railway project exists separately from disposable Phase 0. | Done | Project `dev-orbit-llm-gateway` exists separately from Phase 0 project `internal-llm-gateway-phase0`. |
| Persistent staging environment exists. | Done | Environment `staging` (`f188f687-8582-4308-9110-1d082dc31b89`) exists and is linked. |
| Managed Postgres exists for LiteLLM state. | Done | `Postgres` service is deployed, `SUCCESS`, one replica running, volume ready. |
| App service shells exist. | Done | `litellm-proxy` and `backup-worker` exist. The earlier `cloudflared-tunnel` sourceless shell is a blocked cleanup target requiring explicit operator approval before deletion. |
| No app service is publicly exposed. | Done | Service readback shows no URL for app services; environment config shows zero service/custom domains for app services. |
| No app service has source attached or deployment triggered. | Done | Service readback shows app service `source=null`, `deploymentId=null`, and `latestDeployment=null`. |
| Private-network wiring is configured without public DB URLs. | Done with Phase 4 interpretation | App services reference `${{Postgres.DATABASE_URL}}`. Live app-to-DB proof is deferred to Phase 5 because app services intentionally do not run in Phase 4. |
| Docs and runbooks are updated with non-secret evidence. | Done | `config\railway\staging.md`, `docs\runbooks\railway-project-service-setup.md`, and `docs\runbooks\staging-deployment.md` are updated. |
| Final validation and GPT/Opus review are complete. | Done | Local validation passed; GPT-5.5 and Opus 4.8 reviewed with no blockers. |

## Phase 6 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P6-01 | Review Phase 6 plan with GPT and Opus before implementation. | Done | GPT-5.4 and Opus 4.8 reviewed the plan. Feedback incorporated: Admin UI decision must be explicit, control-plane secrets must be rotated before public ingress, active baseline alerting is required before exposure, admin/control denial coverage must expand, and public validation must run after approved mutations. | Session `plan.md` |
| P6-02 | Reconcile Phase 5 before public ingress. | Done | `dev-search` passed targeted private validation with rotated staged Perplexity key and disposable validation key blocking. Public ingress remains blocked until exposed control-plane staging secrets are confirmed rotated. | `docs\operations\litellm-policy-validation.md` |
| P6-03 | Record Phase 6 public-origin and Admin UI decisions. | Done | Decisions recorded: Railway-generated public endpoint first, custom domain deferred, public `/health/readiness` accepted for staging, Admin UI enabled for private staging testing with sealed credentials while public exposure remains gated, generous configurable budget/rate defaults selected, Cloudflare/edge hardening removed from Phase 6 scope, and alerting deferred until public ingress or explicit risk exception. | `docs\decisions\public-origin-risk-acceptance.md`; `docs\security\litellm-native-auth-policy.md`; `docs\operations\public-origin-validation.md` |
| P6-04 | Add public-origin validation tooling. | Done | Phase 6 validator and skip-safe public-origin smoke tests were added and local validation passed for auth rejection, approved route proof, streaming, docs closure, admin/control denial families, redacted output, and safe response bodies. | `scripts\phase6-validate-public-origin.ps1`; `tests\smoke\test_public_origin_policy.py`; `.github\workflows\staging-smoke.yml` |
| P6-05 | Configure Railway-generated developer API endpoint. | Done | Railway-generated public endpoint created for staging `litellm-proxy`; literal host is kept out of tracked docs to satisfy repository secret/public-host scans. | `docs\operations\public-origin-validation.md` |
| P6-06 | Configure active baseline alerts. | Done | Operator explicitly deferred active alerting as a Phase 6 staging-proof risk exception. Revisit before production or broader pilot. | `docs\operations\public-origin-validation.md` |
| P6-07 | Validate public-origin native auth and route controls. | Done | Public checks passed: readiness public `200`, missing/invalid auth rejected, `dev-fast` chat passed, `dev-search` chat passed, `dev-embed` embeddings passed, developer key admin route denied, docs/ReDoc/OpenAPI blocked, Admin UI HTML loads at `/ui/`, and disposable validation key was blocked. | `scripts\phase6-validate-public-origin.ps1` |
| P6-08 | Update final Phase 6 evidence. | Done | Final Phase 6 evidence recorded with non-secret public endpoint and pass/fail summaries. | This file; `docs\operations\public-origin-validation.md` |

## Phase 6 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| Anonymous or missing-key request to `llm.thaarei.com` or staging equivalent is blocked. | Done | Missing auth returns `401` on the Railway-generated staging endpoint. |
| Invalid LiteLLM virtual key is blocked. | Done | Invalid auth returns `401` on the Railway-generated staging endpoint. |
| Valid LiteLLM virtual key succeeds on approved `/v1` routes. | Done | Disposable validation key succeeded on `dev-fast`, `dev-search`, and `dev-embed`, then was blocked. |
| Streaming completion works through the public LiteLLM endpoint. | Done | Public `dev-fast` streaming returned `200` and produced SSE data with a disposable validation key. |
| Admin UI is available only to approved admins/leads through an approved control. | Done | Admin UI loads at `/ui/` on the Railway-generated staging endpoint and is protected by sealed LiteLLM Admin UI credentials. |
| Developer virtual keys cannot access LiteLLM Admin UI or admin/control routes. | Done | Disposable developer key was denied on `/key/list`, `/user/info`, `/team/list`, `/config/list`, `/spend/logs`, and `/admin`. |
| Public docs/Swagger are disabled or explicitly protected. | Done | `/docs`, `/redoc`, and `/openapi.json` are blocked on the public endpoint. |

## Phase 7 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P7-01 | Review Phase 7 plan with GPT and Opus before implementation. | Done | GPT-5.5 and Opus 4.8 reviewed the plan. Feedback incorporated: same-project Railway Object Storage is staging-only, backup-failure alerting needs push visibility, backup encryption material must be escrowed, daily/weekly/monthly logical retention must be explicit, native snapshot restore must be validated or documented, and RPO/RTO must be measured. | Session `plan.md` |
| P7-02 | Harden backup-worker logical backup and restore scripts. | Done | Scripts create compressed custom-format encrypted dumps, upload non-secret checksum manifests, emit metadata-only JSON logs, support backup tiers, and support restore into a fresh database through guarded `RESTORE_DATABASE_URL` plus `RESTORE_TARGET_CONFIRMED=fresh-restore-drill`. Local shell syntax, policy lint, secret scan without Gitleaks, smoke collection, and GPT/Opus review passed. | `services\backup-worker\scripts\backup-postgres.sh`; `services\backup-worker\scripts\restore-check.sh` |
| P7-03 | Add Phase 7 backup, restore, alert, rotation, outage, rollback, and leakage runbooks. | Done | Required runbook files were added, the runbook index updated, revoked-key reconciliation documented, and local policy/secret/smoke validation passed. | `docs\runbooks\*.md` |
| P7-04 | Create staging backup object-storage target. | Done | Railway Object Storage bucket `litellm-staging-backups` (`644dfb0b-9b67-4c46-aaf7-a416bf4db1af`) exists in staging region `sin`; object count is `8` after fresh-key validation and final daily-cron readback. backup-worker has rclone destination/config variables and uses `RCLONE_CONFIG_BACKUP_URL_STYLE=path`. Same-project storage remains staging-only; production remains blocked until external/cross-account storage or risk acceptance exists. | `docs\runbooks\off-platform-logical-backup-restore.md` |
| P7-05 | Deploy scheduled backup-worker. | Done | backup-worker deployed successfully with a Postgres 18 `pg_dump` image and no public URL. After bucket credential rotation and a fresh operator-escrowed backup key, encrypted logical backups uploaded successfully, metadata-only logs were emitted, and cron was restored to `30 18 * * *`. Latest readback showed deployment `49768015-83e6-4fb9-80a9-049ceefc7c57` as `SUCCESS`, with no public URL and no running replica between cron invocations. | `services\backup-worker\README.md`; `services\backup-worker\Dockerfile` |
| P7-06 | Configure Railway native Postgres backups. | Blocked | Requires Railway backup schedule/readback mutation or dashboard/API evidence. | `docs\runbooks\railway-backup-restore.md` |
| P7-07 | Prove backup and restore drill. | In progress | Fresh-key logical backup validation passed: `backup_uploaded` logged artifact `litellm-postgres-20260606T171804Z-daily.dump.enc` with encrypted SHA-256 `f831b67877b303a60d42dbdd3e1a89a9dda3fba4428cec92eb74accece0615127` and encrypted size `241120` bytes; archive-list `restore_check_passed` logged against validation artifact `litellm-postgres-20260606T171903Z-daily.dump.enc`. Fresh restore-drill Postgres service and disposable LiteLLM restored-database validation are deferred by staging exception and remain production blockers. | `docs\runbooks\off-platform-logical-backup-restore.md`; `docs\runbooks\litellm-postgres-outage.md`; `docs\decisions\phase-7-staging-risk-exception.md` |
| P7-08 | Configure alerts and manual staging review cadence. | Blocked | Manual spend/error review is documented, but backup-failure push visibility still requires a dead-man success ping, Railway cron-failure notification, or equivalent sealed configuration. | `docs\runbooks\budget-spend-alert-response.md` |
| P7-09 | Validate and review Phase 7 before marking done. | Blocked | Repository-side validation and GPT/Opus review passed. Railway readbacks, restore drill evidence, RPO/RTO measurement, and backup-failure alert evidence remain blocked until approved infrastructure mutations and sealed credentials exist. | This file |

## Phase 7 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| Backup job succeeds in staging. | Done | Fresh operator-escrowed `BACKUP_ENCRYPTION_KEY` is set as a sealed backup-worker variable; encrypted backup upload succeeded with metadata-only logs and bucket object count `8`. Daily cron restored to `30 18 * * *`. |
| Restore drill succeeds into a fresh staging database. | Blocked | Deferred by `docs\decisions\phase-7-staging-risk-exception.md` for Phase 8 staging only; production remains blocked until encrypted artifact restore, fresh restore-drill Postgres service, and restore execution are proven. |
| Restored database supports LiteLLM virtual-key auth. | Blocked | Deferred by staging exception for Phase 8 only; production remains blocked until disposable LiteLLM validation against restored database or a controlled maintenance-window repoint is proven. |
| Revoked-key reconciliation procedure is documented. | Done | Procedure is documented in `docs\runbooks\litellm-virtual-key-revocation.md`; concrete ledger location/evidence must still be recorded during the restore drill. |
| RPO/RTO are documented. | Blocked | Deferred by staging exception for Phase 8 only; production remains blocked until measured restore drill and confirmed schedules exist. |
| Budget/error/backup alerts are configured. | Blocked | Manual spend/error checks are documented; push-style backup-failure alert configuration is deferred by staging exception and remains a production blocker. |
| Production cutover/rollback runbook draft exists. | Done | `docs\runbooks\railway-deploy-rollback.md` exists as a draft; production-specific IDs/domains remain intentionally deferred until production exists. |

## Phase 8 task tracker

| ID | Roadmap item | Status | Evidence / blocker | Artifact |
| --- | --- | --- | --- | --- |
| P8-01 | Review Phase 8 plan with GPT-5.5 and Opus 4.8 before implementation. | Done | GPT-5.5 planning pass completed in-session; Opus 4.8 review completed on 2026-06-07 and guardrails were incorporated before implementation. | Session `plan.md` |
| P8-02 | Record Phase 7 staging-only risk exception. | Done | Operator accepted moving remaining Phase 7 DR/alert blockers to a final pre-production gate for staging Phase 8 progress only. | `docs\decisions\phase-7-staging-risk-exception.md` |
| P8-03 | Add staging proof-gate checklist. | Done | Checklist separates public-path evidence, needs-run checks, and staging-only deferred production blockers. | `docs\operations\staging-proof-gates.md` |
| P8-04 | Add supported developer-tool setup guidance. | Done | Setup doc defines required capabilities, evidence template, and blocked-tool rules without marking named tools supported prematurely. | `docs\onboarding\supported-developer-tool-setup.md`; `docs\onboarding\supported-tools-matrix.md` |
| P8-05 | Add production readiness review draft. | Done | Draft records no-Cloudflare current path, staging risk exceptions, and production blockers. | `docs\decisions\production-readiness-review.md` |
| P8-06 | Run public staging smoke gates. | Blocked | Requires operator-provided staging public base URL and disposable LiteLLM virtual key. No new key creation is approved. | `docs\operations\staging-proof-gates.md`; `scripts\phase6-validate-public-origin.ps1` |
| P8-07 | Validate named developer tools. | Blocked | Requires live Continue.dev, Cline/Roo-style, Aider/equivalent, OpenAI SDK, or Copilot CLI BYOK-compatible runs. Raw HTTP validation script is the only supported baseline so far. | `docs\onboarding\supported-developer-tool-setup.md`; `docs\onboarding\supported-tools-matrix.md` |
| P8-08 | Final Phase 8 review and status update. | In progress | Repository-side Phase 8 artifacts validated: public-origin validator `-ValidateOnly`, LiteLLM/config lint, secret scanning with Gitleaks, smoke collection, and smoke tests passed locally. Phase 8 cannot be fully Done until mandatory runtime gates are passed or separately accepted with production-grade exceptions. | This file |

## Phase 8 exit criteria tracker

| Exit criterion | Status | Evidence / blocker |
| --- | --- | --- |
| All mandatory smoke tests pass. | In progress | Several public-path checks were previously validated in Phase 6. Budget, fallback, no-downgrade, cache-off runtime proof, log sentinel, provider rotation, restore drill, restored auth, RPO/RTO, and backup-failure push alerting are not fully passed. |
| At least one primary developer tool works end-to-end with LiteLLM-native auth. | Blocked | Raw HTTP validation script works, but named developer tools remain untested. |
| Blocked tools are documented and excluded from launch. | In progress | Blocked-tool rules are documented; concrete tool statuses require live validation. |
| Risk exceptions have owner, expiry, budget limits, rate limits, and monitoring. | Done | Phase 7 staging risk exception records owner, scope, expiry/review, budget/rate-limit constraints, monitoring, and production gate. |
| Product approval gates are ready for production creation. | Blocked | Production remains blocked by deferred Phase 7 DR/alerting items and incomplete named tool validation. |

## Latest Phase 0 technical validation

Validated on 2026-06-06 without printing secrets:

| Check | Result |
| --- | --- |
| Railway linked project | `internal-llm-gateway-phase0` in workspace `muthurema's Projects` |
| `litellm-proxy` deployment | `2cba1ae5-6bb6-4043-8630-d389c1861ae4`, `SUCCESS` |
| Postgres deployment | `def888c5-4d59-45e2-a496-ce7575dce6c0`, `SUCCESS`, instance `RUNNING`, volume `READY` |
| Readiness endpoint | `200`, `{"status":"healthy","db":"connected"}` |
| Docs/Swagger | `/docs` and `/redoc` return `404` |
| Missing key | `/v1/chat/completions` returns `401` |
| Invalid key | `/v1/chat/completions` returns `401` |
| Virtual-key generation | `200`; temporary key has `models=["dev-fast"]`, `max_budget=0.05`, `rpm_limit=10` |
| Developer-key admin denial | `/key/list` returns `403` |
| OpenAI direct key validity | `/v1/models` previously returned `200`; credited key now also succeeds through LiteLLM chat and streaming |
| LiteLLM model exposure | `/v1/models` returns only `dev-fast`; no provider key, database URL, or secret marker found |
| Phase 0 env presence | `LITELLM_MASTER_KEY`, `OPENAI_API_KEY`, `UI_PASSWORD`, and `DATABASE_URL` are present in Railway runtime; `NO_DOCS=True`, `NO_REDOC=True`, `ENVIRONMENT=phase0`, `PORT=4000` |
| Prompt sentinel logs | `phase0_no_log_sentinel_20260606` not found in latest 500 LiteLLM logs |
| Valid developer key can call approved alias | Done; credited OpenAI-backed chat through LiteLLM returned `200` |
| Valid developer key can stream chat completion | Done; credited OpenAI-backed streaming through LiteLLM returned `200` with stream chunks received |
| Disposable project deletion | Done; Railway accepted deletion for `internal-llm-gateway-phase0`; readback shows `deletedAt=2026-06-08T06:40:12.528Z` |
