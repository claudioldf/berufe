# frozen_string_literal: true

class CreateProfessionalProfileSupply < ActiveRecord::Migration[8.1]
  def change
    create_table :professional_profile_services, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional_profile, type: :uuid, null: false, foreign_key: true
      table.references :service, type: :uuid, null: false, foreign_key: true
      table.boolean :is_primary, null: false, default: false
      table.text :note
      table.timestamps null: false
    end

    add_index :professional_profile_services,
      %i[professional_profile_id service_id],
      unique: true,
      name: "idx_profile_services_unique_service"
    add_index :professional_profile_services,
      :professional_profile_id,
      unique: true,
      where: "is_primary",
      name: "idx_profile_services_one_primary"
    add_check_constraint :professional_profile_services,
      "note IS NULL OR char_length(btrim(note)) BETWEEN 1 AND 120",
      name: "professional_profile_services_note_length"

    create_table :professional_profile_service_areas, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional_profile, type: :uuid, null: false, foreign_key: true,
        index: {name: "idx_profile_service_areas_profile"}
      table.text :city_code, null: false, default: "Joinville"
      table.text :neighborhood_code
      table.timestamps null: false
    end

    add_foreign_key :professional_profile_service_areas,
      :neighborhoods,
      column: :neighborhood_code,
      primary_key: :code
    add_index :professional_profile_service_areas,
      %i[professional_profile_id city_code neighborhood_code],
      unique: true,
      where: "neighborhood_code IS NOT NULL",
      name: "idx_profile_service_areas_unique_neighborhood"
    add_index :professional_profile_service_areas,
      %i[professional_profile_id city_code],
      unique: true,
      where: "neighborhood_code IS NULL",
      name: "idx_profile_service_areas_unique_all_city"
    add_check_constraint :professional_profile_service_areas,
      "city_code = 'Joinville'",
      name: "professional_profile_service_areas_joinville_only"
  end
end
