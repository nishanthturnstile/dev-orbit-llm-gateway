# Railway configuration notes

This directory is the documentation home for Railway environment setup.

Phase 4 created durable staging shells in Railway. See `staging.md` for non-secret names, IDs, service boundaries, and variable-reference shapes.

This directory may document:

- Project and environment names.
- Service boundaries.
- Variable references between services.
- Sealed variable handling.
- Dockerfile or config-as-code paths.
- Deployment health check path, expected to be `/health/readiness` for LiteLLM.
- Staging and production differences.

Do not store Railway variable values, tokens, database URLs, private hostnames, generated virtual keys, or provider keys here.
