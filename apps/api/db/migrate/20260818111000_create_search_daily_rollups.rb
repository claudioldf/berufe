# frozen_string_literal: true

class CreateSearchDailyRollups < ActiveRecord::Migration[8.1]
  def change
    create_table :search_daily_rollups, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.date :report_date, null: false
      table.references :service, type: :uuid, null: true, foreign_key: true
      table.text :neighborhood_code
      table.text :unmatched_query
      table.integer :searches, null: false, default: 0
      table.integer :with_results, null: false, default: 0
      table.integer :with_three_results, null: false, default: 0
      table.integer :with_profile_open, null: false, default: 0
      table.integer :with_whatsapp_handoff, null: false, default: 0
      table.integer :zero_results, null: false, default: 0
      table.integer :thin_results, null: false, default: 0
      table.timestamps
    end

    add_foreign_key :search_daily_rollups,
      :neighborhoods,
      column: :neighborhood_code,
      primary_key: :code
    add_index :search_daily_rollups,
      %i[report_date service_id neighborhood_code unmatched_query],
      unique: true,
      nulls_not_distinct: true,
      name: "idx_search_daily_rollups_unique_dimensions"
    add_index :search_daily_rollups, %i[service_id report_date]
    add_index :search_daily_rollups, %i[neighborhood_code report_date]
    add_check_constraint :search_daily_rollups,
      "(service_id IS NULL) <> (unmatched_query IS NULL)",
      name: "search_daily_rollups_matched_or_unmatched"
    add_check_constraint :search_daily_rollups,
      "unmatched_query IS NULL OR (unmatched_query ~ '^[a-z0-9]+( [a-z0-9]+)*$' AND char_length(unmatched_query) <= 80)",
      name: "search_daily_rollups_query_format"
    add_check_constraint :search_daily_rollups,
      "searches >= 0 AND with_results >= 0 AND with_three_results >= 0 AND " \
        "with_profile_open >= 0 AND with_whatsapp_handoff >= 0 AND zero_results >= 0 AND thin_results >= 0",
      name: "search_daily_rollups_nonnegative"
    add_check_constraint :search_daily_rollups,
      "with_results <= searches AND with_three_results <= with_results AND " \
        "with_profile_open <= searches AND with_whatsapp_handoff <= searches AND " \
        "zero_results + with_results = searches AND thin_results <= with_results",
      name: "search_daily_rollups_subset_counts"
  end
end
