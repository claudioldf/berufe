# frozen_string_literal: true

class AddRecommendationHiding < ActiveRecord::Migration[8.1]
  def up
    add_column :customer_recommendations, :hidden_by_professional_at, :datetime
    add_column :customer_recommendations, :hidden_reason, :text
    add_index :customer_recommendations, :hidden_by_professional_at
    add_check_constraint :customer_recommendations,
      "hidden_reason IS NULL OR char_length(btrim(hidden_reason)) BETWEEN 1 AND 700",
      name: "customer_recommendations_hidden_reason_length"
    add_check_constraint :customer_recommendations,
      "hidden_by_professional_at IS NOT NULL OR hidden_reason IS NULL",
      name: "customer_recommendations_hidden_reason_requires_hidden"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "the recommendation hiding change requires a database reset"
  end
end
