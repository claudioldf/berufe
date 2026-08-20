# frozen_string_literal: true

class EnablePostPublicationModeration < ActiveRecord::Migration[8.1]
  def up
    add_column :professional_profiles, :birthdate, :date
    add_reference :professional_profiles, :approved_revision,
      type: :uuid,
      foreign_key: {to_table: :professional_profile_revisions},
      index: {unique: true}
    add_reference :professional_profiles, :approved_photo,
      type: :uuid,
      foreign_key: {to_table: :professional_profile_photos},
      index: {unique: true}

    add_column :verification_requests, :claimed_birthdate, :date
    add_column :verification_requests, :identity_match_confirmed_at, :datetime
    add_column :verification_requests, :expired_at, :datetime

    execute <<~SQL.squish
      UPDATE professional_profiles
      SET approved_revision_id = published_revision_id,
          approved_photo_id = published_photo_id
    SQL

    # Preserve already-created edits during rollout: the pending working copy
    # becomes the live copy while the old approved pointer stays available for
    # a rejection rollback.
    execute <<~SQL.squish
      UPDATE professional_profiles AS profiles
      SET published_revision_id = profiles.working_revision_id
      FROM professional_profile_revisions AS revisions
      WHERE profiles.profile_status = 'published'
        AND revisions.id = profiles.working_revision_id
        AND revisions.status = 'pending_review'
    SQL
    execute <<~SQL.squish
      UPDATE professional_profiles AS profiles
      SET published_photo_id = profiles.working_photo_id
      FROM professional_profile_photos AS photos
      WHERE profiles.profile_status = 'published'
        AND photos.id = profiles.working_photo_id
        AND photos.status = 'pending_review'
    SQL
  end

  def down
    remove_column :verification_requests, :expired_at
    remove_column :verification_requests, :identity_match_confirmed_at
    remove_column :verification_requests, :claimed_birthdate
    remove_reference :professional_profiles, :approved_photo,
      foreign_key: {to_table: :professional_profile_photos}
    remove_reference :professional_profiles, :approved_revision,
      foreign_key: {to_table: :professional_profile_revisions}
    remove_column :professional_profiles, :birthdate
  end
end
