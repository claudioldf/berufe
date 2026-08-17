# frozen_string_literal: true

class CreateSearchEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :search_events, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :service, type: :uuid, null: true, foreign_key: true
      table.text :query_text_normalized
      table.text :city_code, null: false
      table.text :neighborhood_code
      table.integer :result_count, null: false
      table.boolean :profile_opened, null: false, default: false
      table.boolean :whatsapp_handoff_occurred, null: false, default: false
      table.timestamps
    end

    add_foreign_key :search_events,
      :neighborhoods,
      column: :neighborhood_code,
      primary_key: :code
    add_index :search_events,
      %i[created_at service_id neighborhood_code],
      name: "index_search_events_on_time_service_and_neighborhood"
    add_check_constraint :search_events,
      "city_code = 'Joinville'",
      name: "search_events_launch_city"
    add_check_constraint :search_events,
      "result_count >= 0",
      name: "search_events_result_count_nonnegative"
    add_check_constraint :search_events,
      "query_text_normalized IS NULL OR (query_text_normalized ~ '^[a-z0-9]+( [a-z0-9]+)*$' AND char_length(query_text_normalized) <= 80)",
      name: "search_events_normalized_query_format"
  end
end
