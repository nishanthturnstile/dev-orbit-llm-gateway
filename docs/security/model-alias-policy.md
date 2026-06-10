# Model alias policy

The runtime source of truth for aliases is `services\litellm\config.yaml`. `config\litellm\model-aliases.yaml` is metadata used by validation and documentation.

## Approved aliases

| Alias | Access | Runtime status |
| --- | --- | --- |
| `dev-fast` | Default | Fireworks AI `gpt-oss-120b`; requires runtime validation. |
| `dev-code` | Default | Fireworks AI `kimi-k2p6`; default coding alias, requires runtime validation. |
| `dev-long-horizon` | Default | Fireworks AI `glm-5p1`; requires runtime validation. |
| `dev-reasoning` | Default | Fireworks AI `minimax-m2p7`; requires runtime validation. |
| `dev-search` | Default | Perplexity `sonar`; requires approved credentials and runtime validation. |
| `dev-embed` | Default | OpenAI embedding route; requires embedding validation. |
| `dev-vision` | Default | Existing approved vision route; requires chat-with-image validation. |
| `premium-code` | Restricted | OpenAI `gpt-5.4`; requires lead/admin approval and runtime validation. |
| `premium-planning` | Restricted | Anthropic `claude-sonnet-4-6`; requires lead/admin approval and runtime validation. |
| `ultra-premium-code` | Tightly restricted | OpenAI `gpt-5.5`; requires explicit operator approval and runtime validation. |
| `ultra-premium-planning` | Tightly restricted | Anthropic `claude-opus-4-8`; requires explicit operator approval and runtime validation. |

`batch-analysis`, `docs-qa`, and `dev-long-context` are intentionally absent. Documentation and clarifying-question work should use `dev-code` by default, then escalate to `premium-planning` only when needed.

## Forbidden aliases

`sensitive-code` and all `sensitive-*` aliases are forbidden until a separate security review approves them.

## Fallbacks

The runtime config defines no fallbacks. This satisfies the same-tier-only rule by omission. Same-tier fallbacks may be added later only after explicit provider/model validation, and must be validated again before production. Premium and ultra-premium aliases must never fall back to regular/default-tier models.

## Logging and cache

Raw prompt/response logging remains disabled by default. Response caching remains default-off for code prompts.
