# frozen_string_literal: true

class CreatePhoneOtpChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_challenges, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.text :public_token_digest, null: false
      table.text :infobip_challenge_id_ciphertext, null: false
      table.text :phone_e164_ciphertext, null: false
      table.datetime :expires_at, null: false
      table.datetime :consumed_at
      table.timestamps null: false
    end

    add_index :otp_challenges, :public_token_digest, unique: true
    add_index :otp_challenges, :expires_at
    add_check_constraint :otp_challenges,
      "btrim(public_token_digest) <> ''",
      name: "otp_challenges_public_token_digest_present"
    add_check_constraint :otp_challenges,
      "btrim(infobip_challenge_id_ciphertext) <> ''",
      name: "otp_challenges_provider_ciphertext_present"
    add_check_constraint :otp_challenges,
      "btrim(phone_e164_ciphertext) <> ''",
      name: "otp_challenges_phone_ciphertext_present"
    add_check_constraint :otp_challenges,
      "expires_at > created_at",
      name: "otp_challenges_expire_after_creation"
    add_check_constraint :otp_challenges,
      "consumed_at IS NULL OR consumed_at >= created_at",
      name: "otp_challenges_consumed_after_creation"

    create_table :otp_request_counters, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.text :scope_kind, null: false
      table.text :subject_digest, null: false
      table.datetime :window_started_at, null: false
      table.datetime :expires_at, null: false
      table.integer :request_count, limit: 2, null: false, default: 0
      table.datetime :last_requested_at
      table.timestamps null: false
    end

    add_index :otp_request_counters,
      %i[scope_kind subject_digest window_started_at],
      unique: true,
      name: "index_otp_counters_on_scope_subject_and_window"
    add_index :otp_request_counters, :expires_at
    add_check_constraint :otp_request_counters,
      "scope_kind IN ('phone', 'ip')",
      name: "otp_request_counters_known_scope"
    add_check_constraint :otp_request_counters,
      "subject_digest ~ '^[0-9a-f]{64}$'",
      name: "otp_request_counters_digest_format"
    add_check_constraint :otp_request_counters,
      "request_count >= 0",
      name: "otp_request_counters_nonnegative_count"
    add_check_constraint :otp_request_counters,
      "expires_at > window_started_at",
      name: "otp_request_counters_valid_window"
    add_check_constraint :otp_request_counters,
      "last_requested_at IS NULL OR last_requested_at >= window_started_at",
      name: "otp_request_counters_request_inside_window"
  end
end
