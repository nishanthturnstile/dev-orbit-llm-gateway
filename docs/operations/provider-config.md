# Provider configuration

Provider credentials must be configured as Railway variables, sealed where applicable, and referenced from LiteLLM config using `os.environ/VAR_NAME`.

## Runtime variables

| Variable | Used by | Purpose |
| --- | --- | --- |
| `OPENAI_API_KEY` | `litellm-proxy` | OpenAI-backed aliases including `dev-fast`. |
| `PERPLEXITY_API_KEY` | `litellm-proxy` | `dev-search`; required before that alias is deployed or used. |
| `LITELLM_MASTER_KEY` | `litellm-proxy` | LiteLLM admin/master key. Must start with `sk-` but must never be committed. |
| `DATABASE_URL` | `litellm-proxy` | Railway managed Postgres service reference for LiteLLM state. |
| `LITELLM_DATABASE_URL` | `backup-worker` | Backup-worker reference to the same LiteLLM Postgres instance. |

`DATABASE_URL` and `LITELLM_DATABASE_URL` intentionally have different names because they are injected into different services. They must point to the same `litellm-postgres` database when backup-worker is deployed.

## Validation gates before staging

- Verify each configured OpenAI model is available to the credited OpenAI account.
- Add and validate Perplexity credentials before using `dev-search`.
- Validate embeddings before marking `dev-embed` supported.
- Validate vision input before marking `dev-vision` supported.
- Do not add same-tier fallbacks until fallback candidates are approved and tested.

No provider key, generated virtual key, database URL, Redis URL, private host, or backup credential belongs in repository files.
