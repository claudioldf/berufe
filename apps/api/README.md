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

Only values prefixed `NUXT_PUBLIC_` are exposed through Nuxt's public runtime configuration. Database, Infobip, R2, MaxMind, Rails, and Bugsnag credentials are server-only and belong in the relevant hosting platform's secret store.

## Approximate search location

Rails resolves the visitor's approximate city and state through MaxMind GeoLite web
services. Staging, integration, and production require `MAXMIND_ACCOUNT_ID` and
`MAXMIND_LICENSE_KEY`; both belong only in the API service's secret store. The browser and
Nuxt public runtime configuration must never receive either value.

The client is pinned to `geolite.info`, so it does not accidentally call MaxMind's paid
`geoip.maxmind.com` host. Rails prefers its public request peer and accepts a server-forwarded
`X-Real-IP` value only when that peer is private. It ignores non-public or malformed
addresses and never places the raw address in its location cache. Supported results are
cached for up to 24 hours by a keyed digest; provider failures are cached for five minutes.
Any unresolved or unsupported city becomes the disclosed Joinville launch-market fallback.

## Recommendation email prerequisite

When a professional marks a service completed, the worker schedules a
personal recommendation link to the email snapshot stored on the approved
quote (a WhatsApp handoff covers quotes with no email instead). Delivery goes
through one of two `MAIL_ADAPTER` values:

- `resend` — Resend's HTTP API (`lib/berufe/resend_mail_client.rb`), required
  for staging, integration, and production, which refuse to boot with any
  other adapter. They also require `RESEND_API_KEY` and `MAIL_FROM`. Railway
  blocks outbound SMTP below its Pro plan — a connection to
  `smtp.resend.com:587` times out (`Net::OpenTimeout`) rather than being
  refused — so these environments cannot use `smtp`.
- `smtp` — plain Action Mailer SMTP, the default locally. Refuses to boot
  without `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`,
  `SMTP_PASSWORD`, `SMTP_AUTHENTICATION`, `SMTP_STARTTLS`, and `MAIL_FROM`
  whenever it applies to a deployed environment (it does not for `preview`).

The `default` GoodJob queue must be running. Delivery is retry-safe, the job
argument contains only the recommendation-request UUID, and the bearer link is
unavailable until delivery succeeds. Local/development mail always goes
through MailCatcher (the `mailcatcher` Compose service) — view it at
<http://localhost:1080>; nothing reaches a real inbox. Automated tests use
Action Mailer's test adapter instead.

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

Administrators do not use professional SMS login or public registration. In non-production environments, `db:seed` idempotently creates `ADMIN_AUTH_EMAIL` / `ADMIN_AUTH_PASSWORD`, defaulting to `admin@berufe.com.br` / `@Qwer1234`. The seed service refuses production execution. Production administrators are created only through the interactive console task below; there is no administrator-creation API route.

Provision the first production administrator from an authenticated Railway shell. The
password is read from the terminal without echoing and is not placed in shell history:

```bash
EMAIL=admin@example.com OPERATOR=ops@example.com bin/rake admin:provision
```

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

## IBGE location import

`locations:import_ibge` upserts states and municipalities from the official
[IBGE Localidades API](https://servicodados.ibge.gov.br/api/v1/localidades) and
neighborhoods from the official 2022 Census neighborhood DBF archives. The Localidades
API does not publish a neighborhood endpoint, so both sources are required. States for
which IBGE publishes no neighborhood archive are retained with all their municipalities
and an empty neighborhood list.

Import the entire country, selected states, or selected seven-digit municipality codes:

```bash
docker compose run --rm api bin/rake locations:import_ibge
docker compose run --rm -e IBGE_UFS=SC,PR api bin/rake locations:import_ibge
docker compose run --rm -e IBGE_CITY_CODES=4209102,4202404,4106902,4202008 api bin/rake locations:import_ibge
```

`db:seed` remains network-independent: it imports the committed official snapshot for
Joinville/SC, Blumenau/SC, Curitiba/PR, and Balneário Camboriú/SC before creating demo
professionals.

## GoodJob execution

Local Compose uses GoodJob in `external` mode with a dedicated worker so worker health and
failure behavior remain easy to exercise. The MVP production service uses `async` mode and
runs one GoodJob thread inside the single Rails process. This removes a separately billed
worker while retaining PostgreSQL-backed durability. The `default` queue is reserved for
image sanitization/processing, expired counter/token/file/session cleanup, aggregate
maintenance, and nonurgent provider reconciliation. Interactive OTP initiation is
synchronous and must never be enqueued.

The general database connection budget is:

```text
(API replicas × API pool) + (worker replicas × worker pool) + migration/admin allowance
```

The production MVP sets `RAILS_MAX_THREADS=3`, `GOOD_JOB_MAX_THREADS=1`, and `DB_POOL=7`.
That gives the single Rails/GoodJob process enough connections plus a small margin. Keep at
least five additional database connections available for Railway migrations and operator
access. Recalculate before adding replicas or threads.

The external worker exposes `:7001/status`, `:7001/status/started`, and
`:7001/status/connected`; local Compose requires both started and connected status.
Production instead uses the Rails `/up` health check and observes queue health through the
administrator-only GoodJob dashboard at `/admin/jobs`.

Every job carries a validated web request ID or a generated correlation UUID. Job implementations must be retry-safe: check current state, use database constraints/transactions or idempotent writes, and treat already-completed work as success. Never place OTPs, phone numbers, raw tokens, signed URLs, customer details, or file contents in job arguments or logs.

The harmless foundation probe can validate normal processing and one retry:

```bash
docker compose exec api bin/rails runner 'FoundationProbeJob.perform_later(probe_id: SecureRandom.uuid)'
docker compose exec api bin/rails runner 'FoundationProbeJob.perform_later(probe_id: SecureRandom.uuid, fail_once: true)'
```
