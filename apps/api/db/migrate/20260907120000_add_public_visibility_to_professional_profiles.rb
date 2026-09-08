# frozen_string_literal: true

class AddPublicVisibilityToProfessionalProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :professional_profiles,
      :public_visibility,
      :text,
      null: false,
      default: "discoverable"
    add_index :professional_profiles, :public_visibility
    add_check_constraint :professional_profiles,
      "public_visibility = ANY (ARRAY['discoverable'::text, 'direct_link'::text, 'unpublished'::text])",
      name: "professional_profiles_known_public_visibility"
  end
end
