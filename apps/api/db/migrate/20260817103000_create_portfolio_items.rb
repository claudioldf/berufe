# frozen_string_literal: true

class CreatePortfolioItems < ActiveRecord::Migration[8.1]
  STATUSES = %w[pending_review approved rejected hidden].freeze

  def change
    create_table :portfolio_items, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional_profile, type: :uuid, null: false, foreign_key: true
      table.references :media_upload, type: :uuid, null: false, foreign_key: true, index: {unique: true}
      table.references :service, type: :uuid, null: false, foreign_key: true
      table.text :title, null: false
      table.text :description
      table.text :status, null: false, default: "pending_review"
      table.text :private_key, null: false
      table.text :public_key
      table.text :content_type, null: false
      table.bigint :byte_size, null: false
      table.integer :width, null: false
      table.integer :height, null: false
      table.datetime :submitted_at, null: false
      table.datetime :reviewed_at
      table.datetime :hidden_at
      table.datetime :deleted_at
      table.text :rejection_reason
      table.timestamps null: false
    end

    add_index :portfolio_items, :private_key, unique: true
    add_index :portfolio_items, :public_key, unique: true, where: "public_key IS NOT NULL"
    add_index :portfolio_items,
      %i[professional_profile_id submitted_at id],
      order: {submitted_at: :desc, id: :desc},
      where: "deleted_at IS NULL",
      name: "idx_portfolio_items_owner_newest"
    add_check_constraint :portfolio_items,
      "status IN (#{STATUSES.map { |status| quote(status) }.join(", ")})",
      name: "portfolio_items_known_status"
    add_check_constraint :portfolio_items,
      "content_type IN ('image/jpeg', 'image/png')",
      name: "portfolio_items_supported_content_type"
    add_check_constraint :portfolio_items,
      "byte_size > 0 AND width > 0 AND height > 0",
      name: "portfolio_items_valid_image"
  end
end
