# frozen_string_literal: true

class ExpandProfessionalProfileBioLength < ActiveRecord::Migration[8.1]
  CONSTRAINT_NAME = "professional_profile_revisions_bio_length"

  def up
    replace_constraint(maximum: 2500)
  end

  def down
    replace_constraint(maximum: 500)
  end

  private

  def replace_constraint(maximum:)
    remove_check_constraint :professional_profile_revisions, name: CONSTRAINT_NAME
    add_check_constraint :professional_profile_revisions,
      "bio IS NULL OR char_length(btrim(bio)) BETWEEN 1 AND #{maximum}",
      name: CONSTRAINT_NAME
  end
end
