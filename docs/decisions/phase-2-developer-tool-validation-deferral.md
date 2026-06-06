# Phase 2 developer-tool validation deferral

**Status:** Accepted for Phase 2 start
**Related roadmap phases:** Phase 0, Phase 2, Phase 8
**Related tracker:** `docs\operations\implementation-status.md`

## Decision

The successful OpenAI-compatible validation script is accepted as sufficient proof for Phase 2 planning and local service scaffolding. Named developer-tool compatibility validation is deferred to Phase 8 staging proof gates.

## Context

After OpenAI credits were added, `scripts\phase0-validate-litellm.ps1` validated the public LiteLLM endpoint through Railway with:

- Generated LiteLLM virtual key: `200`
- Chat completion through `dev-fast`: `200`
- Streaming chat completion through `dev-fast`: `200`
- Developer virtual key denied on admin route: `403`
- Prompt sentinel absent from bounded Railway logs

The script exercises the required OpenAI-compatible base URL, `Authorization: Bearer ...` virtual-key path, and streaming behavior. It does not prove Continue.dev, Cline/Roo, Aider, or Copilot CLI BYOK-compatible UX.

## Guardrail

Do not mark named developer tools as supported until each tool is tested against the staging gateway or an approved equivalent environment. Phase 8 must still record compatibility evidence for the selected v1 tools.
