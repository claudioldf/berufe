# frozen_string_literal: true

class AllowStructuredSearchRollups < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :search_daily_rollups,
      name: "search_daily_rollups_matched_or_unmatched"
    add_check_constraint :search_daily_rollups,
      "service_id IS NULL OR unmatched_query IS NULL",
      name: "search_daily_rollups_do_not_mix_dimensions"
  end
end
