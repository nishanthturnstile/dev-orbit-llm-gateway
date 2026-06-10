---
goal: Self-hosted Team Password Vault on Railway using Vaultwarden
version: 1.0
date_created: 2026-06-10
last_updated: 2026-06-10
owner: Platform / Operator
tags: [infrastructure, railway, vaultwarden, password-manager, security, small-team]
---

# Introduction

This implementation plan defines a secure, self-hosted password-sharing service for a small team using Vaultwarden on Railway. The target outcome is a separate Railway project named `team-password-vault` that hosts a Bitwarden-compatible team vault at `https://vault.thaarei.com`, backed by Railway managed PostgreSQL, a persistent `/data` volume, SMTP email delivery, disabled public signups, invite-only onboarding, strong administrator controls, and tested backup/restore procedures.

This plan is intentionally separate from the Internal LLM Gateway Railway project. It must not mutate, reuse, or depend on the existing `dev-orbit-llm-gateway` Railway project, LiteLLM services, provider keys, UI keys, chat UI services, backup buckets, or service variables.

Official documentation checked on 2026-06-10 using Context7:

- Railway official docs, library `/railwayapp/docs`: services, public networking, `PORT`, custom domains, managed PostgreSQL, private networking, variables/secrets, volume backups, logs, metrics, and HTTPS termination.
- Vaultwarden official repository/wiki, library `/dani-garcia/vaultwarden`: Docker deployment, `/data` persistence, PostgreSQL backend, `DOMAIN`, SMTP, disabled signups, invitations, `ROCKET_PORT`, FIDO2/WebAuthn domain requirements, and Argon2id-hashed `ADMIN_TOKEN`.

## 1. Requirements & Constraints

- **REQ-001**: Create a separate Railway project named `team-password-vault` for the password manager.
- **REQ-002**: Create two Railway environments: `staging` for validation/upgrade rehearsals and `production` for team usage.
- **REQ-003**: Deploy one Vaultwarden app service named `vaultwarden`.
- **REQ-004**: Provision one Railway managed PostgreSQL database service named `vaultwarden-postgres` in each environment.
- **REQ-005**: Attach a persistent Railway volume to the `vaultwarden` service at `/data` in each environment.
- **REQ-006**: Configure the production public URL as `https://vault.thaarei.com`.
- **REQ-007**: Configure `DOMAIN=https://vault.thaarei.com` in production so Vaultwarden generated links, attachments, and FIDO2/WebAuthn use the exact public origin.
- **REQ-008**: Configure SMTP before inviting users so invites, verification, and administrative emails work.
- **REQ-009**: Use PostgreSQL for team/production usage; do not rely on SQLite for production team data.
- **REQ-010**: Use Bitwarden-compatible clients for browser extensions, desktop apps, and mobile apps.
- **REQ-011**: Use invite-only onboarding for all team members.
- **REQ-012**: Create shared organization collections for team password sharing.
- **REQ-013**: Validate the exact Vaultwarden image tag/digest and relevant environment variables immediately before deployment.

- **SEC-001**: Disable public signups with `SIGNUPS_ALLOWED=false` in staging and production.
- **SEC-002**: Keep invitations enabled with `INVITATIONS_ALLOWED=true` only after SMTP is configured and verified.
- **SEC-003**: Store every secret only as a sealed Railway variable or in an approved operator secret escrow.
- **SEC-004**: Never commit SMTP passwords, database URLs, Railway variables, Vaultwarden admin tokens, user passwords, backup credentials, vault exports, or generated recovery material to Git.
- **SEC-005**: Use an Argon2id PHC hash in `ADMIN_TOKEN`; never store the plaintext admin token in Railway variables.
- **SEC-006**: Keep the plaintext Vaultwarden admin token in offline/operator escrow only until initial setup is complete.
- **SEC-007**: After initial setup, disable the Vaultwarden admin page when it is not actively needed by removing `ADMIN_TOKEN` and redeploying, or keep it enabled only with a strong hashed token and operator-only access.
- **SEC-008**: Require 2FA for all team members as an operating policy before they receive shared collection access.
- **SEC-009**: Use at least two organization owners/admins to avoid lockout, but do not share one admin account.
- **SEC-010**: Restrict Railway dashboard access for the `team-password-vault` project to operators only.
- **SEC-011**: Enable MFA on Railway accounts, DNS/domain registrar accounts, SMTP provider accounts, backup storage accounts, and all Vaultwarden admin accounts.
- **SEC-012**: Use least-privilege collection access; do not grant every user access to every collection by default.
- **SEC-013**: Do not use Vaultwarden for secrets that require formal enterprise compliance, SSO/SCIM enforcement, legal hold, or audited enterprise support unless the risk is explicitly accepted.
- **SEC-014**: Treat Bitwarden/Vaultwarden exports as critical secrets; encrypt immediately and delete temporary plaintext files.
- **SEC-015**: Do not share passwords through Slack, Teams, email, tickets, spreadsheets, screenshots, READMEs, or Railway variables.

