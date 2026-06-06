# Phase 2 fallback deferral

**Status:** Accepted for Phase 2
**Related roadmap phases:** Phase 2 and Phase 5

## Decision

Phase 2 intentionally defines no LiteLLM fallbacks.

Zero fallbacks is stricter than the roadmap rule that fallbacks must be same-tier only. A later phase may add same-tier fallbacks only after the fallback provider/model is approved, credited, configured, and validated.

## Rationale

Only the OpenAI `dev-fast` path was validated in Phase 0. Adding fallback routes now would require guessing model equivalence, provider availability, and cost behavior. That would risk cross-tier routing, unexpected spend, and policy drift.

## Follow-up

If fallbacks are added before deployment, Phase 5 must validate:

- source and fallback models are the same tier
- provider credentials exist only in Railway variables
- fallback behavior works for chat and streaming where applicable
- failure behavior does not leak provider details or stack traces
