# frozen_string_literal: true

class AddDeletedAtToProfessionalRelationships < ActiveRecord::Migration[8.1]
  def up
    add_column :professional_relationships, :deleted_at, :datetime

    remove_index :professional_relationships,
      name: "idx_professional_relationships_unique_direction"
    add_index :professional_relationships,
      %i[initiator_professional_id recipient_professional_id relationship_type],
      unique: true,
      where: "deleted_at IS NULL",
      name: "idx_professional_relationships_unique_direction"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "removed relationships may have been recreated after this migration"
  end
end
