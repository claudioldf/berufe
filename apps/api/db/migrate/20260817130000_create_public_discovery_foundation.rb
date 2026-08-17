# frozen_string_literal: true

class CreatePublicDiscoveryFoundation < ActiveRecord::Migration[8.1]
  def up
    create_table :professional_relationships, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :initiator_professional,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :professional_profiles}
      table.references :recipient_professional,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :professional_profiles}
      table.text :relationship_type, null: false
      table.text :context_note
      table.text :status, null: false, default: "pending"
      table.datetime :responded_at
      table.timestamps
    end

    add_index :professional_relationships,
      %i[initiator_professional_id recipient_professional_id relationship_type],
      unique: true,
      name: "idx_professional_relationships_unique_direction"
    add_index :professional_relationships,
      %i[initiator_professional_id status],
      name: "idx_professional_relationships_initiator_status"
    add_index :professional_relationships,
      %i[recipient_professional_id status],
      name: "idx_professional_relationships_recipient_status"
    add_check_constraint :professional_relationships,
      "initiator_professional_id <> recipient_professional_id",
      name: "professional_relationships_distinct_profiles"
    add_check_constraint :professional_relationships,
      "relationship_type IN ('recommendation', 'worked_together')",
      name: "professional_relationships_known_type"
    add_check_constraint :professional_relationships,
      "status IN ('pending', 'accepted', 'declined')",
      name: "professional_relationships_known_status"
    add_check_constraint :professional_relationships,
      "context_note IS NULL OR char_length(btrim(context_note)) BETWEEN 1 AND 300",
      name: "professional_relationships_context_length"
    add_check_constraint :professional_relationships,
      "(status = 'pending' AND responded_at IS NULL) OR (status IN ('accepted', 'declined') AND responded_at IS NOT NULL)",
      name: "professional_relationships_response_state"

    remove_check_constraint :moderation_actions, name: "moderation_actions_known_target"
    add_check_constraint :moderation_actions,
      "target_type IN ('profile_revision', 'profile_photo', 'portfolio_item', 'verification_request', 'professional_relationship')",
      name: "moderation_actions_known_target"
  end

  def down
    remove_check_constraint :moderation_actions, name: "moderation_actions_known_target"
    add_check_constraint :moderation_actions,
      "target_type IN ('profile_revision', 'profile_photo', 'portfolio_item', 'verification_request')",
      name: "moderation_actions_known_target"
    drop_table :professional_relationships
  end
end
