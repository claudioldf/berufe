# frozen_string_literal: true

class CreateAdminPasswordAccess < ActiveRecord::Migration[8.1]
  def change
    change_column_null :user_accounts, :phone_e164, true
    add_column :user_accounts, :email, :text
    add_column :user_accounts, :password_digest, :text
    add_index :user_accounts, :email, unique: true

    add_check_constraint :user_accounts,
      "email IS NULL OR (email = lower(email) AND email = btrim(email))",
      name: "user_accounts_normalized_email"
    add_check_constraint :user_accounts,
      <<~SQL.squish,
        (role = 'professional' AND phone_e164 IS NOT NULL AND email IS NULL AND password_digest IS NULL)
        OR
        (role = 'admin' AND phone_e164 IS NULL AND email IS NOT NULL AND email <> '' AND password_digest IS NOT NULL AND password_digest <> '')
      SQL
      name: "user_accounts_role_credentials"

    remove_check_constraint :application_sessions,
      name: "application_sessions_known_authentication_method"
    remove_check_constraint :application_sessions,
      name: "application_sessions_mfa_after_authentication"
    remove_column :application_sessions, :mfa_authenticated_at, :datetime
    change_column_default :application_sessions, :authentication_method, from: "sms_otp", to: nil
    add_check_constraint :application_sessions,
      "authentication_method IN ('sms_otp', 'password')",
      name: "application_sessions_known_authentication_method"

    create_table :admin_access_events, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :admin_user, type: :uuid, null: false, foreign_key: {to_table: :user_accounts}
      table.text :action, null: false
      table.text :operator_identifier, null: false
      table.text :request_id, null: false
      table.datetime :created_at, null: false
    end

    add_index :admin_access_events, %i[admin_user_id created_at]
    add_check_constraint :admin_access_events,
      "action IN ('provisioned', 'password_reset')",
      name: "admin_access_events_known_action"
    add_check_constraint :admin_access_events,
      "operator_identifier <> ''",
      name: "admin_access_events_operator_present"
    add_check_constraint :admin_access_events,
      "request_id ~ '^[A-Za-z0-9._-]{1,100}$'",
      name: "admin_access_events_request_id_format"

    create_table :admin_login_attempt_counters, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.text :scope, null: false
      table.text :subject_digest, null: false
      table.datetime :window_started_at, null: false
      table.integer :attempt_count, null: false, default: 0
      table.timestamps null: false
    end

    add_index :admin_login_attempt_counters,
      %i[scope subject_digest window_started_at],
      unique: true,
      name: "index_admin_login_attempts_on_subject_and_window"
    add_check_constraint :admin_login_attempt_counters,
      "scope IN ('email', 'ip')",
      name: "admin_login_attempt_counters_known_scope"
    add_check_constraint :admin_login_attempt_counters,
      "subject_digest ~ '^[0-9a-f]{64}$'",
      name: "admin_login_attempt_counters_digest_format"
    add_check_constraint :admin_login_attempt_counters,
      "attempt_count >= 0",
      name: "admin_login_attempt_counters_nonnegative_count"
  end
end
