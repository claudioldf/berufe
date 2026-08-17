# frozen_string_literal: true

class CreateCatalogs < ActiveRecord::Migration[8.1]
  def change
    create_table :service_categories, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.text :name, null: false
      table.text :slug, null: false
      table.text :icon, null: false
      table.boolean :is_active, null: false, default: true
      table.integer :sort_order, limit: 2, null: false
      table.timestamps null: false
    end

    add_index :service_categories, :slug, unique: true
    add_index :service_categories, %i[sort_order slug]
    add_index :service_categories, "lower(name)", unique: true, where: "is_active", name: "index_active_service_categories_on_name"
    add_check_constraint :service_categories, "btrim(name) <> ''", name: "service_categories_name_present"
    add_check_constraint :service_categories, "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", name: "service_categories_slug_format"
    add_check_constraint :service_categories, "sort_order >= 0", name: "service_categories_sort_order_nonnegative"

    create_table :services, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :category, type: :uuid, null: false, foreign_key: {to_table: :service_categories}
      table.text :name, null: false
      table.text :slug, null: false
      table.text :icon, null: false
      table.text :description, null: false
      table.text :aliases, array: true, null: false, default: []
      table.boolean :is_active, null: false, default: true
      table.integer :sort_order, limit: 2, null: false
      table.timestamps null: false
    end

    add_index :services, :slug, unique: true
    add_index :services, %i[sort_order slug]
    add_index :services, %i[category_id sort_order slug]
    add_check_constraint :services, "btrim(name) <> ''", name: "services_name_present"
    add_check_constraint :services, "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", name: "services_slug_format"
    add_check_constraint :services, "btrim(description) <> ''", name: "services_description_present"
    add_check_constraint :services, "sort_order >= 0", name: "services_sort_order_nonnegative"

    create_table :neighborhoods, id: :text, primary_key: :code do |table|
      table.string :state_code, limit: 2, null: false
      table.text :city_code, null: false
      table.text :name, null: false
      table.boolean :is_active, null: false, default: true
      table.integer :sort_order, limit: 2, null: false
      table.timestamps null: false
    end

    add_index :neighborhoods, %i[sort_order code]
    add_index :neighborhoods, "state_code, city_code, lower(name)", unique: true, where: "is_active", name: "index_active_neighborhoods_on_location_and_name"
    add_check_constraint :neighborhoods, "code ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", name: "neighborhoods_code_format"
    add_check_constraint :neighborhoods, "state_code = 'SC'", name: "neighborhoods_launch_state"
    add_check_constraint :neighborhoods, "city_code = 'Joinville'", name: "neighborhoods_launch_city"
    add_check_constraint :neighborhoods, "btrim(name) <> ''", name: "neighborhoods_name_present"
    add_check_constraint :neighborhoods, "sort_order >= 0", name: "neighborhoods_sort_order_nonnegative"
  end
end