- **RAI-001**: Railway must terminate HTTPS for the public domain; do not run Caddy/Nginx inside this deployment solely for TLS.
- **RAI-002**: The Vaultwarden container must listen on `0.0.0.0` and the port exposed to Railway.
- **RAI-003**: Configure `PORT=80`, `ROCKET_ADDRESS=0.0.0.0`, and `ROCKET_PORT=80` unless staging validation proves the selected Railway deployment mode requires a different port mapping.
- **RAI-004**: Use Railway service variable references for PostgreSQL wiring where supported; prefer private/internal database networking from the app service to PostgreSQL.
- **RAI-005**: Do not expose PostgreSQL publicly.
- **RAI-006**: Configure a Railway health check only after validating the selected Vaultwarden release endpoint in staging. Use `/alive` if the release returns `200`; otherwise use `/` only as a deployment-level readiness check.
- **RAI-007**: Enable Railway native backup/snapshot features for PostgreSQL and the attached `/data` volume where available.
- **RAI-008**: Treat Railway logs as operational metadata only; do not log or paste passwords, tokens, exports, or SMTP credentials.
- **RAI-009**: Do not mutate Railway resources without explicit operator approval for the exact action.

- **VW-001**: Use the official Vaultwarden container image source `vaultwarden/server`.
- **VW-002**: Do not deploy the floating `latest` tag directly to production. Pin the selected image by digest or immutable version and record the selected digest in private deployment notes.
- **VW-003**: Persist `/data` even when PostgreSQL is used, because attachments, sends, icons/cache, and instance keys may live under `/data`.
- **VW-004**: Configure `DATABASE_URL` using the Railway PostgreSQL private/internal connection value.
- **VW-005**: Configure `SMTP_HOST`, `SMTP_FROM`, `SMTP_PORT`, `SMTP_SECURITY`, `SMTP_USERNAME`, and `SMTP_PASSWORD` before sending invitations.
- **VW-006**: Configure `DOMAIN` with the `https://` scheme and the exact public hostname.
- **VW-007**: Validate FIDO2/WebAuthn after the final custom domain is active; WebAuthn is origin-bound and can fail if the hostname changes.
- **VW-008**: Validate the selected Vaultwarden version's real-time sync / WebSocket / notification setting before enabling any version-specific variable.

- **OPS-001**: Run staging validation before production cutover.
- **OPS-002**: Prove restore into a fresh staging database before production onboarding.
- **OPS-003**: Perform a quarterly restore drill after production launch.
- **OPS-004**: Review user access monthly.
- **OPS-005**: Rotate the Vaultwarden admin token after any operator changes or suspected exposure.
- **OPS-006**: Rotate SMTP credentials and backup credentials at least every 180 days.
- **OPS-007**: Keep a documented break-glass owner and backup owner.
- **OPS-008**: Export organization vault data only for approved disaster-recovery tests; store exports encrypted and delete test exports after validation.

