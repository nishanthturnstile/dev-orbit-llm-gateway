# Scripts

This directory contains repository automation and validation scripts.

Current `phase0-*` scripts are retained for Phase 0 validation and proof operations. Phase 1 does not add functional scripts beyond documentation.

Future scripts should:

- Avoid printing secrets or generated virtual keys.
- Use bounded Railway logs if Railway inspection is needed.
- Prefer placeholders and environment references over literal values.
- Fail clearly on unsafe config.
- Avoid mutating Railway, Cloudflare, provider, database, or tunnel resources unless the operator approved the exact action.

Planned later-phase scripts include secret checks, LiteLLM config linting, Railway smoke checks, and virtual-key creation helpers.
