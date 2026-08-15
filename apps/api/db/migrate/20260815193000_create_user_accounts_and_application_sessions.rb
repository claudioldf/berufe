# frozen_string_literal: true

class CreateUserAccountsAndApplicationSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_accounts, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.text :phone_e164, null: false
      table.text :role, null: false, default: "professional"
      table.text :status, null: false, default: "active"
      table.datetime :terms_accepted_at
      table.datetime :last_login_at
      table.timestamps null: false
    end

    add_index :user_accounts, :phone_e164, unique: true
    add_index :user_accounts, %i[role status]
    add_check_constraint :user_accounts,
      "phone_e164 ~ '^\\+55[1-9][1-9]9[0-9]{8}$'",
      name: "user_accounts_brazilian_mobile_phone"
    add_check_constraint :user_accounts,
      "role IN ('professional', 'admin')",
      name: "user_accounts_known_role"
    add_check_constraint :user_accounts,
      "status IN ('active', 'suspended')",
      name: "user_accounts_known_status"

    create_table :application_sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :user_account, type: :uuid, null: false, foreign_key: true
      table.text :authentication_method, null: false, default: "sms_otp"
      table.text :token_digest, null: false
      table.text :csrf_token_digest, null: false
      table.datetime :authenticated_at, null: false
      table.datetime :mfa_authenticated_at
      table.datetime :last_active_at, null: false
      table.datetime :idle_expires_at, null: false
      table.datetime :absolute_expires_at, null: false
      table.datetime :revoked_at
      table.timestamps null: false
    end

    add_index :application_sessions, :token_digest, unique: true
    add_index :application_sessions, %i[user_account_id created_at]
    add_index :application_sessions, :idle_expires_at
    add_index :application_sessions, :absolute_expires_at
    add_check_constraint :application_sessions,
      "authentication_method = 'sms_otp'",
      name: "application_sessions_known_authentication_method"
    add_check_constraint :application_sessions,
      "token_digest ~ '^[0-9a-f]{64}$'",
      name: "application_sessions_token_digest_format"
    add_check_constraint :application_sessions,
      "csrf_token_digest ~ '^[0-9a-f]{64}$'",
      name: "application_sessions_csrf_digest_format"
    add_check_constraint :application_sessions,
      "last_active_at >= authenticated_at",
      name: "application_sessions_activity_after_authentication"
    add_check_constraint :application_sessions,
      "idle_expires_at > last_active_at",
      name: "application_sessions_idle_after_activity"
    add_check_constraint :application_sessions,
      "absolute_expires_at > authenticated_at",
      name: "application_sessions_absolute_after_authentication"
    add_check_constraint :application_sessions,
      "idle_expires_at <= absolute_expires_at",
      name: "application_sessions_idle_within_absolute"
    add_check_constraint :application_sessions,
      "mfa_authenticated_at IS NULL OR mfa_authenticated_at >= authenticated_at",
      name: "application_sessions_mfa_after_authentication"
    add_check_constraint :application_sessions,
      "revoked_at IS NULL OR revoked_at >= authenticated_at",
      name: "application_sessions_revoked_after_authentication"
  end
end
