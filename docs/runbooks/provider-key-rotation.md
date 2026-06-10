# Provider and gateway key rotation runbook

Use this runbook when rotating provider keys, LiteLLM master/admin credentials, backup encryption keys, or developer virtual keys.

Never paste secrets, generated virtual keys, database URLs, or backup credentials into docs, chat, issues, screenshots, or logs.

## Provider keys

1. Create or obtain the replacement provider key in the provider console.
2. Set the replacement only as a sealed Railway variable on `litellm-proxy`.
3. Redeploy or restart `litellm-proxy` if required.
4. Validate the affected approved aliases with a disposable LiteLLM virtual key.
5. Revoke the old provider key at the provider.
6. Record provider name, rotation reason, validation result, and revocation confirmation without secret values.

## LiteLLM master key and Admin UI credentials

1. Schedule a maintenance window because master-key rotation can affect automation and validation helpers.
2. Set the replacement as a sealed Railway variable.
3. Update approved operator secret storage.
4. Redeploy and validate admin-only operations from an approved operator context.
5. Revoke or remove the old credential.

## Developer virtual keys

1. Create a replacement key with the same approved aliases, budget, rate limit, and expiry policy.
2. Deliver the key only through the approved secret-sharing channel.
3. Block or revoke the old key.
4. Record non-secret metadata in the key inventory or revocation ledger.

## Backup encryption key

1. Generate replacement key material in an operator-controlled secret manager.
2. Escrow the replacement outside the Railway project.
3. Set `BACKUP_ENCRYPTION_KEY` as a sealed variable on `backup-worker`.
4. Run a backup and restore-check with the replacement key.
5. Preserve the old key until all old artifacts expire or are intentionally re-encrypted and verified.
6. If the old key may be compromised, treat all artifacts encrypted with it as exposed and rotate any data that could be recovered from those backups.
