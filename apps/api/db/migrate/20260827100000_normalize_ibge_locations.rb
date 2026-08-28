# frozen_string_literal: true

class NormalizeIbgeLocations < ActiveRecord::Migration[8.1]
  def change
    discard_legacy_location_data
    detach_legacy_neighborhoods
    create_location_tables
    reshape_professional_coverage
    connect_search_locations
    restrict_catalog_change_events
  end

  private

  def discard_legacy_location_data
    execute "DELETE FROM professional_profile_service_areas"
    execute "DELETE FROM search_daily_rollups"
    execute "DELETE FROM search_events"
  end

  def detach_legacy_neighborhoods
    remove_foreign_key :professional_profile_service_areas,
      column: :neighborhood_code
    remove_foreign_key :search_events,
      column: :neighborhood_code
    remove_foreign_key :search_daily_rollups,
      column: :neighborhood_code
    drop_table :neighborhoods
  end

  def create_location_tables
    create_table :states, id: :text, primary_key: :code do |table|
      table.string :abbreviation, limit: 2, null: false
      table.text :name, null: false
      table.timestamps null: false
    end
    add_index :states, :abbreviation, unique: true
    add_index :states, "lower(name)", unique: true
    add_check_constraint :states, "code ~ '^[0-9]{2}$'", name: "states_ibge_code_format"
    add_check_constraint :states, "abbreviation ~ '^[A-Z]{2}$'", name: "states_abbreviation_format"
    add_check_constraint :states, "btrim(name) <> ''", name: "states_name_present"

    create_table :cities, id: :text, primary_key: :code do |table|
      table.text :state_code, null: false
      table.text :name, null: false
      table.text :slug, null: false
      table.timestamps null: false
    end
    add_foreign_key :cities, :states, column: :state_code, primary_key: :code
    add_index :cities, %i[state_code slug], unique: true
    add_index :cities, "state_code, lower(name)", unique: true, name: "index_cities_on_state_and_name"
    add_check_constraint :cities, "code ~ '^[0-9]{7}$'", name: "cities_ibge_code_format"
    add_check_constraint :cities, "btrim(name) <> ''", name: "cities_name_present"
    add_check_constraint :cities, "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", name: "cities_slug_format"

    create_table :neighborhoods, id: :text, primary_key: :code do |table|
      table.text :city_code, null: false
      table.text :name, null: false
      table.timestamps null: false
    end
    add_foreign_key :neighborhoods, :cities, column: :city_code, primary_key: :code
    add_index :neighborhoods, %i[city_code code]
    add_index :neighborhoods, "city_code, lower(name)", unique: true, name: "index_neighborhoods_on_city_and_name"
    add_check_constraint :neighborhoods, "code ~ '^[0-9]{10}$'", name: "neighborhoods_ibge_code_format"
    add_check_constraint :neighborhoods, "btrim(name) <> ''", name: "neighborhoods_name_present"
  end

  def reshape_professional_coverage
    add_column :professional_profile_revisions, :coverage_city_code, :text
    add_column :professional_profile_revisions, :covers_whole_city, :boolean, null: false, default: false
    add_foreign_key :professional_profile_revisions,
      :cities,
      column: :coverage_city_code,
      primary_key: :code
    add_index :professional_profile_revisions, :coverage_city_code

    remove_check_constraint :professional_profile_service_areas,
      name: "professional_profile_service_areas_joinville_only"
    remove_index :professional_profile_service_areas,
      name: "idx_revision_service_areas_unique_neighborhood"
    remove_index :professional_profile_service_areas,
      name: "idx_revision_service_areas_unique_all_city"
    remove_column :professional_profile_service_areas, :city_code, :text
    change_column_null :professional_profile_service_areas, :neighborhood_code, false
    add_foreign_key :professional_profile_service_areas,
      :neighborhoods,
      column: :neighborhood_code,
      primary_key: :code
    add_index :professional_profile_service_areas,
      %i[professional_profile_revision_id neighborhood_code],
      unique: true,
      name: "idx_revision_service_areas_unique_neighborhood"
  end

  def connect_search_locations
    remove_check_constraint :search_events, name: "search_events_launch_city"
    add_foreign_key :search_events, :cities, column: :city_code, primary_key: :code
    add_foreign_key :search_events,
      :neighborhoods,
      column: :neighborhood_code,
      primary_key: :code
    add_index :search_events, %i[city_code created_at]

    remove_index :search_daily_rollups,
      name: "idx_search_daily_rollups_unique_dimensions"
    add_column :search_daily_rollups, :city_code, :text, null: false
    add_foreign_key :search_daily_rollups, :cities, column: :city_code, primary_key: :code
    add_foreign_key :search_daily_rollups,
      :neighborhoods,
      column: :neighborhood_code,
      primary_key: :code
    add_index :search_daily_rollups,
      %i[report_date city_code service_id neighborhood_code unmatched_query],
      unique: true,
      nulls_not_distinct: true,
      name: "idx_search_daily_rollups_unique_dimensions"
    add_index :search_daily_rollups, %i[city_code report_date]
  end

  def restrict_catalog_change_events
    remove_check_constraint :catalog_change_events,
      name: "catalog_change_events_known_catalog_type"
    add_check_constraint :catalog_change_events,
      "catalog_type = 'service'",
      name: "catalog_change_events_known_catalog_type"
  end
end