- **CON-001**: This repository stores only the implementation plan. The actual Vaultwarden deployment may use a new private deployment repository or Railway Docker image deployment.
- **CON-002**: Do not add real secrets or generated credentials to this repository.
- **CON-003**: Do not reuse the Internal LLM Gateway project, domains, provider secrets, LiteLLM keys, backup buckets, UI keys, or service variables.
- **CON-004**: Vaultwarden is community-maintained. If enterprise support, formal compliance, mandatory SSO/SCIM, or advanced audit controls are required, use official Bitwarden Enterprise or another audited business password manager.
- **CON-005**: Same-project Railway backups are not sufficient as the only disaster recovery strategy; keep encrypted off-platform backups.

- **GUD-001**: Use `team-password-vault` for the Railway project name.
- **GUD-002**: Use `vaultwarden` for the app service name.
- **GUD-003**: Use `vaultwarden-postgres` for the PostgreSQL service name.
- **GUD-004**: Use `vault.thaarei.com` for the production custom domain.
- **GUD-005**: Use collections named `Engineering`, `Production Access`, `Staging and Development`, `Finance and Vendors`, and `Shared Admin`.
- **GUD-006**: Use normal user accounts for day-to-day access and reserve admin privileges for only two or three trusted operators.
- **PAT-001**: Use one Railway project with two environments: `staging` and `production`.
- **PAT-002**: Use one Vaultwarden service, one PostgreSQL service, and one persistent volume per environment.
- **PAT-003**: Add public/custom domains only after secure variables are present and public signup is disabled.

Recommended baseline variable table:

| Variable | Environment | Value / Source | Secret | Purpose |
| --- | --- | --- | ---: | --- |
| `DOMAIN` | staging | Railway staging URL or staging custom domain | No | Correct links and origin-bound auth testing. |
| `DOMAIN` | production | `https://vault.thaarei.com` | No | Correct links, attachments, and FIDO2/WebAuthn origin. |
| `SIGNUPS_ALLOWED` | both | `false` | No | Blocks public self-registration. |
| `INVITATIONS_ALLOWED` | both | `true` after SMTP validation | No | Allows operator-controlled onboarding. |
| `DATABASE_URL` | both | Railway private/internal PostgreSQL URL | Yes | Stores Vaultwarden relational data in PostgreSQL. |
| `ADMIN_TOKEN` | both | Argon2id PHC hash only | Yes | Protects `/admin`. |
| `SMTP_HOST` | both | Approved SMTP host | No | Email delivery. |
| `SMTP_FROM` | both | `vault@thaarei.com` or approved sender | No | Sender address. |
| `SMTP_FROM_NAME` | both | Approved vault sender name | No | Human-readable sender name. |
| `SMTP_PORT` | both | `587` unless provider requires otherwise | No | STARTTLS SMTP port. |
| `SMTP_SECURITY` | both | `starttls` unless provider requires otherwise | No | SMTP transport security. |
| `SMTP_USERNAME` | both | Approved SMTP username | Yes | SMTP authentication. |
| `SMTP_PASSWORD` | both | Approved SMTP password/app password | Yes | SMTP authentication. |
| `PORT` | both | `80` unless staging proves a different mapping | No | Railway public networking port mapping for this container. |
| `ROCKET_ADDRESS` | both | `0.0.0.0` | No | Listen on all container interfaces. |
| `ROCKET_PORT` | both | Same value as `PORT` | No | Vaultwarden listen port. |
| `LOG_LEVEL` | both | `warn` | No | Reduces unnecessary log detail. |
| `SENDS_ALLOWED` | both | `false` unless explicitly approved | No | Controls Bitwarden Send. |

## 2. Implementation Steps

### Implementation Phase 1 - Documentation, ownership, and preflight

