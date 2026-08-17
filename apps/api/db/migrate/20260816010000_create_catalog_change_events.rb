# frozen_string_literal: true

class CreateCatalogChangeEvents < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :services, "char_length(name) <= 80", name: "services_name_length"
    add_check_constraint :services, "char_length(slug) <= 80", name: "services_slug_length"
    add_check_constraint :services, "char_length(description) <= 240", name: "services_description_length"
    add_check_constraint :neighborhoods, "char_length(name) <= 80", name: "neighborhoods_name_length"
    add_check_constraint :neighborhoods, "char_length(code) <= 80", name: "neighborhoods_code_length"
    add_check_constraint :neighborhoods, "char_length(city_code) <= 80", name: "neighborhoods_city_length"

    create_table :catalog_change_events, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :admin_user, type: :uuid, null: false, foreign_key: {to_table: :user_accounts}
      table.text :catalog_type, null: false
      table.text :target_identifier, null: false
      table.text :action, null: false
      table.jsonb :change_data, null: false, default: {}
      table.text :request_id, null: false
      table.datetime :created_at, null: false
    end

    add_index :catalog_change_events, %i[catalog_type target_identifier created_at],
      name: "index_catalog_changes_on_target_and_created_at"
    add_index :catalog_change_events, %i[admin_user_id created_at]
    add_check_constraint :catalog_change_events,
      "catalog_type IN ('service', 'neighborhood')",
      name: "catalog_change_events_known_catalog_type"
    add_check_constraint :catalog_change_events,
      "action IN ('created', 'updated', 'activated', 'deactivated', 'reordered')",
      name: "catalog_change_events_known_action"
    add_check_constraint :catalog_change_events,
      "target_identifier <> ''",
      name: "catalog_change_events_target_present"
    add_check_constraint :catalog_change_events,
      "jsonb_typeof(change_data) = 'object'",
      name: "catalog_change_events_change_data_object"
    add_check_constraint :catalog_change_events,
      "request_id ~ '^[A-Za-z0-9._-]{1,100}$'",
      name: "catalog_change_events_request_id_format"
  end
end
