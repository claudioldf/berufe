#!/usr/bin/env bash
# Resets the PRODUCTION database on Railway (drop, recreate, load schema, seed)
# and restarts the api service. Also empties the R2 private bucket, since every
# media reference in the database is about to disappear anyway. Destructive:
# all data in the linked Railway project's Postgres AND all objects in its R2
# private bucket are lost.
#
# `bin/rails db:reset` cannot be used here: PostgreSQL's `db:drop` issues
# DROP DATABASE while Puma and GoodJob hold live connections, so instead this
# drops and recreates the `public` schema through `bin/rails runner` (the
# production image has no `psql`), then reloads schema.rb and re-seeds.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

SERVICE="api"
ENVIRONMENT="production"
PROJECT="berufe-production"
ASSUME_YES=0
SKIP_ADMIN=0
SKIP_MEDIA=0
ADMIN_EMAIL=""
ADMIN_OPERATOR=""
API_HEALTH_URL="https://api.berufe.com.br/up"

usage() {
  cat <<'EOF'
Usage: scripts/reset_production_db.sh [options]

Resets the production database on Railway: empties the R2 private bucket,
drops and recreates the public schema, reloads schema.rb, re-seeds locations
and the service catalog, restarts the api service, and offers to
re-provision an administrator.

Options:
  --service NAME       Railway service to reset (default: api)
  --environment NAME   Railway environment (default: production)
  --project NAME       Expected Railway project name; aborts if the linked
                        project does not match (default: berufe-production)
  --yes                Skip the typed confirmation prompt
  --skip-media         Do not empty the R2 private bucket (media is left orphaned)
  --skip-admin         Do not offer to provision an administrator afterwards
  --admin-email EMAIL  Email to use if provisioning an administrator
  --admin-operator ID  Operator identifier to record for the provision audit
                        event (default: git config user.email)
  -h, --help           Show this help and exit
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --service)
      SERVICE="$2"
      shift 2
      ;;
    --environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --yes)
      ASSUME_YES=1
      shift
      ;;
    --skip-media)
      SKIP_MEDIA=1
      shift
      ;;
    --skip-admin)
      SKIP_ADMIN=1
      shift
      ;;
    --admin-email)
      ADMIN_EMAIL="$2"
      shift 2
      ;;
    --admin-operator)
      ADMIN_OPERATOR="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for bin in railway jq curl; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Missing required command: $bin" >&2
    exit 1
  fi
done

echo "==> Checking Railway session and linked project"
if ! railway whoami >/dev/null 2>&1; then
  echo "Not logged in to Railway. Run: railway login" >&2
  exit 1
fi

STATUS_JSON="$(railway status --json)"
LINKED_PROJECT="$(echo "$STATUS_JSON" | jq -r '.name')"
if [ "$LINKED_PROJECT" != "$PROJECT" ]; then
  echo "Linked Railway project is '$LINKED_PROJECT', expected '$PROJECT'. Aborting." >&2
  echo "Pass --project '$LINKED_PROJECT' if this is intentional." >&2
  exit 1
fi

echo "    Workspace/project : $(echo "$STATUS_JSON" | jq -r '.workspace.name // "unknown"') / $LINKED_PROJECT"
echo "    Environment       : $ENVIRONMENT"
echo "    Service           : $SERVICE"