- GOAL-001: Establish ownership, deployment boundaries, documentation evidence, and implementation prerequisites before creating Railway resources.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Confirm the password vault owner, backup owner, and security reviewer. Record them in private operator notes, not in public docs. |  |  |
| TASK-002 | Confirm the production hostname `vault.thaarei.com` and the DNS account that will manage it. |  |  |
| TASK-003 | Confirm the SMTP provider and sender address `vault@thaarei.com` or an approved equivalent. |  |  |
| TASK-004 | Confirm the initial user list and classify each person as `owner`, `admin`, or `member`. |  |  |
| TASK-005 | Confirm whether Vaultwarden's community-maintained risk is acceptable for the team. If not acceptable, stop and use official Bitwarden Enterprise or 1Password Business. |  |  |
| TASK-006 | Create private operator deployment notes outside this repository for non-secret resource IDs and operational evidence. |  |  |
| TASK-007 | Resolve the current `vaultwarden/server` image version and digest from the official image registry. Record the immutable image reference in private deployment notes. |  |  |
| TASK-008 | Verify the selected Vaultwarden release documentation for changed environment variable names before setting production variables. |  |  |

### Implementation Phase 2 - Railway project and staging environment

- GOAL-002: Create an isolated Railway staging environment without exposing production user data.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-009 | Create a new Railway project named `team-password-vault`. Do not use the existing `dev-orbit-llm-gateway` project. |  |  |
| TASK-010 | Create Railway environments named `staging` and `production`. |  |  |
| TASK-011 | In `staging`, create a managed PostgreSQL service named `vaultwarden-postgres`. |  |  |
| TASK-012 | In `staging`, create an app service named `vaultwarden` from the selected pinned `vaultwarden/server` image or from a minimal private deployment repository that uses the pinned image. |  |  |
| TASK-013 | In `staging`, attach a persistent volume to the `vaultwarden` service at `/data`. |  |  |
| TASK-014 | In `staging`, set non-secret variables: `DOMAIN`, `SIGNUPS_ALLOWED`, `INVITATIONS_ALLOWED`, `PORT`, `ROCKET_ADDRESS`, `ROCKET_PORT`, `LOG_LEVEL`, and any approved policy variables. |  |  |
| TASK-015 | In `staging`, set secret variables: `DATABASE_URL`, `SMTP_USERNAME`, `SMTP_PASSWORD`, and hashed `ADMIN_TOKEN`. |  |  |
| TASK-016 | In `staging`, keep the service on a Railway-generated domain or staging-only custom domain until validation succeeds. |  |  |
| TASK-017 | Validate that the service starts, listens on `0.0.0.0:$PORT`, and returns `200` from the selected readiness URL over HTTPS. |  |  |
| TASK-018 | Validate the selected health check path. Prefer `/alive` only if the running release returns `200`; otherwise use `/` as a deployment health check. |  |  |

### Implementation Phase 3 - Vaultwarden configuration baseline

- GOAL-003: Apply a secure small-team Vaultwarden configuration with invite-only access and no public self-registration.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-019 | Generate a long random admin token locally and convert it to an Argon2id PHC hash using Vaultwarden's documented `hash` command or the documented Argon2id CLI method. |  |  |
| TASK-020 | Store only the Argon2id PHC hash in Railway variable `ADMIN_TOKEN`. Do not store the plaintext admin token in Railway. |  |  |
| TASK-021 | Set `DOMAIN=https://vault.thaarei.com` in production and a staging-specific `DOMAIN` during staging validation. |  |  |
| TASK-022 | Set `SIGNUPS_ALLOWED=false` in both environments. |  |  |
| TASK-023 | Set `INVITATIONS_ALLOWED=true` after SMTP validation passes. |  |  |
| TASK-024 | Set `DATABASE_URL` to the Railway PostgreSQL private/internal connection value. |  |  |
| TASK-025 | Set `SMTP_HOST`, `SMTP_FROM`, `SMTP_PORT=587`, `SMTP_SECURITY=starttls`, `SMTP_USERNAME`, and `SMTP_PASSWORD`. |  |  |
| TASK-026 | Set `PORT`, `ROCKET_ADDRESS`, and `ROCKET_PORT` to the staging-validated Railway-compatible values. |  |  |
| TASK-027 | Set `LOG_LEVEL=warn` unless troubleshooting requires temporary higher verbosity. |  |  |
| TASK-028 | Validate whether the selected release still requires a WebSocket/notifications variable. Enable only the documented variable for the selected release. |  |  |
| TASK-029 | Confirm that `/admin` requires the admin token and is not accessible anonymously. |  |  |
| TASK-030 | After setup, decide whether to disable the admin page by removing `ADMIN_TOKEN` and redeploying. Record the decision in private operator notes. |  |  |

