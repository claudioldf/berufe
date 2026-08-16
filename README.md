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

Populate the server-only Infobip values and an E.164 `INFOBIP_TEST_NUMBERS`
allowlist in `.env` before starting the development stack. Automated tests
override the adapter and use `FAKE_SMS_OTP_CODE`; normal runtime traffic never
falls back to fake delivery.

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
Compose stack.

## Format

```bash
docker compose exec web pnpm format
docker compose exec api bundle exec standardrb --fix
```

## Stop

```bash
docker compose down
```
