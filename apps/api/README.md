# Berufe API configuration

The deployment environment is selected with `BERUFE_ENV`. Rails refuses to boot when its environment/adapters do not match this matrix or a required variable is blank.

| `BERUFE_ENV`  | SMS OTP | Media storage | Intended use                                        |
| ------------- | ------- | ------------- | --------------------------------------------------- |
| `local`       | Infobip | local disk    | Docker Compose development with allowlisted SMS     |
| `test`        | fake    | local disk    | automated tests with synthetic data                 |
| `preview`     | Infobip | local disk    | isolated pull-request previews with allowlisted SMS |
| `staging`     | Infobip | R2            | stable staging with allowlisted SMS                 |
| `integration` | Infobip | R2            | restricted-provider checks                          |
| `production`  | Infobip | R2            | live service                                        |

Only values prefixed `NUXT_PUBLIC_` are exposed through Nuxt's public runtime configuration. Database, Infobip, R2, Rails, and Bugsnag credentials are server-only and belong in the relevant hosting platform's secret store.

## Recommendation email prerequisite

When a client confirms completion, the worker sends a personal recommendation
link to the email snapshot stored on the approved quote. Staging, integration,
and production refuse to boot without `SMTP_ADDRESS`, `SMTP_PORT`,
`SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_AUTHENTICATION`,
`SMTP_STARTTLS`, and `MAIL_FROM`.

The `default` GoodJob queue must be running. Delivery is retry-safe, the job
argument contains only the recommendation-request UUID, and the bearer link is
unavailable until SMTP delivery succeeds. Local development writes messages to
`apps/api/tmp/mails`; automated tests use Action Mailer's test adapter.

## Infobip production prerequisite

Infobip is used only to synchronously start and verify professional SMS OTP challenges. Rails remains the owner of accounts, sessions, roles, authorization, logout/revocation, and administrator email/password authentication.

Before enabling production delivery:

1. Assign a Berufe owner for the Infobip account, API key, spend, and rotation process. Use a dedicated production API key with at least the `2fa:pin:send` scope, 2FA application ID, and message-template ID.
2. Complete Infobip's Brazilian sender-registration and Letter of Authorization process for `INFOBIP_SENDER`; do not launch while the sender is unregistered.
3. Record the approved sender, application/message-template identifiers, per-message price, monthly spend cap, provider throughput/delivery limits, and escalation contact in the restricted operations inventory.

4. Confirm the challenge flow starts with `POST /2fa/2/pin` and verifies with `POST /2fa/2/pin/{pinId}/verify`. The provider challenge reference stays server-side and OTP values are never stored or logged by Berufe.
5. Configure Rails cooldowns and daily phone/IP allowances in addition to Infobip limits. Delivery rejection returns a safe client error; rate limiting preserves `Retry-After`; timeout, malformed response, or provider failure returns a safe unavailable result. Existing Rails sessions remain usable during a provider outage.

Every environment except automated test uses Infobip. Local, preview, stable staging, and integration use a separate restricted Infobip application/profile, require `INFOBIP_CREDENTIAL_SCOPE=integration`, and may send only to normalized Brazilian E.164 numbers listed in `INFOBIP_TEST_NUMBERS`. They never receive production credentials or fall back to fake delivery. Production requires `INFOBIP_CREDENTIAL_SCOPE=production` and does not apply the non-production recipient allowlist.

## Administrator accounts

Administrators do not use professional SMS login or public registration. `AdminSeed` is the only application service allowed to create an administrator. In non-production environments, `db:seed` idempotently creates `ADMIN_AUTH_EMAIL` / `ADMIN_AUTH_PASSWORD`, defaulting to `admin@berufe.com.br` / `@Qwer1234`. The service refuses to run in production and logs a warning instead; there is no production administrator-creation task or API route.

Reset a password with the same operator attribution:

```bash
docker compose exec -e EMAIL=admin@example.com -e OPERATOR=ops@example.com api bin/rake admin:reset_password
```

The reset operation prompts for the password without echoing it and appends an administrator access event. Password reset revokes all existing sessions for the account. The browser login is `/app/admin/login`.

## Infobip smoke check

After changing Infobip settings, recreate the API process and call the provider service directly with the first allowlisted number:

```bash
docker compose up -d --force-recreate api worker
docker compose exec -T api bin/infobip-smoke
```

This non-production-only command sends one real SMS to the first number in `INFOBIP_TEST_NUMBERS` and bypasses the controller, database challenge record, and Rails rate limiter. It prints neither the destination nor the provider reference. Confirm receipt on the allowlisted phone and the corresponding request in Infobip's logs.

An HTTP `403` in the privacy-safe Rails outcome log means the API key or account is not authorized to send 2FA PINs. Grant the dedicated key the `2fa:pin:send` scope and confirm that the configured 2FA application/profile is enabled before rerunning the smoke check.

## R2 boundary

Stable staging, integration, and production use dedicated Cloudflare R2 credentials and the configured public/private buckets. Local and automated tests write under `LOCAL_STORAGE_ROOT`; they do not require R2 or an object-storage emulator.

## Database lifecycle

From the repository root, recreate development data and verify the isolated test database with:

```bash
docker compose run --rm api bin/rails db:drop db:create db:migrate db:seed
docker compose run --rm -e RAILS_ENV=test -e BERUFE_ENV=test api bin/rails db:drop db:create db:migrate
```

Committed Rails migrations are the only supported way to change the schema. Application generators use UUID primary keys, Rails stores time in UTC, and PostgreSQL maps Rails `datetime` columns to `timestamptz`.

## GoodJob worker

The API enqueues with GoodJob in `external` mode and the dedicated worker processes one `default` queue. That queue is reserved for image sanitization/processing, expired counter/token/file/session cleanup, aggregate maintenance, and nonurgent provider reconciliation. Interactive OTP initiation is synchronous and must never be enqueued.

The database connection budget is:

```text
(API replicas × API pool) + (worker replicas × worker pool) + migration/admin allowance
```

With one API and one worker, reserve 15 connections: five for Rails, five for GoodJob, and five for migrations/administration. Select a managed PostgreSQL plan with at least 20 available connections and recalculate before adding replicas or threads.

The worker exposes `:7001/status`, `:7001/status/started`, and `:7001/status/connected`; Compose requires both started and connected status. The GoodJob dashboard is mounted at `/admin/jobs` only when the request contains an active Rails-owned administrator password session.

Every job carries a validated web request ID or a generated correlation UUID. Job implementations must be retry-safe: check current state, use database constraints/transactions or idempotent writes, and treat already-completed work as success. Never place OTPs, phone numbers, raw tokens, signed URLs, customer details, or file contents in job arguments or logs.

The harmless foundation probe can validate normal processing and one retry:

```bash
docker compose exec api bin/rails runner 'FoundationProbeJob.perform_later(probe_id: SecureRandom.uuid)'
docker compose exec api bin/rails runner 'FoundationProbeJob.perform_later(probe_id: SecureRandom.uuid, fail_once: true)'
```