### Implementation Phase 4 - Production Railway deployment

- GOAL-004: Promote the validated staging configuration to production with a custom domain and durable data controls.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-031 | In `production`, create a managed PostgreSQL service named `vaultwarden-postgres`. |  |  |
| TASK-032 | In `production`, create an app service named `vaultwarden` using the same pinned image reference validated in staging. |  |  |
| TASK-033 | In `production`, attach a persistent volume to `/data`. |  |  |
| TASK-034 | Set all production Railway variables from the baseline variable table using fresh production secrets. Do not blindly copy staging secrets. |  |  |
| TASK-035 | Add the custom domain `vault.thaarei.com` to the production `vaultwarden` service. |  |  |
| TASK-036 | Configure DNS for `vault.thaarei.com` according to Railway's custom-domain instructions. |  |  |
| TASK-037 | Wait for Railway HTTPS certificate provisioning to complete. |  |  |
| TASK-038 | Validate that `https://vault.thaarei.com` loads the Vaultwarden web vault over HTTPS. |  |  |
| TASK-039 | Validate that `DOMAIN=https://vault.thaarei.com` is reflected in generated invite links. |  |  |
| TASK-040 | Validate that the staging Railway-generated URL is not used for production invites or WebAuthn setup. |  |  |

### Implementation Phase 5 - Team setup and access model

- GOAL-005: Configure team sharing with controlled collections, least privilege, and recoverable administration.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-041 | Create the first operator account from the production web vault. |  |  |
| TASK-042 | Verify the first operator account email through SMTP. |  |  |
| TASK-043 | Create the organization named `Thaarei Team Vault` or an approved equivalent. |  |  |
| TASK-044 | Add a second owner/admin account before adding normal members. |  |  |
| TASK-045 | Create collections named `Engineering`, `Production Access`, `Staging and Development`, `Finance and Vendors`, and `Shared Admin`. |  |  |
| TASK-046 | Invite initial users with least-privilege collection access. |  |  |
| TASK-047 | Require each user to enable 2FA before granting shared collection access. |  |  |
| TASK-048 | Validate Bitwarden browser extension login against `https://vault.thaarei.com`. |  |  |
| TASK-049 | Validate Bitwarden desktop app login against `https://vault.thaarei.com`. |  |  |
| TASK-050 | Validate Bitwarden mobile app login against `https://vault.thaarei.com`. |  |  |
| TASK-051 | Validate creating, sharing, editing, and deleting one test credential in each collection. |  |  |
| TASK-052 | Delete all test credentials used during validation. |  |  |

### Implementation Phase 6 - Backup, restore, and disaster recovery

- GOAL-006: Make PostgreSQL data and `/data` volume contents recoverable before production usage becomes business-critical.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-053 | Enable Railway native PostgreSQL backups or snapshots for `vaultwarden-postgres` in production. |  |  |
| TASK-054 | Enable Railway volume backups or snapshots for the production `/data` volume where available. |  |  |
| TASK-055 | Configure an encrypted off-platform backup target outside the `team-password-vault` Railway project. |  |  |
| TASK-056 | Create a logical PostgreSQL backup job using `pg_dump` or an approved managed backup workflow. |  |  |
| TASK-057 | Create a `/data` backup job that captures attachments, sends, icon cache if required, and instance key material. |  |  |
| TASK-058 | Encrypt every off-platform backup artifact before upload. |  |  |
| TASK-059 | Store backup encryption material in operator escrow outside Railway and outside this repository. |  |  |
| TASK-060 | Restore PostgreSQL into a fresh staging database from an encrypted backup artifact. |  |  |
| TASK-061 | Restore `/data` into a fresh staging volume from an encrypted backup artifact. |  |  |
| TASK-062 | Start a disposable staging Vaultwarden instance against the restored database and restored `/data` volume. |  |  |
| TASK-063 | Validate that restored login, organization collections, and one shared item work. |  |  |
| TASK-064 | Document measured RPO and RTO in private operator notes. |  |  |
| TASK-065 | Schedule quarterly restore drills. |  |  |

