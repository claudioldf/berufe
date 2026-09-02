# frozen_string_literal: true

class AddAiGeneratedCopyToProfessionalProfileRevisions < ActiveRecord::Migration[8.1]
  def up
    add_column :professional_profile_revisions, :ai_headline, :text
    add_column :professional_profile_revisions, :ai_bio, :text
    add_column :professional_profile_revisions, :ai_copy_model, :string, limit: 80
    add_column :professional_profile_revisions, :ai_copy_generated_at, :datetime
    add_check_constraint :professional_profile_revisions,
      "ai_headline IS NULL OR char_length(btrim(ai_headline)) BETWEEN 1 AND 120",
      name: "professional_profile_revisions_ai_headline_length"
    add_check_constraint :professional_profile_revisions,
      "ai_bio IS NULL OR char_length(btrim(ai_bio)) BETWEEN 1 AND 500",
      name: "professional_profile_revisions_ai_bio_length"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the AI-generated copy change requires a database reset"
  end
end
