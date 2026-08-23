# Production deployment runbook

## Chosen MVP topology

Berufe runs in Railway's Virginia region (`us-east4-eqdc4a`) as three services:

| Service    | Runtime                                  | Public hostname     |
| ---------- | ---------------------------------------- | ------------------- |
| `web`      | Nuxt production image                    | `www.berufe.com.br` |
| `api`      | Rails plus one in-process GoodJob thread | `api.berufe.com.br` |
| `Postgres` | Railway managed PostgreSQL               | private only        |

Cloudflare provides authoritative DNS and two R2 buckets. Resend provides SMTP, Infobip
provides production SMS OTP, and separate Bugsnag projects receive privacy-scrubbed Rails
and browser exceptions.

There is no permanent staging service, Redis, separate production worker, or pull-request
environment. Local Compose and CI are the release-candidate environments. The expected
MVP platform cost is roughly USD 8–13/month; configure a USD 10 warning and USD 15 hard
usage limit in Railway. A hard limit can stop production, which is an accepted MVP tradeoff.

## Release model

- Feature and deployment work enters `master` through a pull request.
- A release is a pull request from `master` to the protected `production` branch.
- Railway watches only `production` and waits for GitHub CI before deploying.
- The Rails pre-deploy command runs `db:prepare` and the idempotent catalog seed before a
  new application deployment becomes active.
- Rollback normally means reverting the bad commit on `master`, merging the revert into
  `production`, and letting Railway redeploy. Never roll back a database migration by
  deleting production data; use a forward migration.

Required GitHub checks on both protected branches are:

- `Backend checks`
- `Frontend checks`
- `Compose integration`
- `Production image smoke test`

## 1. Railway project

Create and link one project named `berufe-production`. The committed
`.railway/railway.ts` defines the `api`, `web`, and managed PostgreSQL resources, connects
both applications to this repository's `production` branch, and defines their non-secret
variables, health checks, and Virginia replicas.

For a first setup, create and link the project plus two empty service shells before
applying IaC. This lets secrets be configured before a source can deploy:

```bash
railway init --name berufe-production
railway add --service api
railway add --service web
npm ci --prefix .railway
railway config plan
```

The initial plan is read-only. With the two empty shells present, it must propose one
database addition, updates to `api` and `web`, and no destructive changes. Do not apply it
until the preserved variables below exist, Sections 2–3 are complete, and the intended
release commit is already green on the protected `production` branch.

Railway IaC cannot register a new custom domain or express the **Wait for CI** switch. The
switch appears only after a GitHub source is connected, so the first IaC apply must target
a release commit whose GitHub checks already passed. Immediately after that apply, enable
Wait for CI for both services before any later push to `production`.

The IaC file manages the following `api` variable names. Values marked secret or
account-specific use `preserve()` and must be entered directly in Railway before the first
deployment; never commit them or paste them into an issue or chat transcript.

```dotenv
BERUFE_ENV=production
RAILS_ENV=production
PORT=8080
DATABASE_URL=${{Postgres.DATABASE_URL}}
SECRET_KEY_BASE=<secret: bin/rails secret>
RAILS_MAX_THREADS=3
DB_POOL=7
WEB_ORIGIN=https://www.berufe.com.br
API_PUBLIC_URL=https://api.berufe.com.br
PRODUCT_LAUNCH_DATE=<actual YYYY-MM-DD launch date>

SMS_OTP_ADAPTER=infobip
INFOBIP_BASE_URL=<production account base URL>
INFOBIP_API_KEY=<secret>
INFOBIP_2FA_APPLICATION_ID=<secret>
INFOBIP_2FA_MESSAGE_ID=<secret>
INFOBIP_SENDER=<registered sender>
INFOBIP_CREDENTIAL_SCOPE=production

MEDIA_STORAGE_ADAPTER=r2
R2_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com
R2_ACCESS_KEY_ID=<secret>
R2_SECRET_ACCESS_KEY=<secret>
R2_PUBLIC_BUCKET=berufe-production-public
R2_PRIVATE_BUCKET=berufe-production-private

SMTP_ADDRESS=smtp.resend.com
SMTP_PORT=587
SMTP_DOMAIN=berufe.com.br
SMTP_USERNAME=resend
SMTP_PASSWORD=<secret Resend API key>
SMTP_AUTHENTICATION=plain
SMTP_STARTTLS=true
MAIL_FROM=Berufe <nao-responda@berufe.com.br>

GOOD_JOB_EXECUTION_MODE=async
GOOD_JOB_MAX_THREADS=1
GOOD_JOB_QUEUES=default
BUGSNAG_API_KEY=<secret Rails project notifier key>
```

