# Local config validation

Phase 2 config validation checks local artifacts only. It must not call Railway, OpenAI, Cloudflare, backup storage, or any provider.

## Linux/macOS or Git Bash

```sh
sh services/litellm/scripts/verify-config.sh
pwsh -NoProfile -File scripts/lint-litellm-config.ps1
```

## Windows PowerShell

The verifier uses Python and PyYAML. If PyYAML is missing, install it in a local development environment before running validation:

```powershell
python -m pip install PyYAML
pwsh -NoProfile -File scripts\lint-litellm-config.ps1
```

`scripts\lint-litellm-config.ps1` is the preferred Windows entry point. If `sh` is available through Git Bash or WSL, `sh services\litellm\scripts\verify-config.sh` runs the same shared Python validator.

## Validation coverage

The verifier checks:

- `services\litellm\config.yaml` parses.
- Required aliases exist.
- `config\litellm\model-aliases.yaml` alias names match runtime aliases.
- `config\litellm\provider-denylist.yaml` rules are enforced.
- `sensitive-code` and `sensitive-*` are absent.
- Runtime secrets are environment references.
- Wildcard routes are absent.
- Cache stays default-off.
- `--detailed_debug` is absent.
- Public Railway proof URLs, private hostnames, database URLs, Redis URLs, and key-like values are absent.

The verifier fails closed if required dependencies are missing.
