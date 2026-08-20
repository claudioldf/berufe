# frozen_string_literal: true

class AddModerationStatusToProfessionalRelationships < ActiveRecord::Migration[8.1]
  def up
    add_column :professional_relationships, :moderation_status, :text,
      null: false, default: "pending_review"
    add_check_constraint :professional_relationships,
      "moderation_status IN ('pending_review', 'approved', 'rejected', 'hidden')",
      name: "professional_relationships_known_moderation_status"
    add_index :professional_relationships, %i[status moderation_status],
      name: "idx_professional_relationships_status_moderation"

    # Until now the effective moderation state was derived from the latest
    # moderation_actions row. Materialize it once so the audit log stops being
    # load-bearing.
    execute(<<~SQL.squish)
      UPDATE professional_relationships
      SET moderation_status = CASE latest.action
        WHEN 'approved' THEN 'approved'
        WHEN 'restored' THEN 'approved'
        WHEN 'rejected' THEN 'rejected'
        WHEN 'hidden' THEN 'hidden'
      END
      FROM (
        SELECT DISTINCT ON (moderation_actions.target_id)
          moderation_actions.target_id,
          moderation_actions.action
        FROM moderation_actions
        WHERE moderation_actions.target_type = 'professional_relationship'
        ORDER BY moderation_actions.target_id,
          moderation_actions.created_at DESC,
          moderation_actions.id DESC
      ) AS latest
      WHERE latest.target_id = professional_relationships.id
        AND latest.action IN ('approved', 'restored', 'rejected', 'hidden')
    SQL
  end

  def down
    remove_index :professional_relationships,
      name: "idx_professional_relationships_status_moderation"
    remove_check_constraint :professional_relationships,
      name: "professional_relationships_known_moderation_status"
    remove_column :professional_relationships, :moderation_status
  end
end
