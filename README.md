# Berufe

## Install

```bash
corepack enable
pnpm --dir apps/web install --frozen-lockfile
cd apps/api
bundle install
cd ../..
cp .env.example .env
```

Local development uses the fake SMS adapter and local storage by default. To
exercise Infobip locally, set `SMS_OTP_ADAPTER=infobip` and populate the
server-only Infobip values plus an E.164 `INFOBIP_TEST_NUMBERS` allowlist in
`.env`. Adapter selection is explicit and never falls back at runtime.

## Start

```bash
docker compose up --build
```

## Test

```bash
docker compose exec web pnpm test
docker compose exec api bundle exec rspec
```

## Lint

```bash
docker compose exec web pnpm check
docker compose exec api bin/check
```

These are the same non-writing checks used by CI. CI also verifies generated API types,
Rails boot and migrations, both Docker images, the Nuxt production build, and the complete
Compose stack. The production-image job additionally boots the release images with the
same environment shape used by Railway.

## Deploy

Production runs as Nuxt, Rails with in-process GoodJob, and PostgreSQL on Railway. The
release branch is `production`; normal development continues through pull requests into
`master`. See [the production deployment runbook](docs/PRODUCTION_DEPLOYMENT.md) for the
automated setup, required secrets, DNS cutover, verification, and rollback procedure.

## Format

```bash
docker compose exec web pnpm format
docker compose exec api bundle exec standardrb --fix
```

## Stop

```bash
docker compose down
```
