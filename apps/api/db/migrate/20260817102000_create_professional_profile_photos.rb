# frozen_string_literal: true

class CreateProfessionalProfilePhotos < ActiveRecord::Migration[8.1]
  STATUSES = %w[pending_review approved rejected hidden superseded].freeze

  def change
    add_column :media_uploads, :sanitized_content_type, :text
    add_check_constraint :media_uploads,
      "sanitized_content_type IS NULL OR sanitized_content_type IN ('image/jpeg', 'image/png')",
      name: "media_uploads_supported_sanitized_type"

    create_table :professional_profile_photos, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional_profile, type: :uuid, null: false, foreign_key: true
      table.references :media_upload, type: :uuid, null: false, foreign_key: true, index: {unique: true}
      table.text :status, null: false, default: "pending_review"
      table.text :private_key, null: false
      table.text :public_key
      table.text :content_type, null: false, default: "image/jpeg"
      table.bigint :byte_size, null: false
      table.integer :width, null: false
      table.integer :height, null: false
      table.datetime :submitted_at, null: false
      table.datetime :reviewed_at
      table.datetime :hidden_at
      table.text :rejection_reason
      table.timestamps null: false
    end

    add_index :professional_profile_photos, :private_key, unique: true
    add_index :professional_profile_photos, :public_key, unique: true, where: "public_key IS NOT NULL"
    add_index :professional_profile_photos,
      :professional_profile_id,
      unique: true,
      where: "status = 'pending_review'",
      name: "idx_profile_photos_one_pending"
    add_index :professional_profile_photos,
      :professional_profile_id,
      unique: true,
      where: "status = 'approved'",
      name: "idx_profile_photos_one_approved"
    add_check_constraint :professional_profile_photos,
      "status IN (#{STATUSES.map { |status| quote(status) }.join(", ")})",
      name: "professional_profile_photos_known_status"
    add_check_constraint :professional_profile_photos,
      "content_type = 'image/jpeg'",
      name: "professional_profile_photos_jpeg_only"
    add_check_constraint :professional_profile_photos,
      "byte_size > 0 AND width BETWEEN 1 AND 1024 AND height BETWEEN 1 AND 1536",
      name: "professional_profile_photos_valid_variant"

    add_column :professional_profiles, :working_photo_id, :uuid
    add_column :professional_profiles, :published_photo_id, :uuid
    add_foreign_key :professional_profiles,
      :professional_profile_photos,
      column: :working_photo_id
    add_foreign_key :professional_profiles,
      :professional_profile_photos,
      column: :published_photo_id
    add_index :professional_profiles, :working_photo_id, unique: true
    add_index :professional_profiles, :published_photo_id, unique: true
  end
end
