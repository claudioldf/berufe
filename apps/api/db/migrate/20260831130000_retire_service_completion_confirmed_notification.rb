# frozen_string_literal: true

class RetireServiceCompletionConfirmedNotification < ActiveRecord::Migration[8.1]
  def up
    # Fired only by the removed customer-confirmation path
    # (SharedQuoteCompletionResponder). See CollapseServiceJobCompletionStates.
    execute "DELETE FROM notifications WHERE notification_type = 'service_completion_confirmed'"

    remove_check_constraint :notifications, name: "notifications_known_type"
    add_check_constraint :notifications,
      <<~SQL.squish,
        notification_type IN (
          'profile_moderation_hidden',
          'profile_moderation_restored',
          'verification_request_moderation_approved',
          'verification_request_moderation_rejected',
          'relationship_request_received',
          'relationship_request_accepted',
          'relationship_request_declined',
          'quote_change_requested',
          'quote_approved',
          'quote_declined',
          'service_completion_issue_reported',
          'customer_recommendation_published'
        )
      SQL
      name: "notifications_known_type"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the notification-type retirement requires a database reset"
  end
end