Suggested starting targets:

| Control | Initial target |
| --- | --- |
| Backup cadence | Daily encrypted logical database backup plus daily `/data` backup. |
| Retention | 7 daily, 4 weekly, 12 monthly encrypted artifacts. |
| RPO | 24 hours. |
| RTO | 4 hours for small-team internal service restoration. |
| Restore drill cadence | Quarterly and after major Vaultwarden version upgrades. |

### Implementation Phase 7 - Security validation and production launch

- GOAL-007: Validate the deployment against security, availability, and small-team operating requirements before inviting the full team.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-066 | Confirm public signup is blocked by attempting registration from an uninvited email address. |  |  |
| TASK-067 | Confirm invitation flow works for one test member. |  |  |
| TASK-068 | Confirm SMTP emails do not expose secrets. |  |  |
| TASK-069 | Confirm `/admin` is protected by the hashed admin token or disabled after setup. |  |  |
| TASK-070 | Confirm PostgreSQL has no public exposure. |  |  |
| TASK-071 | Confirm the Vaultwarden app service has only the intended public domain. |  |  |
| TASK-072 | Confirm Railway project access is restricted to operators. |  |  |
| TASK-073 | Confirm Railway variables do not contain plaintext admin-token values. |  |  |
| TASK-074 | Confirm production logs do not contain SMTP passwords, admin tokens, user passwords, database URLs, or vault item secrets. |  |  |
| TASK-075 | Confirm backup jobs have succeeded at least once and restore drill has passed. |  |  |
| TASK-076 | Invite the first pilot group of users. |  |  |
| TASK-077 | Monitor login, sync, email, memory, CPU, storage, and backup behavior for 7 days. |  |  |
| TASK-078 | Invite the remaining team after the 7-day pilot has no blocking findings. |  |  |

### Implementation Phase 8 - Maintenance and upgrades

- GOAL-008: Operate the service safely after launch and avoid accidental breakage during image upgrades.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-079 | Review Vaultwarden release notes before each upgrade. |  |  |
| TASK-080 | Test every image upgrade in `staging` before production. |  |  |
| TASK-081 | Take fresh PostgreSQL and `/data` backups before production upgrades. |  |  |
| TASK-082 | Upgrade production only after staging login, invite, sync, admin, and restore checks pass. |  |  |
| TASK-083 | Review user and collection access monthly. |  |  |
| TASK-084 | Review Railway costs, storage growth, and backup success monthly. |  |  |
| TASK-085 | Rotate SMTP and backup credentials every 180 days or immediately after suspected exposure. |  |  |
| TASK-086 | Rotate the Vaultwarden admin token after operator changes or suspected exposure. |  |  |
| TASK-087 | Keep a break-glass recovery note offline with domain, Railway project, backup target, and restore owners. |  |  |

## 3. Alternatives

- **ALT-001**: Official Bitwarden self-hosted. Rejected for this small Railway deployment because it is heavier operationally than Vaultwarden. Choose it instead if enterprise support, formal compliance, SSO/SCIM, or vendor-backed auditability is required.
- **ALT-002**: Bitwarden Enterprise cloud. Rejected as the default because the requested direction is self-hosted on Railway. It remains the best option if compliance, SLA, SSO, SCIM, and audit requirements outweigh self-hosting control.
- **ALT-003**: 1Password Business. Rejected as the default because it is SaaS rather than self-hosted. It remains a strong option for business-grade password sharing with lower operational burden.
- **ALT-004**: Passbolt self-hosted. Rejected as the default because the team likely benefits more from Bitwarden-compatible clients and Vaultwarden's lightweight deployment model.
- **ALT-005**: Infisical, Doppler, HashiCorp Vault, or Railway variables. Rejected for human password sharing because these are better suited to application/developer secrets, not shared human credential vaults with browser/mobile password-manager workflows.
- **ALT-006**: Store passwords in Slack, Teams, GitHub, `.env` files, spreadsheets, or Railway variables. Rejected because these do not provide appropriate per-user access control, auditability, client autofill, password hygiene, or safe sharing workflows.

