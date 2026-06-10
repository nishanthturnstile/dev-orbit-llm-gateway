# Provider outage and same-tier fallback runbook

Same-tier fallbacks must not be enabled until fallback candidates are approved, budgeted, and tested. Do not add ad hoc direct-provider aliases during an incident.

## Triage

1. Confirm whether failures are provider-specific, alias-specific, or gateway-wide.
2. Check LiteLLM metadata, bounded logs, and provider status pages.
3. Verify provider credentials only by using approved validation paths; never print keys.

## Response

1. If one provider is down, notify users of affected aliases.
2. If an approved same-tier fallback exists, enable only the pre-approved alias/config path.
3. Validate missing/invalid auth, approved alias success, streaming if relevant, and spend controls.
4. If no approved fallback exists, keep the alias degraded rather than routing to an unapproved provider.

## After recovery

1. Revert temporary fallback changes if they were incident-only.
2. Review spend impact.
3. Record provider, aliases, start/end time, action, and validation evidence.