Set the following `web` variables:

```dotenv
PORT=8080
NUXT_API_INTERNAL_BASE_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:${{api.PORT}}
NUXT_PUBLIC_API_BASE_URL=https://api.berufe.com.br
NUXT_PUBLIC_SITE_URL=https://www.berufe.com.br
NUXT_PUBLIC_BUGSNAG_API_KEY=<web project notifier key>
```

The browser notifier key is intentionally public, but the Bugsnag account and management
credentials are not. The IaC pins both HTTP listeners to `PORT=8080`; Railway supplies
`RAILWAY_GIT_COMMIT_SHA` automatically.

## 2. Cloudflare R2

Activate R2 and create exactly these buckets:

- `berufe-production-public`
- `berufe-production-private`

Create one scoped object read/write API token limited to those two buckets. Record the S3
endpoint, access-key ID, and secret once in Railway. Do not enable public bucket listing.
Rails serves approved public media through controlled API routes; browsers upload only to
short-lived signed URLs for the private quarantine bucket.

Apply this CORS policy to the private bucket (and the public bucket if Cloudflare requires a
bucket-wide policy in the dashboard):

```json
[
  {
    "AllowedOrigins": ["https://www.berufe.com.br"],
    "AllowedMethods": ["PUT"],
    "AllowedHeaders": ["Content-Type"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

## 3. Email, SMS, and error reporting

In Resend, verify `berufe.com.br`, add every SPF/DKIM record Resend supplies, create a
send-only API key, and use it as `SMTP_PASSWORD`. Preserve any existing DNS records not
explicitly replaced.

In Infobip, use the approved production base URL, 2FA application, template, sender, and a
dedicated API key. Confirm sender registration, per-message cost, monthly spend alerts,
and the `2fa:pin:send` permission before the live smoke check.

Create separate Bugsnag projects named `berufe-api-production` and
`berufe-web-production`. Disable session tracking and user/IP collection in project
settings as defense in depth. Configure the operations owner to receive immediate alerts
for new unhandled production errors.

Enter every `preserve()` value in the empty Railway service shells and rerun the plan.
Apply only when it contains the intended database creation, service updates, and no
destructive changes. Applying connects the already-green `production` sources and starts
the first deployment. Then immediately enable Wait for CI on both services and register
the domains:

```bash
railway config plan
railway config apply
railway domain api.berufe.com.br --service api --port 8080
railway domain www.berufe.com.br --service web --port 8080
```

## 4. DNS cutover

Add `berufe.com.br` to Cloudflare without changing nameservers yet. Preserve the current
apex mail-suppression records unless Resend explicitly replaces them. Add Railway's exact
verification targets for:

- `www.berufe.com.br` on the `web` service
- `api.berufe.com.br` on the `api` service

Configure a permanent redirect from `https://berufe.com.br/*` to
`https://www.berufe.com.br/$1`. Then replace the Registro.br nameservers with the two
Cloudflare nameservers assigned to the zone. Wait until Cloudflare reports the zone active
and both Railway domains show valid certificates.

## 5. First release and verification

Merge the implementation pull request into `master`, then open and merge a release pull
request from `master` to `production`. Watch all four GitHub checks and both Railway
deployments. Do not bypass a failed health check or migration.

From an authenticated Railway shell on `api`, provision the first administrator:

```bash
EMAIL=<admin email> OPERATOR=<operator email> bin/rake admin:provision
```

The task prompts twice for a password without echoing it and writes an audit event.

Verify from a clean browser and a terminal:

```bash
curl --fail https://api.berufe.com.br/up
curl --fail https://www.berufe.com.br/health
curl --head https://berufe.com.br/
```

Then complete one controlled pass through each critical flow:

1. public search and professional profile rendering;
2. professional OTP start and verification on an authorized launch phone;
3. authenticated image upload, processing, and public display;
4. quote creation/sharing and recommendation email delivery;
5. administrator login, moderation, GoodJob dashboard, and logout.

Confirm no private request data appears in Railway or Bugsnag, the release SHA appears in
both Bugsnag projects, the GoodJob queue drains, and Railway spend alerts are active.

## 6. Backup and incident minimums

Before accepting real users, confirm Railway's PostgreSQL backup/retention settings and
record a restore-test owner and date. Exporting a backup is not a restore test.

If a release fails, keep DNS in place, disable the affected provider/flow if necessary,
merge a forward fix or revert through the normal release PR, and repeat the five critical
checks. Rotate any credential that may have reached logs or a client bundle.
