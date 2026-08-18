# frozen_string_literal: true

class CreateVerificationRequestsAndFiles < ActiveRecord::Migration[8.1]
  STATUSES = %w[pending_review approved rejected expired].freeze

  def change
    create_table :verification_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional_profile, type: :uuid, null: false, foreign_key: true
      table.text :verification_type, null: false, default: "identity"
      table.text :status, null: false, default: "pending_review"
      table.datetime :submitted_at, null: false
      table.datetime :reviewed_at
      table.references :reviewed_by_user_account, type: :uuid, foreign_key: {to_table: :user_accounts}
      table.text :review_note
      table.text :public_label
      table.datetime :verified_at
      table.timestamps null: false
    end

    add_index :verification_requests,
      %i[professional_profile_id verification_type],
      unique: true,
      where: "status = 'pending_review'",
      name: "idx_verification_requests_one_pending_type"
    add_index :verification_requests,
      %i[professional_profile_id submitted_at id],
      order: {submitted_at: :desc, id: :desc},
      name: "idx_verification_requests_owner_newest"
    add_check_constraint :verification_requests,
      "verification_type = 'identity'",
      name: "verification_requests_identity_only"
    add_check_constraint :verification_requests,
      "status IN (#{STATUSES.map { |status| quote(status) }.join(", ")})",
      name: "verification_requests_known_status"

    create_table :verification_files, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :verification_request, type: :uuid, null: false, foreign_key: true, index: {unique: true}
      table.references :media_upload, type: :uuid, null: false, foreign_key: true, index: {unique: true}
      table.text :private_key, null: false
      table.text :content_type, null: false
      table.bigint :byte_size, null: false
      table.integer :width, null: false
      table.integer :height, null: false
      table.datetime :uploaded_at, null: false
      table.datetime :deleted_at
      table.timestamps null: false
    end

    add_index :verification_files, :private_key, unique: true
    add_check_constraint :verification_files,
      "content_type IN ('image/jpeg', 'image/png')",
      name: "verification_files_supported_content_type"
    add_check_constraint :verification_files,
      "byte_size > 0 AND width > 0 AND height > 0",
      name: "verification_files_valid_image"
  end
end