echo "==> Current production data (blast radius)"
railway ssh --service "$SERVICE" --environment "$ENVIRONMENT" -- bash -lc '
  cd /app && bin/rails runner "
    puts %(database: #{ActiveRecord::Base.connection.current_database})
    {UserAccount => %(accounts), ProfessionalProfile => %(profiles), Quote => %(quotes),
     CustomerRecommendation => %(recommendations), MediaUpload => %(media)}.each do |model, label|
      puts %(#{label}: #{model.count})
    end
  "
'

if [ "$ASSUME_YES" -ne 1 ]; then
  echo
  echo "This will PERMANENTLY DELETE all data above from '$PROJECT' / '$ENVIRONMENT' / '$SERVICE'."
  if [ "$SKIP_MEDIA" -ne 1 ]; then
    echo "It will also PERMANENTLY DELETE every object in the R2 private bucket (profile"
    echo "photos, portfolio images, verification files)."
  else
    echo "Media already stored in R2 will not be deleted (--skip-media) and will become orphaned."
  fi
  read -r -p "Type the project name ($PROJECT) to continue: " CONFIRMATION
  if [ "$CONFIRMATION" != "$PROJECT" ]; then
    echo "Confirmation did not match. Aborting; nothing was changed." >&2
    exit 1
  fi
fi

if [ "$SKIP_MEDIA" -ne 1 ]; then
  echo "==> Emptying the R2 private bucket"
  railway ssh --service "$SERVICE" --environment "$ENVIRONMENT" -- bash -lc '
    set -euo pipefail
    cd /app
    bin/rails runner "
      if ENV[%(MEDIA_STORAGE_ADAPTER)] != %(r2)
        puts %(MEDIA_STORAGE_ADAPTER is not r2 here; skipping R2 cleanup.)
      else
        require %(aws-sdk-s3)
        client = Aws::S3::Client.new(
          endpoint: ENV.fetch(%(R2_ENDPOINT)),
          access_key_id: ENV.fetch(%(R2_ACCESS_KEY_ID)),
          secret_access_key: ENV.fetch(%(R2_SECRET_ACCESS_KEY)),
          region: %(auto),
          force_path_style: true
        )
        bucket = ENV.fetch(%(R2_PRIVATE_BUCKET))
        deleted = 0
        loop do
          response = client.list_objects_v2(bucket:)
          objects = response.contents.map { |object| {key: object.key} }
          break if objects.empty?

          deletion = client.delete_objects(bucket:, delete: {objects:, quiet: true})
          unless deletion.errors.empty?
            codes = deletion.errors.filter_map(&:code).uniq.join(%(, ))
            raise %(R2 rejected #{deletion.errors.length} object deletion(s): #{codes})
          end
          deleted += objects.length
        end
        puts %(Deleted #{deleted} object(s) from #{bucket})
      end
    "
  '
else
  echo "==> Skipping R2 cleanup (--skip-media)"
fi

echo "==> Dropping and recreating the public schema"
railway ssh --service "$SERVICE" --environment "$ENVIRONMENT" -- bash -lc '
  set -euo pipefail
  cd /app
  export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
  bin/rails runner "ActiveRecord::Base.connection.execute(<<~SQL)
    DROP SCHEMA public CASCADE;
    CREATE SCHEMA public;
    GRANT ALL ON SCHEMA public TO CURRENT_USER;
    GRANT USAGE ON SCHEMA public TO PUBLIC;
  SQL"
'

echo "==> Loading schema"
railway ssh --service "$SERVICE" --environment "$ENVIRONMENT" -- bash -lc '
  set -euo pipefail
  cd /app
  export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
  bin/rails db:schema:load
'

echo "==> Seeding locations and catalog"
railway ssh --service "$SERVICE" --environment "$ENVIRONMENT" -- bash -lc '
  set -euo pipefail
  cd /app
  bin/rails db:seed
'

echo "==> Restarting $SERVICE to clear stale connections"
railway service restart --service "$SERVICE" --environment "$ENVIRONMENT" --yes

echo "==> Waiting for $API_HEALTH_URL to come back"
HEALTHY=0
for _ in $(seq 1 18); do
  if curl --fail --silent --output /dev/null "$API_HEALTH_URL"; then
    HEALTHY=1
    break
  fi
  sleep 5
done
if [ "$HEALTHY" -eq 1 ]; then
  echo "    api is healthy"
else
  echo "    WARNING: api did not report healthy within 90s; check 'railway logs --service $SERVICE --environment $ENVIRONMENT'" >&2
fi

if [ "$SKIP_ADMIN" -ne 1 ]; then
  echo
  read -r -p "Provision an administrator now? [y/N] " PROVISION_ADMIN
  if [ "${PROVISION_ADMIN:-}" = "y" ] || [ "${PROVISION_ADMIN:-}" = "Y" ]; then
    if [ -z "$ADMIN_EMAIL" ]; then
      read -r -p "Administrator email: " ADMIN_EMAIL
    fi
    if [ -z "$ADMIN_OPERATOR" ]; then
      ADMIN_OPERATOR="$(git config user.email || true)"
      read -r -p "Operator identifier [$ADMIN_OPERATOR]: " OPERATOR_INPUT
      ADMIN_OPERATOR="${OPERATOR_INPUT:-$ADMIN_OPERATOR}"
    fi
    printf -v ADMIN_EMAIL_QUOTED '%q' "$ADMIN_EMAIL"
    printf -v ADMIN_OPERATOR_QUOTED '%q' "$ADMIN_OPERATOR"
    ADMIN_COMMAND="cd /app && EMAIL=$ADMIN_EMAIL_QUOTED OPERATOR=$ADMIN_OPERATOR_QUOTED bin/rake admin:provision"
    echo "==> Provisioning administrator $ADMIN_EMAIL (you will be prompted for a password)"
    if ! railway ssh --service "$SERVICE" --environment "$ENVIRONMENT" -- bash -lc \
      "$ADMIN_COMMAND"; then
      echo "Administrator provisioning failed or was interrupted. Run it yourself with:" >&2
      printf '  railway ssh --service %q --environment %q -- bash -lc %q\n' \
        "$SERVICE" "$ENVIRONMENT" "$ADMIN_COMMAND" >&2
    fi
  else
    echo "Skipped. Provision later with:"
    echo "  railway ssh --service $SERVICE --environment $ENVIRONMENT -- bash -lc \"cd /app && EMAIL=<email> OPERATOR=<operator> bin/rake admin:provision\""
  fi
fi

echo
echo "==> Done"
if [ "$SKIP_MEDIA" -eq 1 ]; then
  echo "Note: R2 objects (profile photos, portfolio images, verification files) were not deleted and are now orphaned."
fi
