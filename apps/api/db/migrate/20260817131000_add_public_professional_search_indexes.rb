# frozen_string_literal: true

class AddPublicProfessionalSearchIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :professional_profile_services,
      %i[service_id professional_profile_revision_id],
      name: "idx_revision_services_service_revision"
    add_index :professional_profile_service_areas,
      %i[neighborhood_code professional_profile_revision_id],
      where: "neighborhood_code IS NOT NULL",
      name: "idx_revision_service_areas_neighborhood_revision"
  end
end
