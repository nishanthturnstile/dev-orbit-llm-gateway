# LiteLLM policy

`services\litellm\config.yaml` is the runtime source of truth for model routing. Files in `config\litellm` are policy metadata and validation inputs; they must not become a second runtime `model_list`.

## Alias policy

The Phase 2 runtime config defines these aliases:

| Alias | Purpose | Validation status |
| --- | --- | --- |
| `dev-fast` | Low-latency general development use. | Validated in Phase 0 with OpenAI `gpt-4o-mini`. |
| `dev-code` | Code-focused development assistance. | Requires model availability validation before staging deployment. |
| `dev-reasoning` | Reasoning tasks with higher latency tolerance. | Requires model availability and timeout validation before staging deployment. |
| `dev-long-context` | Long-context analysis. | Requires model availability and context validation before staging deployment. |
| `batch-analysis` | Non-interactive analysis jobs. | Requires budget and batch-use validation before staging deployment. |
| `dev-search` | Search-augmented answers. | Requires approved Perplexity credentials before deployment or use. |
| `dev-embed` | Embedding workflows. | Requires embedding route validation before staging deployment. |
| `dev-vision` | Chat completions with image input. | Requires vision route validation before staging deployment. |

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

A later phase may add same-tier fallbacks only after the fallback provider/model is credited, approved, and validated. Any fallback added before deployment must be validated in Phase 5.

## Health details

LiteLLM `/health/readiness` is the readiness endpoint for Railway deployment checks. `/health` can call providers and should not be used as the Railway deployment health check.

Detailed health/provider output must not be broadly exposed. Phase 2 does not rely on unverified LiteLLM config keys for health-detail hiding; later runtime validation must confirm the exact supported control before production exposure.
