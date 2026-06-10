# LiteLLM policy

`services\litellm\config.yaml` is the runtime source of truth for model routing. Files in `config\litellm` are policy metadata and validation inputs; they must not become a second runtime `model_list`.

## Alias policy

The approved runtime config defines these developer-facing aliases:

| Alias | Access | Purpose | Validation status |
| --- | --- | --- | --- |
| `dev-fast` | Default | Fast, low-cost questions, small snippets, and quick iteration. | Requires Fireworks AI runtime validation. |
| `dev-code` | Default | Default coding model. Use when unsure. | Requires Fireworks AI runtime validation. |
| `dev-long-horizon` | Default | Long-running agent loops, large refactors, and multi-step engineering tasks. | Requires Fireworks AI runtime validation. |
| `dev-reasoning` | Default | Planning, complex reasoning, and tool-heavy productivity tasks. | Requires Fireworks AI runtime validation. |
| `dev-search` | Default | Search-augmented answers. | Requires approved Perplexity credentials and runtime validation. |
| `dev-embed` | Default | Embedding workflows. | Requires embedding route validation. |
| `dev-vision` | Default | Chat completions with image input. | Requires vision route validation. |
| `premium-code` | Restricted | Hard coding and debugging when `dev-code` is insufficient. | Requires OpenAI premium model validation. |
| `premium-planning` | Restricted | High-quality planning, review, and clarification. | Requires Anthropic premium model validation. |
| `ultra-premium-code` | Tightly restricted | Highest-value coding and debugging only. | Requires explicit operator approval and validation. |
| `ultra-premium-planning` | Tightly restricted | Highest-value architecture, planning, and second-model review only. | Requires explicit operator approval and validation. |

`batch-analysis`, `docs-qa`, and `dev-long-context` are intentionally absent. Documentation and clarification work should use `dev-code` by default and escalate to `premium-planning` only when needed.

`sensitive-code` and all `sensitive-*` aliases are forbidden until a separate security review approves them.

## Secret and logging rules

- Provider credentials must use `os.environ/VAR_NAME` references.
- Provider credentials must live in Railway variables, sealed where applicable.
- The LiteLLM master key must use `os.environ/LITELLM_MASTER_KEY`.
- The LiteLLM database URL must use `os.environ/DATABASE_URL`.
- Raw prompt and response logging stays disabled by default.
- User and key information should be redacted where LiteLLM supports it.
- Response caching stays default-off for code prompts.
- Runtime config must not include provider keys, generated virtual keys, database URLs, Redis URLs, public Railway proof URLs, private hostnames, or backup credentials.

## Fallback policy

Phase 2 intentionally defines no fallbacks. Zero fallbacks is stricter than, and therefore compliant with, the roadmap rule that fallbacks must be same-tier only.

A later phase may add same-tier fallbacks only after the fallback provider/model is credited, approved, and validated. Premium and ultra-premium aliases must never fall back to regular/default-tier models. Any fallback added before deployment must be validated in Phase 5.

## Health details

LiteLLM `/health/readiness` is the readiness endpoint for Railway deployment checks. `/health` can call providers and should not be used as the Railway deployment health check.

Detailed health/provider output must not be broadly exposed. Phase 2 does not rely on unverified LiteLLM config keys for health-detail hiding; later runtime validation must confirm the exact supported control before production exposure.
