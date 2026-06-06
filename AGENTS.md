# Agent instructions

This repository implements the Internal LLM Gateway plan. Before changing files or Railway resources, read:

- `docs\internal-llm-gateway-implementation-roadmap.md`
- `docs\internal-llm-gateway-architecture-tech-stack.md`
- `docs\internal-llm-gateway-product-plan.md`
- `docs\operations\implementation-status.md`

## Phase workflow

- Keep `docs\operations\implementation-status.md` current before and after each phase task.
- Use the status values `Not started`, `In progress`, `Blocked`, and `Done`.
- Do not advance to the next phase until the current phase exit criteria in the roadmap are met and the tracker is updated with evidence.
- Review any non-trivial phase plan with a second model before implementation.
- Preserve the implementation roadmap as the source of truth for phase order, dependencies, deliverables, and exit criteria.

## Railway and secret rules

- Phase 0 proof resources are disposable only and must never be promoted to staging or production.
- Do not create, deploy, mutate, or delete Railway, Cloudflare, provider, database, or tunnel resources without explicit operator approval for the exact action.
- Read-only Railway validation may use CLI commands such as `railway whoami --json`, `railway status --json`, `railway service list --json`, and bounded status/log commands.
- Never commit or print provider keys, LiteLLM keys, Cloudflare secrets, Railway variables, database URLs, Redis URLs, private hostnames, generated virtual keys, raw prompts/responses, stack traces, SQL, or backup credentials.
- The current approved direction is LiteLLM-native authentication on a public Railway/custom domain. Do not expose the service until LiteLLM virtual-key auth, admin controls, budgets, rate limits, metadata-only logging, and secret handling are configured.
- Treat Cloudflare Tunnel/Zero Trust as optional future hardening, not the Phase 0 default.
- Use `/health/readiness` for Railway deployment health checks; never use `/health` as the Railway deployment health check.
