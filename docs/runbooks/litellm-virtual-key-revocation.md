# LiteLLM virtual-key revocation runbook

This runbook records the Phase 5 non-secret process for revoking or blocking LiteLLM virtual keys. Never record the key value itself.

## When to revoke

1. A developer leaves the approved group.
2. A key appears in source, chat, screenshots, logs, or another unapproved location.
3. Spend, rate, or alias usage looks suspicious.
4. A Phase 5 validation key has finished its test.

## Phase 5 revocation path

Use the LiteLLM API from an approved operator context. The bundled Phase 5 validator automatically blocks its disposable validation key and verifies the blocked key no longer works.

For manual revocation, use the master key only from a local secret manager, Railway-injected environment, or another approved operator context. Do not paste the key into chat or committed docs.

Record only non-secret metadata:

1. Owner or validation purpose.
2. Revocation reason.
3. Revocation time.
4. Whether a replacement is needed.
5. Confirmation that the revoked key no longer works.

If a key leak might include provider credentials, database URLs, or the LiteLLM master key, rotate the affected upstream secret and document only the incident metadata.

## Post-restore revoked-key reconciliation

A database restore can reintroduce LiteLLM virtual keys that were revoked after the restored backup timestamp. Before exposing restored traffic:

1. Identify the restored backup timestamp.
2. Compare restored LiteLLM key metadata with the non-secret revocation ledger.
3. Re-block or revoke every key whose revocation timestamp is newer than the restored backup timestamp.
4. Validate that a re-blocked disposable key no longer works.
5. Record only non-secret evidence: key alias or LiteLLM key ID, owner or validation purpose, revocation timestamp, restore timestamp, and confirmation result.

The revocation ledger must never store raw virtual-key values. Use key aliases, LiteLLM key IDs, owner/team metadata, hashes if available, revocation reason, ticket/reference ID, and timestamps.
