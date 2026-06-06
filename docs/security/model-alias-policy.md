# Model alias policy

The runtime source of truth for aliases is `services\litellm\config.yaml`. `config\litellm\model-aliases.yaml` is metadata used by validation and documentation.

## Required aliases

| Alias | Tier | Runtime status |
| --- | --- | --- |
| `dev-fast` | fast | Validated in Phase 0 with OpenAI `gpt-4o-mini`. |
| `dev-code` | code | Requires model availability validation before staging. |
| `dev-reasoning` | reasoning | Requires model availability and timeout validation before staging. |
| `dev-long-context` | long-context | Requires model availability and context validation before staging. |
| `batch-analysis` | batch | Requires budget and batch-use validation before staging. |
| `dev-search` | search | Requires approved Perplexity credentials before deployment or use. |
| `dev-embed` | embedding | Requires embedding route validation before staging. |
| `dev-vision` | vision | Requires chat-with-image validation before staging. |

## Forbidden aliases

`sensitive-code` and all `sensitive-*` aliases are forbidden until a separate security review approves them.

## Fallbacks

Phase 2 defines no fallbacks. This satisfies the same-tier-only rule by omission. Same-tier fallbacks may be added later only after explicit provider/model validation, and must be validated again before production.

## Logging and cache

Raw prompt/response logging remains disabled by default. Response caching remains default-off for code prompts.
