# frozen_string_literal: true

class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :professional_profiles}
      table.integer :quote_number, null: false
      table.string :customer_name, null: false, limit: 80
      table.string :service_description, null: false, limit: 160
      table.decimal :subtotal_amount, null: false, precision: 14, scale: 2, default: 0
      table.decimal :discount_amount, null: false, precision: 14, scale: 2, default: 0
      table.decimal :total_amount, null: false, precision: 14, scale: 2, default: 0
      table.date :valid_until
      table.text :notes
      table.string :status, null: false, default: "draft", limit: 16
      table.string :share_token_hash, limit: 64
      table.datetime :shared_at
      table.timestamps
    end

    add_index :quotes, %i[professional_id quote_number], unique: true
    add_index :quotes, :share_token_hash, unique: true
    add_index :quotes,
      %i[professional_id created_at id],
      order: {created_at: :desc, id: :desc},
      name: "index_quotes_on_professional_and_recent"
    add_check_constraint :quotes, "quote_number > 0", name: "quotes_positive_number"
    add_check_constraint :quotes,
      "subtotal_amount >= 0 AND discount_amount >= 0 AND total_amount >= 0",
      name: "quotes_nonnegative_amounts"
    add_check_constraint :quotes,
      "discount_amount <= subtotal_amount AND total_amount = subtotal_amount - discount_amount",
      name: "quotes_consistent_totals"
    add_check_constraint :quotes,
      "status IN ('draft', 'shared')",
      name: "quotes_known_status"
    add_check_constraint :quotes,
      "(status = 'draft' AND share_token_hash IS NULL AND shared_at IS NULL) OR " \
      "(status = 'shared' AND share_token_hash IS NOT NULL AND shared_at IS NOT NULL)",
      name: "quotes_consistent_share_state"

    create_table :quote_items, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :quote,
        type: :uuid,
        null: false,
        foreign_key: {on_delete: :cascade}
      table.string :description, null: false, limit: 160
      table.decimal :quantity, null: false, precision: 12, scale: 3
      table.string :unit, null: false, limit: 20
      table.decimal :unit_price, null: false, precision: 14, scale: 2
      table.decimal :line_total, null: false, precision: 14, scale: 2
      table.integer :sort_order, null: false
    end

    add_index :quote_items, %i[quote_id sort_order], unique: true
    add_check_constraint :quote_items, "quantity > 0", name: "quote_items_positive_quantity"
    add_check_constraint :quote_items,
      "unit_price >= 0 AND line_total >= 0",
      name: "quote_items_nonnegative_amounts"
    add_check_constraint :quote_items, "sort_order >= 0", name: "quote_items_nonnegative_sort_order"
  end
end
