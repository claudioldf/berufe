# frozen_string_literal: true

class AddRecommendationDeliveryChannel < ActiveRecord::Migration[8.1]
  def up
    add_column :customer_recommendation_requests, :delivery_channel, :string, limit: 16, default: "email", null: false
    add_check_constraint :customer_recommendation_requests,
      "delivery_channel IN ('email', 'whatsapp')",
      name: "customer_recommendation_requests_known_delivery_channel"

    change_column_null :customer_recommendation_requests, :email_fingerprint, true
    add_check_constraint :customer_recommendation_requests,
      "(delivery_channel = 'email' AND email_fingerprint IS NOT NULL) OR " \
        "(delivery_channel = 'whatsapp' AND email_fingerprint IS NULL)",
      name: "customer_recommendation_requests_consistent_channel"

    add_column :customer_recommendations, :delivery_channel, :string, limit: 16, default: "email", null: false
    add_check_constraint :customer_recommendations,
      "delivery_channel IN ('email', 'whatsapp')",
      name: "customer_recommendations_known_delivery_channel"

    change_column_null :customer_recommendations, :email_fingerprint, true
    change_column_null :customer_recommendations, :email_verified_at, true
    add_check_constraint :customer_recommendations,
      "(delivery_channel = 'email' AND email_fingerprint IS NOT NULL AND email_verified_at IS NOT NULL) OR " \
        "(delivery_channel = 'whatsapp' AND email_fingerprint IS NULL AND email_verified_at IS NULL)",
      name: "customer_recommendations_consistent_channel"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the recommendation delivery-channel change requires a database reset"
  end
end
