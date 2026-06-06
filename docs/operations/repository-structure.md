# Repository structure

**Status:** Phase 2 repository structure
**Related roadmap phase:** Phase 2 - Local service scaffolding and policy/config authoring

## Current structure after Phase 2

```text
.
|-- README.md
|-- .env.example
|-- .gitignore
|-- AGENTS.md
|-- config
|   |-- cloudflare
|   |   `-- README.md
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
|-- services
|   |-- backup-worker
|   |   |-- Dockerfile
|   |   |-- README.md
|   |   `-- scripts
|   |       |-- backup-postgres.sh
|   |       `-- restore-check.sh
|   |-- cloudflared-tunnel
|   |   |-- Dockerfile
|   |   |-- README.md
|   |   `-- config.example.yml
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
        |-- test_cloudflare_block.py
        |-- test_no_prompt_log_leak.py
        `-- test_streaming.py
```

This is a Phase 2 local scaffold and policy baseline, not a deployed staging stack.

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
- Deferred Cloudflare tunnel scaffold.
- Backup worker scaffold.
- Smoke test skeletons.
- Local validation, provider config, model alias, and fallback-deferral docs.

Phase 2 does not add CI workflows, durable Railway staging, production services, or virtual-key automation.

## Deferred directories

The following directories must remain absent unless a later approved decision introduces them:

- `apps\admin-web`
- `services\admin-api`
- `services\llm-edge`

## Checkout hygiene

Every directory intended to exist after Phase 2 contains a tracked README, script, config, test, or `.gitkeep`, because Git does not preserve empty directories. A fresh checkout should include the documented repository homes without requiring local generated files.

## Official-doc references applied

- LiteLLM config should use `os.environ/VAR_NAME` for secrets.
- LiteLLM virtual keys and spend tracking require Postgres and a master key.
- LiteLLM `/health/readiness` is appropriate for deployment readiness; `/health` probes providers.
- Railway variables should hold sealed secrets and service references, not committed values.
- Railway detects service Dockerfiles by name/path and supports config-as-code in later phases.
- Future GitHub Actions should use least privilege, masking, safe expression handling, and pinned third-party actions.
