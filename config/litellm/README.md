# LiteLLM config

This directory contains LiteLLM policy metadata and validation inputs.

The Phase 2 runtime source of truth is `services\litellm\config.yaml`.

Files in this directory:

1. `model-aliases.yaml`: non-runtime alias metadata.
2. `provider-denylist.yaml`: validation rules enforced by `services\litellm\scripts\verify-config.sh`.
3. `policy.md`: human-readable policy.

Secrets in LiteLLM config must use environment references such as `os.environ/VAR_NAME`. Do not commit real provider keys, LiteLLM keys, database URLs, Redis URLs, private hostnames, generated virtual keys, or raw prompt/response logging examples.
