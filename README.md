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

## Start

```bash
docker compose up --build
```

## Test

```bash
docker compose exec web pnpm test
```

## Lint

```bash
docker compose exec web pnpm lint
docker compose exec api bin/brakeman --no-pager
```

## Format

```bash
docker compose exec web pnpm format
```

## Stop

```bash
docker compose down
```
