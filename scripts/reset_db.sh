#!/usr/bin/env bash
# Resets the local development database (drop, recreate, load schema) and
# re-runs db/seeds.rb. Destructive: all data in berufe_development is lost.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "==> Stopping web, api, and worker to release database connections"
docker compose stop web api worker

echo "==> Resetting database (drop, create, schema load, seed)"
docker compose run --rm migrate bin/rails db:reset

echo "==> Bringing the stack back up"
docker compose up -d

echo "==> Done"
