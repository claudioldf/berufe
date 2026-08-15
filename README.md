# Berufe

## Install

```bash
corepack enable
pnpm --dir apps/web install --frozen-lockfile
cd apps/api
bundle install
```

## Start

```bash
pnpm --dir apps/web dev
```

```bash
cd apps/api
bin/rails server --port 3001
```

## Test

```bash
pnpm --dir apps/web test
```

## Lint

```bash
pnpm --dir apps/web lint
cd apps/api
bin/brakeman --no-pager
```

## Format

```bash
pnpm --dir apps/web format
```

## Stop

```text
Ctrl+C
```
