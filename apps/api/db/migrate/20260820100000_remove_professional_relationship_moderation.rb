# frozen_string_literal: true

class RemoveProfessionalRelationshipModeration < ActiveRecord::Migration[8.1]
  TARGET_TYPES = %w[profile_revision profile_photo portfolio_item verification_request].freeze

  def up
    execute "DELETE FROM moderation_actions WHERE target_type = 'professional_relationship'"

    remove_check_constraint :moderation_actions, name: "moderation_actions_known_target"
    add_check_constraint :moderation_actions,
      "target_type IN (#{TARGET_TYPES.map { |value| connection.quote(value) }.join(", ")})",
      name: "moderation_actions_known_target"

    remove_index :professional_relationships,
      name: "idx_professional_relationships_active_direction",
      if_exists: true
    remove_index :professional_relationships,
      name: "idx_professional_relationships_status_moderation",
      if_exists: true
    if check_constraint_exists?(
      :professional_relationships,
      name: "professional_relationships_known_moderation_status"
    )
      remove_check_constraint :professional_relationships,
        name: "professional_relationships_known_moderation_status"
    end
    remove_column :professional_relationships, :moderation_status if column_exists?(
      :professional_relationships,
      :moderation_status
    )

    # A previously rejected moderation decision allowed another request for the
    # same directional relationship. Keep the newest request and its
    # recipient-owned status before restoring the original uniqueness rule.
    execute <<~SQL.squish
      DELETE FROM professional_relationships
      WHERE id IN (
        SELECT id
        FROM (
          SELECT id,
            ROW_NUMBER() OVER (
              PARTITION BY initiator_professional_id,
                recipient_professional_id,
                relationship_type
              ORDER BY created_at DESC, id DESC
            ) AS duplicate_position
          FROM professional_relationships
        ) AS ranked_relationships
        WHERE duplicate_position > 1
      )
    SQL

    return if index_exists?(
      :professional_relationships,
      %i[initiator_professional_id recipient_professional_id relationship_type],
      unique: true,
      name: "idx_professional_relationships_unique_direction"
    )

    add_index :professional_relationships,
      %i[initiator_professional_id recipient_professional_id relationship_type],
      unique: true,
      name: "idx_professional_relationships_unique_direction"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "relationship moderation audit records were intentionally removed"
  end
end
