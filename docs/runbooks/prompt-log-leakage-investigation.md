# Prompt or response log leakage investigation runbook

Use this runbook when raw prompts, model responses, secrets, stack traces, SQL, database URLs, provider keys, or private hostnames may have appeared in logs or artifacts.

## Immediate containment

1. Stop sharing the affected log output.
2. Identify the service, deployment, time window, and route or job.
3. Disable or roll back the logging/config change that caused leakage.
4. Rotate any exposed secrets or keys.

## Investigation

1. Use bounded Railway logs only.
2. Search for a sentinel or known leaked marker without copying sensitive payloads into docs.
3. Confirm whether LiteLLM raw prompt/response logging is disabled.
4. Check backup manifests and runbook evidence for accidental private endpoint or SQL exposure.

## Documentation

Record only non-secret incident metadata:

1. Time window.
2. Affected service.
3. Data class exposed.
4. Containment action.
5. Rotation action.
6. Follow-up owner.

Do not store raw leaked payloads in the repository.
