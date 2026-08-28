# frozen_string_literal: true

class AllowDuplicateIbgeNeighborhoodNames < ActiveRecord::Migration[8.1]
  INDEX_NAME = "index_neighborhoods_on_city_and_name"

  def up
    remove_index :neighborhoods, name: INDEX_NAME
    add_index :neighborhoods, "city_code, lower(name)", name: INDEX_NAME
  end

  def down
    remove_index :neighborhoods, name: INDEX_NAME
    add_index :neighborhoods, "city_code, lower(name)", unique: true, name: INDEX_NAME
  end
end
