# frozen_string_literal: true

class CreateProfessionalDailyMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :professional_daily_metrics, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :professional_profiles}
      table.date :metric_date, null: false
      table.integer :profile_views, null: false, default: 0
      table.integer :whatsapp_clicks, null: false, default: 0
      table.integer :whatsapp_clicks_public_profile, null: false, default: 0
      table.integer :whatsapp_clicks_search_result, null: false, default: 0
      table.integer :quotes_shared, null: false, default: 0
      table.timestamps
    end

    add_index :professional_daily_metrics,
      %i[professional_id metric_date],
      unique: true,
      name: "index_professional_daily_metrics_on_professional_and_date"
    add_check_constraint :professional_daily_metrics,
      "profile_views >= 0 AND whatsapp_clicks >= 0 AND " \
        "whatsapp_clicks_public_profile >= 0 AND whatsapp_clicks_search_result >= 0 AND quotes_shared >= 0",
      name: "professional_daily_metrics_nonnegative_counters"
    add_check_constraint :professional_daily_metrics,
      "whatsapp_clicks = whatsapp_clicks_public_profile + whatsapp_clicks_search_result",
      name: "professional_daily_metrics_whatsapp_source_total"
  end
end
