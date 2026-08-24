# frozen_string_literal: true

class RecordRecommendationConsentAndWithdrawal < ActiveRecord::Migration[8.0]
  def up
    add_column :customer_recommendations, :privacy_notice_version, :text
    add_column :customer_recommendations, :publication_withdrawn_at, :timestamptz
    add_index :customer_recommendations, :publication_withdrawn_at

    execute <<~SQL.squish
      UPDATE customer_recommendations
      SET privacy_notice_version = '0.3'
      WHERE privacy_notice_version IS NULL
    SQL

    change_column_null :customer_recommendations, :privacy_notice_version, false
    add_check_constraint :customer_recommendations,
      "btrim(privacy_notice_version) <> ''",
      name: "customer_recommendations_privacy_version_present"
  end

  def down
    remove_check_constraint :customer_recommendations,
      name: "customer_recommendations_privacy_version_present"
    remove_index :customer_recommendations, :publication_withdrawn_at
    remove_column :customer_recommendations, :publication_withdrawn_at
    remove_column :customer_recommendations, :privacy_notice_version
  end
end
