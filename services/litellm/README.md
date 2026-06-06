# LiteLLM service

This service directory is for the LiteLLM Proxy app service.

## Boundary

LiteLLM owns the v1 gateway API, built-in Admin UI, model aliases, virtual keys, users, teams, budgets, spend tracking, provider routing, and same-tier fallback behavior.

The service must not store real provider keys, LiteLLM master/admin keys, generated virtual keys, database URLs, Redis URLs, Railway variables, backup credentials, or private hostnames in source control.

## Current Phase 2 status

`services\litellm\config.yaml` is the runtime source of truth for LiteLLM model routing and policy. The Dockerfile copies this file to `/app/config.yaml`.

`config\litellm` contains policy metadata and validation inputs only; it is not a second runtime config home.

## Health checks

Use LiteLLM `/health/readiness` for Railway deployment readiness. Do not use `/health` as a deployment health check because LiteLLM documents it as a provider health endpoint that can make upstream model calls.

## Phase 2 artifacts

- `Dockerfile`: digest-pinned LiteLLM database-capable image.
- `config.yaml`: runtime aliases and LiteLLM settings with environment references for secrets.
- `scripts\verify-config.sh`: local policy/config validation.

Smoke tests and CI policy gates are owned by later phases.
