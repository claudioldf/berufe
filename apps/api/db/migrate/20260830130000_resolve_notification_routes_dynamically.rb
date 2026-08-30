# frozen_string_literal: true

class ResolveNotificationRoutesDynamically < ActiveRecord::Migration[8.1]
  QUOTE_TYPES = %w[quote_change_requested quote_approved quote_declined].freeze
  SERVICE_JOB_TYPES = %w[service_completion_confirmed service_completion_issue_reported].freeze
  UUID_SQL_PATTERN = "[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"
  PARAMS_CONSTRAINT = "notifications_route_params_match_type"

  def up
    add_column :notifications, :route_params, :jsonb, null: false, default: {}

    reject_unparseable_legacy_routes!
    backfill_route_params!

    add_check_constraint :notifications,
      "jsonb_typeof(route_params) = 'object'",
      name: "notifications_route_params_object"
    add_check_constraint :notifications, route_params_constraint, name: PARAMS_CONSTRAINT
    remove_check_constraint :notifications, name: "notifications_internal_route"
    remove_column :notifications, :route
  end

  def down
    add_column :notifications, :route, :string, limit: 500
    execute <<~SQL.squish
      UPDATE notifications
      SET route = CASE
        WHEN notification_type IN (#{quoted(QUOTE_TYPES)})
          THEN '/app/professional/quotes/new?quote=' || (route_params ->> 'quote_id')
        WHEN notification_type IN (#{quoted(SERVICE_JOB_TYPES)})
          THEN '/app/professional/services/' || (route_params ->> 'service_job_id')
        WHEN notification_type LIKE 'portfolio_item_moderation_%'
          THEN '/app/professional/profile?tab=portfolio'
        WHEN notification_type LIKE 'verification_request_moderation_%'
          THEN '/app/professional/profile?tab=verificacoes'
        WHEN notification_type LIKE 'relationship_request_%'
          THEN '/app/professional/profile?tab=relacoes'
        WHEN notification_type = 'customer_recommendation_published'
          THEN COALESCE(
            '/profissionais/' || (
              SELECT professional_profiles.public_slug
              FROM professional_profiles
              WHERE professional_profiles.user_account_id = notifications.recipient_user_account_id
            ) || '#customer-recommendations-title',
            '/app/professional/profile'
          )
        ELSE '/app/professional/profile'
      END
    SQL
    change_column_null :notifications, :route, false
    add_check_constraint :notifications,
      "route ~ '^/[^[:space:]]*$'",
      name: "notifications_internal_route"

    remove_check_constraint :notifications, name: PARAMS_CONSTRAINT
    remove_check_constraint :notifications, name: "notifications_route_params_object"
    remove_column :notifications, :route_params
  end

  private

  def reject_unparseable_legacy_routes!
    execute <<~SQL
      DO $migration$
      BEGIN
        IF EXISTS (
          SELECT 1
          FROM notifications
          WHERE notification_type IN (#{quoted(QUOTE_TYPES)})
            AND route !~* '^/app/professional/quotes/new[?]quote=#{UUID_SQL_PATTERN}$'
        ) THEN
          RAISE EXCEPTION 'Cannot derive quote_id from an existing notification route';
        END IF;

        IF EXISTS (
          SELECT 1
          FROM notifications
          WHERE notification_type IN (#{quoted(SERVICE_JOB_TYPES)})
            AND route !~* '^/app/professional/services/#{UUID_SQL_PATTERN}$'
        ) THEN
          RAISE EXCEPTION 'Cannot derive service_job_id from an existing notification route';
        END IF;
      END
      $migration$;
    SQL
  end

  def backfill_route_params!
    execute <<~SQL.squish
      UPDATE notifications
      SET route_params = jsonb_build_object(
        'quote_id',
        substring(lower(route) FROM 'quote=(#{UUID_SQL_PATTERN})$')
      )
      WHERE notification_type IN (#{quoted(QUOTE_TYPES)})
    SQL
    execute <<~SQL.squish
      UPDATE notifications
      SET route_params = jsonb_build_object(
        'service_job_id',
        substring(lower(route) FROM '/services/(#{UUID_SQL_PATTERN})$')
      )
      WHERE notification_type IN (#{quoted(SERVICE_JOB_TYPES)})
    SQL
  end

  def route_params_constraint
    <<~SQL.squish
      CASE
        WHEN notification_type IN (#{quoted(QUOTE_TYPES)}) THEN
          route_params = jsonb_build_object('quote_id', route_params ->> 'quote_id')
          AND COALESCE((route_params ->> 'quote_id') ~* '^#{UUID_SQL_PATTERN}$', FALSE)
        WHEN notification_type IN (#{quoted(SERVICE_JOB_TYPES)}) THEN
          route_params = jsonb_build_object('service_job_id', route_params ->> 'service_job_id')
          AND COALESCE((route_params ->> 'service_job_id') ~* '^#{UUID_SQL_PATTERN}$', FALSE)
        ELSE route_params = '{}'::jsonb
      END
    SQL
  end

  def quoted(values)
    values.map { |value| connection.quote(value) }.join(", ")
  end
end
