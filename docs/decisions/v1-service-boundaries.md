# V1 service boundaries

**Status:** Phase 1 boundary decision
**Related architecture:** `docs\internal-llm-gateway-architecture-tech-stack.md`
**Related roadmap:** `docs\internal-llm-gateway-implementation-roadmap.md`

## V1 services

| Component | Boundary | Phase 1 decision |
| --- | --- | --- |
| `litellm-proxy` | Railway app service running LiteLLM Proxy OSS and built-in Admin UI | Included in v1. Existing Dockerfile is a Phase 0 proof artifact; Phase 2 owns hardened config/scaffold work. |
| `litellm-postgres` | Railway managed Postgres | Included in v1 as platform-managed state for LiteLLM users, teams, virtual keys, budgets, and spend. Not represented as a repo service directory. |
| `backup-worker` | Future scheduled app service | Required before production for off-platform logical backups, but code and scripts are deferred to later phases. |
| `cloudflared-tunnel` | Optional hardening service | Deferred unless public-origin risk, SSO, WAF, or origin-guard requirements justify it. |
| `litellm-redis` | Railway managed Redis | Deferred unless multiple LiteLLM replicas, distributed rate limiting, or shared cache state are required. |

## Explicitly deferred

Do not create these components without a later approved design decision:

- `apps\admin-web`
- `services\admin-api`
- `services\llm-edge`
- A custom admin database
- A custom LLM router
- Redis-backed multi-replica LiteLLM deployment

## Security boundaries

Clients and browser code must never receive:

- Provider keys.
- LiteLLM master/admin keys.
- Generated developer virtual keys except through the approved secure handoff process.
- Railway variables.
- Database URLs.
- Redis URLs.
- Backup credentials.
- Private Railway or internal hostnames.
- Stack traces, SQL, or private operational error details.

LiteLLM remains the v1 source of truth for virtual keys, model aliases, budgets, spend, users, teams, and provider routing. No custom Phase 1 artifact should become a second policy source.

## Runtime config source of truth

Phase 2 moved the local LiteLLM runtime config source of truth to `services\litellm\config.yaml` and updated the Dockerfile copy path at the same time. The former `config\litellm\config.yaml` Phase 0 proof file was removed locally to avoid two active configs.
