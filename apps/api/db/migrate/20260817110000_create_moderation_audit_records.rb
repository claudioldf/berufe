# frozen_string_literal: true

class CreateModerationAuditRecords < ActiveRecord::Migration[8.1]
  TARGET_TYPES = %w[profile_revision profile_photo portfolio_item verification_request].freeze

  def change
    create_table :moderation_actions, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :admin_user, type: :uuid, null: false, foreign_key: {to_table: :user_accounts}
      table.text :target_type, null: false
      table.uuid :target_id, null: false
      table.text :action, null: false
      table.text :reason
      table.text :note
      table.text :request_id, null: false
      table.datetime :created_at, null: false
    end

    add_index :moderation_actions, %i[target_type target_id created_at],
      name: "idx_moderation_actions_target_created"
    add_index :moderation_actions, %i[admin_user_id created_at]
    add_check_constraint :moderation_actions,
      "target_type IN (#{TARGET_TYPES.map { |value| connection.quote(value) }.join(", ")})",
      name: "moderation_actions_known_target"
    add_check_constraint :moderation_actions,
      "action IN ('approved', 'rejected', 'hidden', 'restored')",
      name: "moderation_actions_known_action"
    add_check_constraint :moderation_actions,
      "action NOT IN ('rejected', 'hidden') OR reason IS NOT NULL AND char_length(btrim(reason)) BETWEEN 10 AND 500",
      name: "moderation_actions_required_reason"
    add_check_constraint :moderation_actions,
      "reason IS NULL OR char_length(btrim(reason)) BETWEEN 1 AND 500",
      name: "moderation_actions_reason_length"
    add_check_constraint :moderation_actions,
      "note IS NULL OR char_length(btrim(note)) BETWEEN 1 AND 500",
      name: "moderation_actions_note_length"
    add_check_constraint :moderation_actions,
      "request_id ~ '^[A-Za-z0-9._-]{1,100}$'",
      name: "moderation_actions_request_id_format"

    create_table :moderation_media_access_events, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :admin_user, type: :uuid, null: false, foreign_key: {to_table: :user_accounts}
      table.text :target_type, null: false
      table.uuid :target_id, null: false
      table.text :request_id, null: false
      table.datetime :created_at, null: false
    end

    add_index :moderation_media_access_events, %i[target_type target_id created_at],
      name: "idx_moderation_media_access_target_created"
    add_index :moderation_media_access_events, %i[admin_user_id created_at],
      name: "idx_moderation_media_access_admin_created"
    add_check_constraint :moderation_media_access_events,
      "target_type IN ('profile_photo', 'portfolio_item')",
      name: "moderation_media_access_known_target"
    add_check_constraint :moderation_media_access_events,
      "request_id ~ '^[A-Za-z0-9._-]{1,100}$'",
      name: "moderation_media_access_request_id_format"
  end
end
