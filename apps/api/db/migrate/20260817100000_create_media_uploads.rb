# frozen_string_literal: true

class CreateMediaUploads < ActiveRecord::Migration[8.1]
  PURPOSES = %w[profile_photo portfolio_image verification_identity].freeze
  STATES = %w[authorized uploaded processing processed failed attached expired].freeze

  def change
    create_table :media_uploads, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional_profile, type: :uuid, null: false, foreign_key: true
      table.text :purpose, null: false
      table.text :state, null: false, default: "authorized"
      table.text :declared_content_type, null: false
      table.bigint :declared_byte_size, null: false
      table.text :actual_content_type
      table.bigint :actual_byte_size
      table.bigint :sanitized_byte_size
      table.integer :width
      table.integer :height
      table.text :quarantine_key, null: false
      table.text :sanitized_key
      table.text :failure_code
      table.integer :processing_attempts, null: false, default: 0
      table.datetime :authorization_expires_at, null: false
      table.datetime :uploaded_at
      table.datetime :processing_started_at
      table.datetime :processed_at
      table.datetime :attached_at
      table.timestamps null: false
    end

    add_index :media_uploads, :quarantine_key, unique: true
    add_index :media_uploads, :sanitized_key, unique: true, where: "sanitized_key IS NOT NULL"
    add_index :media_uploads, %i[professional_profile_id purpose created_at]
    add_index :media_uploads,
      :authorization_expires_at,
      where: "state = 'authorized'",
      name: "idx_media_uploads_expiring_authorizations"
    add_check_constraint :media_uploads,
      "purpose IN (#{PURPOSES.map { |purpose| quote(purpose) }.join(", ")})",
      name: "media_uploads_known_purpose"
    add_check_constraint :media_uploads,
      "state IN (#{STATES.map { |state| quote(state) }.join(", ")})",
      name: "media_uploads_known_state"
    add_check_constraint :media_uploads,
      "declared_content_type IN ('image/jpeg', 'image/png')",
      name: "media_uploads_supported_declared_type"
    add_check_constraint :media_uploads,
      "declared_byte_size BETWEEN 1 AND 10485760",
      name: "media_uploads_declared_size_range"
    add_check_constraint :media_uploads,
      "actual_byte_size IS NULL OR actual_byte_size BETWEEN 1 AND 10485760",
      name: "media_uploads_actual_size_range"
    add_check_constraint :media_uploads,
      "processing_attempts >= 0",
      name: "media_uploads_nonnegative_attempts"
    add_check_constraint :media_uploads,
      "(width IS NULL AND height IS NULL) OR (width > 0 AND height > 0)",
      name: "media_uploads_valid_dimensions"
  end
end
