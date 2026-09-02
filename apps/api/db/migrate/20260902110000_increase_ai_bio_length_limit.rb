# frozen_string_literal: true

class IncreaseAiBioLengthLimit < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :professional_profile_revisions, name: "professional_profile_revisions_ai_bio_length"
    add_check_constraint :professional_profile_revisions,
      "ai_bio IS NULL OR char_length(btrim(ai_bio)) BETWEEN 1 AND 1000",
      name: "professional_profile_revisions_ai_bio_length"
  end

  def down
    execute "UPDATE professional_profile_revisions SET ai_bio = left(btrim(ai_bio), 500) WHERE char_length(btrim(ai_bio)) > 500"

    remove_check_constraint :professional_profile_revisions, name: "professional_profile_revisions_ai_bio_length"
    add_check_constraint :professional_profile_revisions,
      "ai_bio IS NULL OR char_length(btrim(ai_bio)) BETWEEN 1 AND 500",
      name: "professional_profile_revisions_ai_bio_length"
  end
end
