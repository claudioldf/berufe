# frozen_string_literal: true

class RestrictModerationToIdentityVerification < ActiveRecord::Migration[8.1]
  def up
    # This change intentionally targets the pre-launch database reset. Existing
    # polymorphic moderation history has no safe meaning in the simplified
    # model, so it is discarded instead of guessed at during migration.
    execute "TRUNCATE TABLE moderation_actions"
    execute <<~SQL
      DELETE FROM notifications
      WHERE notification_type IN (
        'profile_moderation_approved',
        'profile_moderation_rejected',
        'profile_photo_moderation_approved',
        'profile_photo_moderation_rejected',
        'profile_photo_moderation_hidden',
        'profile_photo_moderation_restored',
        'portfolio_item_moderation_approved',
        'portfolio_item_moderation_rejected',
        'portfolio_item_moderation_hidden',
        'portfolio_item_moderation_restored'
      )
    SQL

    drop_table :moderation_media_access_events

    remove_check_constraint :moderation_actions, name: "moderation_actions_known_target"
    add_check_constraint :moderation_actions,
      "target_type IN ('verification_request', 'professional_profile')",
      name: "moderation_actions_known_target"
    add_check_constraint :moderation_actions,
      <<~SQL.squish,
        (target_type = 'verification_request' AND action IN ('approved', 'rejected'))
        OR (target_type = 'professional_profile' AND action IN ('hidden', 'restored'))
      SQL
      name: "moderation_actions_target_matches_action"
    add_check_constraint :moderation_actions,
      <<~SQL.squish,
        (action IN ('rejected', 'hidden') AND reason IS NOT NULL
          AND char_length(btrim(reason)) BETWEEN 10 AND 500)
        OR (action IN ('approved', 'restored') AND reason IS NULL)
      SQL
      name: "moderation_actions_reason_matches_action"

    remove_check_constraint :notifications, name: "notifications_known_type"
    add_check_constraint :notifications,
      <<~SQL.squish,
        notification_type IN (
          'profile_moderation_hidden',
          'profile_moderation_restored',
          'verification_request_moderation_approved',
          'verification_request_moderation_rejected',
          'relationship_request_received',
          'relationship_request_accepted',
          'relationship_request_declined',
          'quote_change_requested',
          'quote_approved',
          'quote_declined',
          'service_completion_confirmed',
          'service_completion_issue_reported',
          'customer_recommendation_published'
        )
      SQL
      name: "notifications_known_type"

    remove_foreign_key :professional_profiles, column: :approved_revision_id
    remove_index :professional_profiles, :approved_revision_id
    remove_column :professional_profiles, :approved_revision_id

    remove_foreign_key :professional_profiles, column: :approved_photo_id
    remove_foreign_key :professional_profiles, column: :published_photo_id
    remove_foreign_key :professional_profiles, column: :working_photo_id
    remove_index :professional_profiles, :approved_photo_id
    remove_index :professional_profiles, :published_photo_id
    remove_index :professional_profiles, :working_photo_id
    remove_column :professional_profiles, :approved_photo_id
    remove_column :professional_profiles, :published_photo_id
    remove_column :professional_profiles, :working_photo_id
    add_reference :professional_profiles, :profile_photo,
      type: :uuid,
      index: {unique: true},
      foreign_key: {to_table: :professional_profile_photos}

    remove_check_constraint :professional_profiles, name: "professional_profiles_known_status"
    add_check_constraint :professional_profiles,
      "profile_status IN ('draft', 'published', 'suspended')",
      name: "professional_profiles_known_status"

    remove_index :professional_profile_revisions, name: "idx_profile_revisions_one_working_per_type"
    remove_check_constraint :professional_profile_revisions, name: "professional_profile_revisions_known_status"
    remove_columns :professional_profile_revisions,
      :status,
      :rejection_reason,
      :reviewed_at,
      :submitted_at

    remove_index :professional_profile_photos, name: "idx_profile_photos_one_approved"
    remove_index :professional_profile_photos, name: "idx_profile_photos_one_pending"
    remove_index :professional_profile_photos, :public_key
    remove_check_constraint :professional_profile_photos, name: "professional_profile_photos_known_status"
    remove_columns :professional_profile_photos,
      :status,
      :rejection_reason,
      :reviewed_at,
      :hidden_at,
      :public_key
    add_column :professional_profile_photos, :deleted_at, :datetime
    add_index :professional_profile_photos, :deleted_at

    remove_index :portfolio_items, :public_key
    remove_check_constraint :portfolio_items, name: "portfolio_items_known_status"
    remove_columns :portfolio_items,
      :status,
      :rejection_reason,
      :reviewed_at,
      :hidden_at,
      :public_key
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the moderation simplification requires a database reset"
  end
end
