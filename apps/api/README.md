# Berufe API configuration

The deployment environment is selected with `BERUFE_ENV`. Rails refuses to boot when its environment/adapters do not match this matrix or a required variable is blank.

| `BERUFE_ENV` | SMS OTP    | Media storage | Intended use                                      |
| ------------ | ---------- | ------------- | ------------------------------------------------- |
| `local`      | fake       | local disk    | Docker Compose development with synthetic data    |
| `test`       | fake       | local disk    | automated tests with synthetic data               |
| `preview`    | fake       | local disk    | isolated pull-request mocks; no shared staging API |
| `staging`    | fake       | R2            | stable isolated staging                           |
| `integration` | Infobip    | R2            | explicit restricted-provider checks only          |
| `production` | Infobip    | R2            | live service                                      |

Only values prefixed `NUXT_PUBLIC_` are exposed through Nuxt's public runtime configuration. Database, Infobip, R2, Rails, and Bugsnag credentials are server-only and belong in the relevant hosting platform's secret store.

## Infobip production prerequisite

Infobip is used only to synchronously start and verify professional SMS OTP challenges. Rails remains the owner of accounts, sessions, roles, authorization, logout/revocation, and administrator TOTP MFA.

Before enabling production delivery:

1. Assign a Berufe owner for the Infobip account, API key, spend, and rotation process. Use a dedicated production API key, 2FA application ID, and message-template ID.
2. Complete Infobip's Brazilian sender-registration and Letter of Authorization process for `INFOBIP_SENDER`; do not launch while the sender is unregistered.
3. Record the approved sender, application/message-template identifiers, per-message price, monthly spend cap, provider throughput/delivery limits, and escalation contact in the restricted operations inventory.
4. Confirm the challenge flow starts with `POST /2fa/2/pin` and verifies with `POST /2fa/2/pin/{pinId}/verify`. The provider challenge reference stays server-side and OTP values are never stored or logged by Berufe.
5. Configure Rails cooldowns and daily phone/IP allowances in addition to Infobip limits. Delivery rejection returns a safe client error; rate limiting preserves `Retry-After`; timeout, malformed response, or provider failure returns a safe unavailable result. Existing Rails sessions remain usable during a provider outage.

Local, preview, and stable staging must keep `SMS_OTP_ADAPTER=fake` and receive no Infobip credential. Explicit integration checks use `BERUFE_ENV=integration`, a separate restricted Infobip application/profile, `INFOBIP_CREDENTIAL_SCOPE=integration`, synthetic allowlisted `INFOBIP_TEST_NUMBERS`, and never production credentials or real-user data. Production requires `INFOBIP_CREDENTIAL_SCOPE=production`.

## R2 boundary

Stable staging, integration, and production use dedicated Cloudflare R2 credentials and the configured public/private buckets. Local and automated tests write under `LOCAL_STORAGE_ROOT`; they do not require R2 or an object-storage emulator.

## Database lifecycle

From the repository root, recreate development data and verify the isolated test database with:

```bash
docker compose run --rm api bin/rails db:drop db:create db:migrate db:seed
docker compose run --rm -e RAILS_ENV=test -e BERUFE_ENV=test api bin/rails db:drop db:create db:migrate
```

Committed Rails migrations are the only supported way to change the schema. Application generators use UUID primary keys, Rails stores time in UTC, and PostgreSQL maps Rails `datetime` columns to `timestamptz`.
