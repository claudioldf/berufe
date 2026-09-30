# frozen_string_literal: true

class AddEmailOtpAuthentication < ActiveRecord::Migration[8.1]
  def change
    add_column :otp_challenges, :channel, :text, null: false, default: "sms"
    add_column :otp_challenges, :email_ciphertext, :text
    add_column :otp_challenges, :email_code_digest, :text
    add_column :otp_challenges, :attempt_count, :integer, limit: 2, null: false, default: 0
    change_column_null :otp_challenges, :phone_e164_ciphertext, true
    change_column_null :otp_challenges, :infobip_challenge_id_ciphertext, true

    remove_check_constraint :otp_challenges, name: "otp_challenges_phone_ciphertext_present"
    remove_check_constraint :otp_challenges, name: "otp_challenges_provider_ciphertext_present"
    add_check_constraint :otp_challenges,
      <<~SQL.squish,
        (
          channel = 'sms'
          AND phone_e164_ciphertext IS NOT NULL
          AND btrim(phone_e164_ciphertext) <> ''
          AND infobip_challenge_id_ciphertext IS NOT NULL
          AND btrim(infobip_challenge_id_ciphertext) <> ''
          AND email_ciphertext IS NULL
          AND email_code_digest IS NULL
        )
        OR
        (
          channel = 'email'
          AND phone_e164_ciphertext IS NULL
          AND infobip_challenge_id_ciphertext IS NULL
          AND email_ciphertext IS NOT NULL
          AND btrim(email_ciphertext) <> ''
          AND email_code_digest ~ '^[0-9a-f]{64}$'
        )
      SQL
      name: "otp_challenges_channel_payload"
    add_check_constraint :otp_challenges,
      "attempt_count BETWEEN 0 AND 5",
      name: "otp_challenges_attempt_count_range"

    remove_check_constraint :otp_request_counters, name: "otp_request_counters_known_scope"
    add_check_constraint :otp_request_counters,
      "scope_kind IN ('phone', 'email', 'ip')",
      name: "otp_request_counters_known_scope"

    add_column :user_accounts, :email_verified_at, :datetime
    add_index :user_accounts, :email_verified_at
    remove_check_constraint :user_accounts, name: "user_accounts_role_credentials"
    remove_check_constraint :user_accounts, name: "user_accounts_registration_requires_verified_phone"
    add_check_constraint :user_accounts,
      <<~SQL.squish,
        (
          role = 'professional'
          AND (phone_e164 IS NOT NULL OR email IS NOT NULL)
          AND password_digest IS NULL
        )
        OR
        (
          role = 'admin'
          AND phone_e164 IS NULL
          AND email IS NOT NULL
          AND email <> ''
          AND password_digest IS NOT NULL
          AND password_digest <> ''
        )
      SQL
      name: "user_accounts_role_credentials"
    add_check_constraint :user_accounts,
      "phone_verified_at IS NULL OR phone_e164 IS NOT NULL",
      name: "user_accounts_phone_verification_has_phone"
    add_check_constraint :user_accounts,
      "email_verified_at IS NULL OR email IS NOT NULL",
      name: "user_accounts_email_verification_has_email"
    add_check_constraint :user_accounts,
      "registered_at IS NULL OR phone_verified_at IS NOT NULL OR email_verified_at IS NOT NULL",
      name: "user_accounts_registration_requires_verified_identity"

    remove_check_constraint :application_sessions,
      name: "application_sessions_known_authentication_method"
    add_check_constraint :application_sessions,
      "authentication_method IN ('sms_otp', 'email_otp', 'password')",
      name: "application_sessions_known_authentication_method"
  end
end
