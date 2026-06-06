# Phase 1 repository-only gate exception

**Status:** Accepted for Phase 1 repository/docs work
**Related roadmap phase:** Phase 1 - Repository and project structure
**Related status tracker:** `docs\operations\implementation-status.md`

## Decision

Phase 1 repository-only work may proceed while the Phase 0 funded provider proof remains blocked, provided no durable deployment, Railway mutation, provider mutation, Cloudflare mutation, database mutation, tunnel mutation, or production exposure work is performed.

This exception covers only repository structure, documentation homes, placeholders, hygiene files, and service-boundary documentation.

## Context

Phase 0 validated the public LiteLLM-native-auth shape enough to inform repository structure, but real chat and streaming responses remain blocked by unfunded provider credits. The Phase 1 structure work does not require provider calls and does not promote Phase 0 proof resources to staging or production.

## Guardrails

- Do not mark Phase 0 runtime proof gates complete from this decision.
- Do not create or mutate Railway, Cloudflare, provider, database, tunnel, domain, or secret resources.
- Do not add real secrets, generated virtual keys, Railway variables, database URLs, Redis URLs, backup credentials, private hostnames, raw prompts/responses, stack traces, or SQL.
- Keep Phase 1 limited to docs, placeholders, service boundaries, and checkout hygiene.
- Defer functional LiteLLM config, backup worker code, cloudflared config, smoke tests, and CI workflows to the roadmap phases that own them.

## Follow-up

Before durable staging or production work, close or explicitly re-accept the Phase 0 provider chat and streaming blockers.
