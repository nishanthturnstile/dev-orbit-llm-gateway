# Railway configuration notes

This directory is the documentation home for future Railway environment setup.

Phase 1 does not create or mutate Railway projects, services, variables, domains, databases, buckets, or deployments.

Later phases should document:

- Project and environment names.
- Service boundaries.
- Variable references between services.
- Sealed variable handling.
- Dockerfile or config-as-code paths.
- Deployment health check path, expected to be `/health/readiness` for LiteLLM.
- Staging and production differences.

Do not store Railway variable values, tokens, database URLs, private hostnames, generated virtual keys, or provider keys here.
