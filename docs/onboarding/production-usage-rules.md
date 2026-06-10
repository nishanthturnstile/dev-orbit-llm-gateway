# Production usage rules

**Status:** Draft for pilot onboarding. Do not distribute until production smoke tests pass and pilot access is approved.

These rules apply to the production Internal LLM Gateway, Open WebUI, and LibreChat.

## Access model

- Each developer receives a separate LiteLLM virtual key.
- Do not share keys between people, tools, or UI services.
- Store keys only in approved local secret stores, environment variables, or tool settings.
- Never commit keys to source control, tickets, chat, docs, screenshots, or shell history.
- Report suspected key exposure immediately so the key can be revoked.

## Approved surfaces

Use only approved production surfaces:

- LiteLLM OpenAI-compatible API through the approved production base URL.
- LiteLLM Admin UI only for approved admins/leads.
- Open WebUI production service after pilot access is granted.
- LibreChat production service after pilot access is granted.

Do not call external providers directly with company/provider keys from client tools or chat UIs.

## Data rules

Until a separate sensitive-code or confidential-data approval exists, do not submit:

- Customer/client confidential data.
- Private credentials, tokens, certificates, or secrets.
- Production incident payloads that include private logs, stack traces, SQL, or customer data.
- Proprietary source code that policy disallows for external LLM processing.
- Personal data beyond what is approved for the pilot.

Open WebUI and LibreChat production stores are durable production data. Conversations, uploads, search indexes, embeddings, users, sessions, settings, and UI state may be retained and backed up according to the approved production retention policy.

## Model usage

- Use LiteLLM aliases only, such as approved `dev-*` aliases.
- Use `dev-code` as the default coding alias when unsure.
- Use `premium-code`, `premium-planning`, `ultra-premium-code`, or `ultra-premium-planning` only if those aliases are explicitly assigned to your virtual key.
- Do not configure direct provider model names unless the alias policy explicitly allows it.
- Do not create or use `sensitive-code` or `sensitive-*` aliases unless a separate approval exists.
- If a model is blocked or over budget, do not work around the restriction with another provider key.

## Chat UI rules

For Open WebUI and LibreChat:

- Use assigned user accounts only.
- Do not create shared accounts.
- Do not add arbitrary OpenAI-compatible endpoints.
- Do not paste direct provider keys.
- Do not enable plugins, tools, connectors, code execution, web search, or external integrations unless that exact feature is approved.
- Treat uploads and knowledge/RAG features as durable retained content.

## Failure reporting

When reporting a problem, include only non-secret details:

- Tool or UI name.
- Approximate time.
- Alias used.
- Sanitized status code or high-level error.
- LiteLLM call ID if visible and safe.

Do not include virtual keys, provider keys, base URLs, raw prompts, raw responses, private hostnames, database URLs, stack traces, SQL, or screenshots that reveal sensitive data.

## Budget and rate limits

- Each key has budget and rate limits.
- Budget exhaustion is expected to block requests.
- Ask for budget increases through the approved workflow.
- Do not use another developer's key or a UI service key to bypass limits.
