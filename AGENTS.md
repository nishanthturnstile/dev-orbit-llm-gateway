# Agent instructions

Internal LLM Gateway is a Railway-hosted, LiteLLM-first OpenAI-compatible gateway for controlled developer access to approved LLM providers. See `README.md` for the overview. Work is delivered in numbered phases; the implementation roadmap is the source of truth for phase order, deliverables, and exit criteria.

Before changing files or Railway resources, read:

- `docs\internal-llm-gateway-implementation-roadmap.md`
- `docs\internal-llm-gateway-architecture-tech-stack.md`
- `docs\internal-llm-gateway-product-plan.md`
- `docs\operations\implementation-status.md`

## Validate changes locally

There is no application build. Changes are gated by policy/config validators and smoke tests using Python 3.11, PowerShell (`pwsh`), and `bash`. Run from the repository root before opening any change that touches config, scripts, workflows, Dockerfiles, or operational docs:

```powershell
python -m pip install -r requirements-ci.txt
pwsh -NoProfile -File scripts\lint-litellm-config.ps1
pwsh -NoProfile -File scripts\check-secrets.ps1
bash services/litellm/scripts/verify-config.sh
python scripts\validate-litellm-config.py
python -m pytest tests\smoke --collect-only -q
python -m pytest tests\smoke -q
```

`check-secrets.ps1` needs a local `gitleaks` binary or Docker. GitHub Actions runs the same gates; see `docs\operations\ci-policy-gates.md`.

## Config and conventions

- LiteLLM policy source of truth: `services\litellm\config.yaml`, `config\litellm\model-aliases.yaml`, and `config\litellm\provider-denylist.yaml`. `scripts\validate-litellm-config.py` is the shared validator; the PowerShell and shell scripts call it rather than duplicating policy logic.
- All service Dockerfiles must use digest-pinned base images (`:latest` and unpinned tags are forbidden); pin every GitHub Actions `uses:` to a full commit SHA.
- Use `.env.example` for variable names and placeholder shapes only.
- Do not add `apps\admin-web`, `services\admin-api`, `services\llm-edge`, Redis, or Cloudflare tunnel/edge artifacts without an approved later-phase decision.

## Phase workflow

- Keep `docs\operations\implementation-status.md` current before and after each phase task.
- Use the status values `Not started`, `In progress`, `Blocked`, and `Done`.
- Do not advance to the next phase until the current phase exit criteria in the roadmap are met and the tracker is updated with evidence.
- Review any non-trivial phase plan with a second model before implementation.
- Preserve the implementation roadmap as the source of truth for phase order, dependencies, deliverables, and exit criteria.

## Railway and secret rules

- Do not create, deploy, mutate, or delete Railway, Cloudflare, provider, database, or tunnel resources without explicit operator approval for the exact action. Treat any disposable proof/spike resources as throwaway; never promote them to staging or production.
- Read-only Railway validation may use CLI commands such as `railway whoami --json`, `railway status --json`, `railway service list --json`, and bounded status/log commands.
- Never commit or print provider keys, LiteLLM keys, Cloudflare secrets, Railway variables, database URLs, Redis URLs, private hostnames, generated virtual keys, raw prompts/responses, stack traces, SQL, or backup credentials.
- The current approved direction is LiteLLM-native authentication on a public Railway/custom domain. Do not expose the service until LiteLLM virtual-key auth, admin controls, budgets, rate limits, metadata-only logging, and secret handling are configured.
- Cloudflare Tunnel/Access/WAF and edge-origin services are not part of the current implementation path; do not reintroduce them without an approved decision.
- Use `/health/readiness` for Railway deployment health checks; never use `/health` as the Railway deployment health check.
