# Supported developer tool setup

**Status:** Phase 8 in progress  
**Source of truth:** `docs\onboarding\supported-tools-matrix.md`  
**Related decision:** `docs\decisions\phase-2-developer-tool-validation-deferral.md`

## Scope

This document explains how to validate developer tools against the LiteLLM-native public Railway/custom endpoint.

Do not record real base URLs, LiteLLM virtual keys, provider keys, raw prompts, raw responses, private hostnames, or screenshots that reveal secrets.

## Required tool capabilities

A tool can be marked `Supported` only if it proves:

1. Custom OpenAI-compatible base URL support.
2. `Authorization: Bearer <LiteLLM virtual key>` support.
3. `/v1/chat/completions` support for at least one approved alias.
4. Streaming support if the tool depends on streaming UX.
5. No need for direct provider model names or provider credentials.

If a tool needs a local proxy or wrapper only to inject headers or normalize routes, mark it `Supported with wrapper` and document the wrapper before launch.

## Current compatibility status

| Tool | Setup path | Header support | Streaming support | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| OpenAI-compatible raw HTTP validation script | `scripts\phase0-validate-litellm.ps1` and `scripts\phase6-validate-public-origin.ps1` | Works with LiteLLM virtual key | Works | Supported baseline | Phase 0 and Phase 6 public validation proved raw HTTP chat and streaming through LiteLLM. This is not the same as an SDK proof. |
| OpenAI SDK scripts | Configure SDK `base_url` / `api_key` from environment variables. | To test | To test | Not tested | Do not mark supported until a Python or JS SDK call succeeds against staging. |
| Continue.dev | Configure custom OpenAI-compatible provider/base URL and LiteLLM virtual key if supported by the client version. | To test | To test | Not tested | Requires live IDE validation in Phase 8. |
| Cline/Roo-style VS Code tool | Configure OpenAI-compatible endpoint, model alias, and API key field if supported by the client version. | To test | To test | Not tested | Requires live IDE validation in Phase 8. |
| Aider or equivalent CLI | Configure OpenAI-compatible base URL and API key from environment variables or CLI settings. | To test | To test | Not tested | Requires live CLI validation in Phase 8. |
| Copilot CLI BYOK-compatible usage | Only applicable if the selected Copilot CLI mode supports custom OpenAI-compatible endpoints and bearer auth. | To test | To test | Not tested | Exclude from v1 if BYOK-compatible endpoint configuration is unavailable. |

## Generic environment-variable pattern

Use local environment variables or the tool's secret store. Do not put virtual keys in repo files.

```powershell
$env:OPENAI_API_KEY = '<liteLLM-virtual-key>'
$env:OPENAI_BASE_URL = '<staging-public-base-url>/v1'
```

Use LiteLLM aliases such as `dev-fast`, `dev-code`, or `dev-reasoning`; do not configure direct provider model names.

## Evidence template

Record each validation in `docs\onboarding\supported-tools-matrix.md` using non-secret evidence:

| Field | Required value |
| --- | --- |
| Tool and version | Name and version only. |
| Base URL support | `Works`, `Works with wrapper`, or `Blocked`. |
| Authorization support | `Works`, `Works with wrapper`, or `Blocked`. |
| Streaming support | `Works`, `Not required`, or `Blocked`. |
| Tested alias | Alias only, never provider model or key. |
| Result | `Supported`, `Supported with wrapper`, `Blocked`, or `Not in v1`. |
| Evidence | Date, tester, sanitized status codes, and whether streaming chunks were observed. |

## Blocked-tool rules

Mark a tool `Blocked` if it:

- Cannot configure a custom OpenAI-compatible base URL.
- Cannot send the LiteLLM virtual key as bearer auth or equivalent API-key auth.
- Requires direct provider keys in the client.
- Requires direct provider model names that bypass LiteLLM aliases.
- Breaks required streaming behavior and has no acceptable wrapper.

Blocked tools must be excluded from v1 production onboarding.
