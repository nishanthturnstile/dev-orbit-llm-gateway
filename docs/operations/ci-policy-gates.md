# CI policy gates

**Status:** Phase 3 baseline
**Scope:** Local and GitHub Actions enforcement before durable Railway staging

Phase 3 policy gates validate repository artifacts only. They must not call Railway, OpenAI, Cloudflare, provider APIs, backup storage, tunnels, domains, or deployment endpoints.

## Local validation commands

Run from the repository root:

```powershell
pwsh -NoProfile -File scripts\lint-litellm-config.ps1
pwsh -NoProfile -File scripts\check-secrets.ps1
bash services/litellm/scripts/verify-config.sh
python scripts\validate-litellm-config.py
python -m pytest tests\smoke --collect-only -q
python -m pytest tests\smoke -q
```

`scripts\check-secrets.ps1` requires either a local `gitleaks` binary or Docker. The Docker fallback uses a digest-pinned Gitleaks image.

## GitHub Actions workflows

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `.github\workflows\ci.yml` | `pull_request`, `push` to `main`, `workflow_dispatch` | Config linting, secret scanning, repository hygiene, and smoke skeleton validation. |
| `.github\workflows\image-policy.yml` | `pull_request`, `push` to `main`, `workflow_dispatch` | Service Dockerfile image pinning and image-policy checks. |
| `.github\workflows\staging-smoke.yml` | `workflow_dispatch` only | Validate the staging smoke script shape without network calls. |

## Security posture

Phase 3 workflows:

- Use `permissions: {}` at workflow level and grant `contents: read` per job.
- Use no GitHub secrets.
- Do not use `pull_request_target`.
- Do not use path filters for checks that may later become required.
- Pin every `uses:` action to a full commit SHA.
- Use `persist-credentials: false` for checkout.
- Avoid Railway, provider, Cloudflare, and deployment mutation commands.

Dependabot is configured for the `github-actions` ecosystem so pinned action SHAs can be updated through reviewable pull requests.

## Config policy

The LiteLLM policy source of truth remains the Phase 2 config and metadata:

- `services\litellm\config.yaml`
- `config\litellm\model-aliases.yaml`
- `config\litellm\provider-denylist.yaml`

`scripts\validate-litellm-config.py` is the shared validator. The POSIX shell and PowerShell scripts call this validator instead of duplicating policy logic.

## Image policy

All service Dockerfiles must use digest-pinned base images. `:latest` and unpinned mutable tags are forbidden.

Image signature verification is intentionally deferred. It should not be enabled until a deterministic verification tool, trust root, and failure policy are selected.

## Phase 4 handoff

Durable Railway staging should not begin until:

- CI policy gates pass locally and in GitHub Actions.
- Secret scanning passes.
- LiteLLM config linting passes.
- Image policy passes.
- The staging smoke skeleton is present and validate-only.
