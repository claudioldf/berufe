# frozen_string_literal: true

class AddGrowthReportingFoundation < ActiveRecord::Migration[8.1]
  def up
    add_column :professional_profiles, :published_at, :datetime
    add_index :professional_profiles, :published_at

    execute <<~SQL
      UPDATE professional_profiles profiles
      SET published_at = COALESCE(
        (
          SELECT MIN(actions.created_at)
          FROM moderation_actions actions
          INNER JOIN professional_profile_revisions revisions
            ON revisions.id = actions.target_id
          WHERE actions.target_type = 'profile_revision'
            AND actions.action = 'approved'
            AND revisions.professional_profile_id = profiles.id
        ),
        (
          SELECT revisions.reviewed_at
          FROM professional_profile_revisions revisions
          WHERE revisions.id = profiles.published_revision_id
        )
      )
      WHERE profiles.profile_status IN ('published', 'suspended')
    SQL

    unresolved = select_value(<<~SQL).to_i
      SELECT COUNT(*)
      FROM professional_profiles
      WHERE profile_status IN ('published', 'suspended')
        AND published_at IS NULL
    SQL
    raise ActiveRecord::MigrationError, "#{unresolved} published profiles have no publication timestamp" if unresolved.positive?
  end

  def down
    remove_column :professional_profiles, :published_at
  end
end
