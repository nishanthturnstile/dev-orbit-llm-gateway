# Internal LLM Gateway

Internal LLM Gateway is a Railway-hosted, LiteLLM-first gateway for controlled developer access to approved LLM providers through an OpenAI-compatible API.

The gateway keeps provider credentials, LiteLLM master/admin keys, database URLs, budgets, model routing, and operational controls server-side. Developers use LiteLLM virtual keys against approved model aliases; admins use LiteLLM's built-in Admin UI for v1 operations.

## Production target

- Platform: Railway.
- Gateway: LiteLLM Proxy OSS.
- State: Railway managed Postgres for LiteLLM users, teams, virtual keys, budgets, and spend.
- Public access model: Railway public/custom domain protected by LiteLLM-native authentication, budgets, rate limits, metadata-only logging, and admin controls.

Cloudflare Tunnel/Access/WAF, Redis, a custom admin API, and a custom admin web app are deferred unless later approved.

## Services

| Service | Status | Purpose |
| --- | --- | --- |
| `services\litellm` | Phase 2 local scaffold | LiteLLM proxy image/config home. `services\litellm\config.yaml` is the runtime config source of truth. |
| Railway managed Postgres | Platform service, not a repo directory | Persistent LiteLLM state. |
| `services\backup-worker` | Phase 2 local scaffold | Future off-platform logical backup worker before production. |
| `services\cloudflared-tunnel` | Deferred Phase 2 scaffold | Optional future hardening if public-origin risk requires it. |

Do not add `apps\admin-web`, `services\admin-api`, `services\llm-edge`, Redis, or custom admin database artifacts without an approved later-phase decision.

## Local development approach

Phase 2 establishes local service scaffolds, LiteLLM config, validation scripts, policy metadata, and smoke test skeletons. CI gates, durable Railway staging, and production deployment are owned by later phases in the roadmap.

Use `.env.example` for variable names and placeholder shapes only. Real provider keys, LiteLLM keys, generated virtual keys, Railway variables, database URLs, Redis URLs, backup credentials, and private hostnames must stay out of the repository.

## Deployment model

Durable Railway staging and production deployment are later phases. No Railway, provider, Cloudflare, database, tunnel, or domain resources should be created or mutated from Phase 2 local scaffold work.

When deployment phases begin, LiteLLM should use `/health/readiness` for Railway deployment health checks. Do not use `/health` as a deployment health check because LiteLLM documents it as a provider-probing endpoint.

## Source documents

- Product plan: `docs\internal-llm-gateway-product-plan.md`
- Architecture and tech stack: `docs\internal-llm-gateway-architecture-tech-stack.md`
- Implementation roadmap: `docs\internal-llm-gateway-implementation-roadmap.md`
- Implementation status: `docs\operations\implementation-status.md`
- Service boundaries: `docs\decisions\v1-service-boundaries.md`
- Repository structure: `docs\operations\repository-structure.md`
- Local config validation: `docs\operations\local-config-validation.md`
- Model alias policy: `docs\security\model-alias-policy.md`