## 4. Dependencies

- **DEP-001**: Railway workspace with permission to create a separate project, services, environments, variables, domains, volumes, and managed PostgreSQL.
- **DEP-002**: Custom domain DNS control for `vault.thaarei.com`.
- **DEP-003**: SMTP provider account with credentials for `vault@thaarei.com` or an approved sender address.
- **DEP-004**: Official Vaultwarden image source `vaultwarden/server` and selected pinned image digest/version.
- **DEP-005**: Railway managed PostgreSQL in staging and production.
- **DEP-006**: Railway persistent volume for `/data` in staging and production.
- **DEP-007**: Encrypted off-platform backup storage outside the `team-password-vault` Railway project.
- **DEP-008**: Operator secret escrow for plaintext admin token, backup encryption key, SMTP credentials, and restore credentials.
- **DEP-009**: Bitwarden-compatible browser extension, desktop app, and mobile app for client validation.
- **DEP-010**: Small-team operating agreement requiring 2FA before shared collection access.

## 5. Files

- **FILE-001**: `docs/impl-plan/infrastructure-team-password-vault-1.md` - This implementation plan.
- **FILE-002**: Private deployment notes outside this repository - Store non-secret Railway resource IDs, selected image digest, validation evidence, RPO/RTO measurements, and upgrade history.
- **FILE-003**: Optional private deployment repository `team-password-vault-deploy` - If Railway image deployment cannot pin by digest directly, create a minimal repository with a digest-pinned Vaultwarden Dockerfile and no secrets.
- **FILE-004**: Optional private runbook `team-password-vault-restore.md` outside this repository - Store exact restore commands and non-public backup target details.

No current application source files in this repository are required for the Vaultwarden deployment.

## 6. Testing

- **TEST-001**: Staging service boot test: `vaultwarden` starts successfully and listens on `0.0.0.0:$PORT`.
- **TEST-002**: Staging HTTPS test: staging URL loads the web vault over HTTPS.
- **TEST-003**: Production HTTPS test: `https://vault.thaarei.com` loads the web vault over HTTPS after Railway certificate provisioning.
- **TEST-004**: Domain correctness test: generated invite links use `https://vault.thaarei.com` in production.
- **TEST-005**: Signup-block test: uninvited public self-registration fails.
- **TEST-006**: Invite-flow test: invited test user receives email, creates an account, verifies email, and logs in.
- **TEST-007**: SMTP test: test email succeeds and logs do not expose SMTP credentials.
- **TEST-008**: Admin protection test: `/admin` requires the admin token or is disabled after setup.
- **TEST-009**: PostgreSQL persistence test: create a test item, redeploy the app, and confirm the item remains.
- **TEST-010**: `/data` persistence test: upload an attachment or equivalent data stored under `/data`, redeploy the app, and confirm it remains.
- **TEST-011**: Collection sharing test: a test item shared to each collection is visible only to assigned users.
- **TEST-012**: Least-privilege test: a user without access to `Production Access` cannot view that collection.
- **TEST-013**: Bitwarden browser extension test: login, autofill, create, update, and sync work against `https://vault.thaarei.com`.
- **TEST-014**: Bitwarden desktop app test: login and sync work against `https://vault.thaarei.com`.
- **TEST-015**: Bitwarden mobile app test: login and sync work against `https://vault.thaarei.com`.
- **TEST-016**: 2FA operating-policy test: all users with shared collection access have 2FA enabled before launch.
- **TEST-017**: WebAuthn/FIDO2 test: at least one admin validates WebAuthn after final domain activation if WebAuthn is used.
- **TEST-018**: Backup success test: database and `/data` backup artifacts are created and encrypted.
- **TEST-019**: Restore drill test: restore database and `/data` into staging and validate login plus shared item access.
- **TEST-020**: Log hygiene test: Railway logs contain no admin token, SMTP password, user password, database URL, backup key, or vault item secret.
- **TEST-021**: Upgrade rehearsal test: staging upgrade passes login, invite, sync, admin, backup, and restore checks before production upgrade.

