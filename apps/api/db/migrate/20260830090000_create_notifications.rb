# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :recipient_user_account,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :user_accounts, on_delete: :cascade}
      table.string :notification_type, null: false, limit: 64
      table.string :status, null: false, default: "unread", limit: 16
      table.string :title, null: false, limit: 120
      table.string :description, null: false, limit: 240
      table.string :route, null: false, limit: 500
      table.string :idempotency_key, null: false, limit: 255
      table.datetime :occurred_at, null: false
      table.datetime :read_at
      table.timestamps
    end

    add_index :notifications, :idempotency_key, unique: true
    add_index :notifications,
      %i[recipient_user_account_id status occurred_at id],
      order: {occurred_at: :desc, id: :desc},
      name: "idx_notifications_recipient_status_order"
    add_check_constraint :notifications,
      "notification_type IN (" \
        "'profile_moderation_approved', 'profile_moderation_rejected', " \
        "'profile_moderation_hidden', 'profile_moderation_restored', " \
        "'profile_photo_moderation_approved', 'profile_photo_moderation_rejected', " \
        "'profile_photo_moderation_hidden', 'profile_photo_moderation_restored', " \
        "'portfolio_item_moderation_approved', 'portfolio_item_moderation_rejected', " \
        "'portfolio_item_moderation_hidden', 'portfolio_item_moderation_restored', " \
        "'verification_request_moderation_approved', 'verification_request_moderation_rejected', " \
        "'relationship_request_received', 'relationship_request_accepted', " \
        "'relationship_request_declined', 'quote_change_requested', 'quote_approved', " \
        "'quote_declined', 'service_completion_confirmed', 'service_completion_issue_reported', " \
        "'customer_recommendation_published')",
      name: "notifications_known_type"
    add_check_constraint :notifications,
      "status IN ('unread', 'read')",
      name: "notifications_known_status"
    add_check_constraint :notifications,
      "char_length(btrim(title)) BETWEEN 1 AND 120",
      name: "notifications_title_length"
    add_check_constraint :notifications,
      "char_length(btrim(description)) BETWEEN 1 AND 240",
      name: "notifications_description_length"
    add_check_constraint :notifications,
      "route ~ '^/[^[:space:]]*$'",
      name: "notifications_internal_route"
    add_check_constraint :notifications,
      "char_length(btrim(idempotency_key)) BETWEEN 1 AND 255",
      name: "notifications_idempotency_key_length"
    add_check_constraint :notifications,
      "(status = 'unread' AND read_at IS NULL) OR (status = 'read' AND read_at IS NOT NULL)",
      name: "notifications_read_state"
  end
end
