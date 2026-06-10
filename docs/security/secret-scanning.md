# Secret scanning

**Status:** Phase 3 baseline
**Primary repo-local scanner:** Gitleaks with `.gitleaks.toml`

Secret scanning protects this gateway from committing provider keys, LiteLLM keys, database URLs, private keys, tunnel or edge-service tokens, backup credentials, and private/public infrastructure hostnames.

## Repo-local enforcement

Run:

```powershell
pwsh -NoProfile -File scripts\check-secrets.ps1
```

The script:

- Fails on committed `.env` files except `.env.example`.
- Fails on tracked key, dump, SQL, backup, and local secret artifacts.
- Runs Gitleaks against the current working tree/current checkout.
- Uses `.gitleaks.toml` as the authoritative custom pattern configuration.
- Redacts matched values in output.

Phase 3 uses working-tree/current-checkout scanning for deterministic pull-request gates. Full-history scanning should be handled by GitHub native secret scanning where available, or by a separately approved manual history scan with explicit allowlists.

## GitHub native secret scanning

Enable GitHub native secret scanning for the repository or organization when the account plan supports it. GitHub native scanning can cover repository history and additional surfaces such as issues, pull requests, discussions, wikis, and secret gists.

Phase 3 does not mutate GitHub repository settings. Enabling native secret scanning remains an operator/repository-admin task.

## Allowlist policy

Allowlists must be narrow and justified:

- Placeholder-only examples are allowed.
- Historical Phase 0 public proof URL mentions are allowed only in explicitly historical docs/status.
- Service, config, workflow, and test artifacts remain strict.
- Broad directory allowlists are not allowed.

## Incident response

If a real secret is found:

1. Rotate or revoke the credential immediately.
2. Review where it was exposed and who had access.
3. Remove the secret from current files.
4. Delete affected logs if a secret was printed.
5. Treat history rewrite as secondary to revocation; do not rely on history rewrite alone.

## Provider validation

Phase 3 secret scanning must not validate credentials against providers. Provider-contacting secret verification can be considered later only with explicit approval.