## 7. Risks & Assumptions

- **RISK-001**: Vaultwarden is community-maintained and not official Bitwarden. Mitigation: accept explicitly for small-team use or choose official Bitwarden Enterprise.
- **RISK-002**: A compromised Railway operator account can access service variables and infrastructure. Mitigation: restrict Railway project access and require MFA.
- **RISK-003**: Incorrect `DOMAIN` breaks invite links, attachments, or FIDO2/WebAuthn. Mitigation: set exact final HTTPS domain before production onboarding and validate generated links.
- **RISK-004**: Loss of `/data` can break attachments or instance-specific material even if PostgreSQL survives. Mitigation: back up both PostgreSQL and `/data`.
- **RISK-005**: Railway-native backups alone may not satisfy disaster recovery if the project/account is unavailable. Mitigation: maintain encrypted off-platform backups.
- **RISK-006**: Public signup accidentally enabled could allow unauthorized account creation. Mitigation: enforce `SIGNUPS_ALLOWED=false` and test anonymous signup failure.
- **RISK-007**: Admin token stored in plaintext increases blast radius. Mitigation: store only Argon2id PHC hash in `ADMIN_TOKEN`.
- **RISK-008**: SMTP compromise can enable phishing or account-flow disruption. Mitigation: use scoped SMTP credentials, MFA on provider account, and credential rotation.
- **RISK-009**: Users may store highly sensitive client/regulated secrets without approval. Mitigation: publish allowed-use rules and use enterprise tooling if formal compliance is required.
- **RISK-010**: Image upgrades can introduce migrations or behavior changes. Mitigation: pin image versions/digests and rehearse upgrades in staging.
- **RISK-011**: The selected Vaultwarden health endpoint may differ by release. Mitigation: validate health endpoint in staging before configuring Railway health checks.
- **RISK-012**: Small-team manual 2FA enforcement can drift. Mitigation: monthly access review and use official Bitwarden Enterprise if hard policy enforcement is required.
- **ASSUMPTION-001**: The team accepts Vaultwarden for small-team internal password sharing.
- **ASSUMPTION-002**: `vault.thaarei.com` is the desired production hostname.
- **ASSUMPTION-003**: Railway is approved to host the password vault service and its PostgreSQL database.
- **ASSUMPTION-004**: The team has a working SMTP provider for invite and verification emails.
- **ASSUMPTION-005**: The team can maintain encrypted off-platform backups outside the Railway project.
- **ASSUMPTION-006**: The expected user count is small enough for one Vaultwarden app instance and one PostgreSQL database.

## 8. Related Specifications / Further Reading

- Railway official docs - Public networking and `PORT`: https://docs.railway.com/guides/public-networking
- Railway official docs - Custom domains: https://docs.railway.com/guides/public-networking#custom-domains
- Railway official docs - Variables and references: https://docs.railway.com/guides/variables
- Railway official docs - PostgreSQL/database services: https://docs.railway.com/guides/postgresql
- Railway official docs - Volumes and backups: https://docs.railway.com/guides/volumes
- Vaultwarden official repository: https://github.com/dani-garcia/vaultwarden
- Vaultwarden official wiki - PostgreSQL backend: https://github.com/dani-garcia/vaultwarden/wiki/Using-the-PostgreSQL-Backend
- Vaultwarden official wiki - SMTP configuration: https://github.com/dani-garcia/vaultwarden/wiki/SMTP-Configuration
- Vaultwarden official wiki - Admin page and hashed `ADMIN_TOKEN`: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page
- Vaultwarden official wiki - FIDO2/WebAuthn and `DOMAIN`: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-U2F-(and-FIDO2-WebAuthn)-authentication
- Bitwarden client apps: https://bitwarden.com/download/
- Internal reference: `AGENTS.md`
- Internal reference: `docs/internal-llm-gateway-implementation-roadmap.md`
- Internal reference: `docs/internal-llm-gateway-architecture-tech-stack.md`
- Internal reference: `docs/internal-llm-gateway-product-plan.md`
