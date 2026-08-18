# frozen_string_literal: true

class CreateVerificationFileAccessEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :verification_file_access_events, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :verification_file, type: :uuid, null: false, foreign_key: true
      table.references :admin_user, type: :uuid, null: false, foreign_key: {to_table: :user_accounts}
      table.text :action, null: false
      table.text :request_id, null: false
      table.datetime :created_at, null: false
    end

    add_index :verification_file_access_events, %i[verification_file_id created_at],
      name: "idx_verification_file_access_target_created"
    add_index :verification_file_access_events, %i[admin_user_id created_at],
      name: "idx_verification_file_access_admin_created"
    add_check_constraint :verification_file_access_events,
      "action = 'viewed'",
      name: "verification_file_access_known_action"
    add_check_constraint :verification_file_access_events,
      "request_id ~ '^[A-Za-z0-9._-]{1,100}$'",
      name: "verification_file_access_request_id_format"
  end
end
