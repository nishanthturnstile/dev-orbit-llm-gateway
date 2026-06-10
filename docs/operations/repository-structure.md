# Repository structure

**Status:** Current repository structure after Cloudflare tunnel cleanup
**Related roadmap phase:** Phase 8 planning direction correction

## Current structure after Phase 3

```text
.
|-- README.md
|-- .env.example
|-- .gitattributes
|-- .gitignore
|-- .gitleaks.toml
|-- AGENTS.md
|-- requirements-ci.txt
|-- .github
|   |-- dependabot.yml
|   `-- workflows
|       |-- ci.yml
|       |-- image-policy.yml
|       `-- staging-smoke.yml
|-- config
|   |-- litellm
|   |   |-- README.md
|   |   |-- model-aliases.yaml
|   |   |-- policy.md
|   |   `-- provider-denylist.yaml
|   `-- railway
|       |-- README.md
|       |-- production.md
|       `-- staging.md
|-- docs
|   |-- decisions
|   |-- onboarding
|   |-- operations
|   |-- runbooks
|   `-- security
|-- scripts
|   |-- check-secrets.ps1
|   |-- lint-litellm-config.ps1
|   |-- smoke-railway.ps1
|   |-- validate-litellm-config.py
|-- services
|   |-- backup-worker
|   |   |-- Dockerfile
|   |   |-- README.md
|   |   `-- scripts
|   |       |-- backup-postgres.sh
|   |       `-- restore-check.sh
|   `-- litellm
|       |-- Dockerfile
|       |-- README.md
|       |-- config.yaml
|       `-- scripts
|           `-- verify-config.sh
`-- tests
    |-- fixtures
    `-- smoke
        |-- test_budget_block.py
        |-- test_chat_completion.py
        |-- test_no_prompt_log_leak.py
        `-- test_streaming.py
```

This repository now reflects the LiteLLM-native public Railway/custom endpoint path. Cloudflare Tunnel/Access/WAF and edge-origin scaffolds are not part of the current implementation.

## Active runtime config

`services\litellm\config.yaml` is the LiteLLM runtime source of truth. `services\litellm\Dockerfile` copies this file to `/app/config.yaml`.

The old `config\litellm\config.yaml` Phase 0 proof file was removed to avoid two active configs. `config\litellm` now contains policy metadata and validation inputs only.

## Existing Phase 0 artifacts

- `scripts\phase0-*.ps1` are retained as Phase 0 validation/operations scripts.
- The deployed Phase 0 Railway proof is not mutated by the local Phase 2 config path move.

## Phase 2 additions

Phase 2 adds:

- LiteLLM runtime config and verifier.
- LiteLLM alias, denylist, and policy metadata.
- Backup worker scaffold.
- Smoke test skeletons.
- Local validation, provider config, model alias, and fallback-deferral docs.

Phase 2 does not add CI workflows, durable Railway staging, production services, or virtual-key automation.

## Phase 3 additions

Phase 3 adds:

- Read-only GitHub Actions policy workflows.
- Gitleaks working-tree secret scanning config.
- Cross-platform LiteLLM config linting.
- Image pinning checks.
- Validate-only staging smoke workflow skeleton.
- CI policy and secret-scanning docs.

Phase 3 does not add durable Railway staging, production services, repository settings mutation, provider validation, or real smoke-test endpoint calls.

## Phase 8 direction correction

Phase 8 planning removed the active Cloudflare tunnel scaffold from the repository path. Historical status/evidence can still mention earlier Cloudflare scaffold work, and defensive secret-scanning rules remain, but current implementation docs should not require a Cloudflare tunnel, Cloudflare Access/WAF, or `llm-edge` service.

## Deferred directories

The following directories must remain absent unless a later approved decision introduces them:

- `apps\admin-web`
- `services\admin-api`
- `services\llm-edge`

## Checkout hygiene

Every directory intended to exist after Phase 3 contains a tracked README, script, config, workflow, test, or `.gitkeep`, because Git does not preserve empty directories. A fresh checkout should include the documented repository homes without requiring local generated files.

## Official-doc references applied

- LiteLLM config should use `os.environ/VAR_NAME` for secrets.
- LiteLLM virtual keys and spend tracking require Postgres and a master key.
- LiteLLM `/health/readiness` is appropriate for deployment readiness; `/health` probes providers.
- Railway variables should hold sealed secrets and service references, not committed values.
- Railway Phase 4 created durable staging service shells. Future source attachment must keep repository root as build context because service Dockerfiles use repository-root-relative `COPY` paths.
- Railway detects service Dockerfiles by name/path and supports config-as-code in later phases.
- GitHub Actions use least privilege, no secrets for Phase 3 gates, safe expression handling, `persist-credentials: false`, and full-SHA-pinned actions.
