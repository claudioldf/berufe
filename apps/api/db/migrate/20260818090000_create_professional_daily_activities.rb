# frozen_string_literal: true

class CreateProfessionalDailyActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :professional_daily_activities, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :professional_profiles}
      table.date :activity_date, null: false
      table.integer :profile_updates, null: false, default: 0
      table.integer :evidence_creations, null: false, default: 0
      table.integer :relationship_interactions, null: false, default: 0
      table.integer :quotes_created, null: false, default: 0
      table.timestamps
    end

    add_index :professional_daily_activities,
      %i[professional_id activity_date],
      unique: true,
      name: "idx_professional_daily_activities_professional_date"
    add_index :professional_daily_activities,
      %i[activity_date professional_id],
      name: "idx_professional_daily_activities_date_professional"
    add_check_constraint :professional_daily_activities,
      "profile_updates >= 0 AND evidence_creations >= 0 AND relationship_interactions >= 0 AND quotes_created >= 0",
      name: "professional_daily_activities_nonnegative"
  end
end
