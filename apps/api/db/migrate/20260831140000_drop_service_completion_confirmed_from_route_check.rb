# frozen_string_literal: true

class DropServiceCompletionConfirmedFromRouteCheck < ActiveRecord::Migration[8.1]
  UUID_SQL_PATTERN = "[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"

  def up
    # RetireServiceCompletionConfirmedNotification dropped the type from
    # notifications_known_type but left this sibling constraint referencing
    # it in a CASE branch that can now never match.
    remove_check_constraint :notifications, name: "notifications_route_params_match_type"
    add_check_constraint :notifications, route_params_constraint, name: "notifications_route_params_match_type"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the notification-type retirement requires a database reset"
  end

  private

  def route_params_constraint
    <<~SQL.squish
      CASE
        WHEN notification_type IN ('quote_change_requested', 'quote_approved', 'quote_declined')
          THEN route_params = jsonb_build_object('quote_id', route_params ->> 'quote_id')
            AND COALESCE(route_params ->> 'quote_id' ~* '^#{UUID_SQL_PATTERN}$', false)
        WHEN notification_type = 'service_completion_issue_reported'
          THEN route_params = jsonb_build_object('service_job_id', route_params ->> 'service_job_id')
            AND COALESCE(route_params ->> 'service_job_id' ~* '^#{UUID_SQL_PATTERN}$', false)
        ELSE route_params = '{}'::jsonb
      END
    SQL
  end
end
