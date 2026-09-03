# frozen_string_literal: true

class AddLumpSumQuotesAndMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :pricing_mode, :string, null: false, default: "itemized", limit: 16
    add_column :quotes, :lump_sum_amount, :decimal, precision: 14, scale: 2
    add_column :quotes, :items_visible_to_customer, :boolean, null: false, default: true

    add_check_constraint :quotes,
      "pricing_mode IN ('itemized', 'lump_sum')",
      name: "quotes_known_pricing_mode"
    add_check_constraint :quotes,
      "pricing_mode <> 'itemized' OR lump_sum_amount IS NULL",
      name: "quotes_itemized_has_no_lump_sum"
    add_check_constraint :quotes,
      "lump_sum_amount IS NULL OR lump_sum_amount >= 0",
      name: "quotes_lump_sum_amount_nonnegative"
    add_check_constraint :quotes,
      "pricing_mode <> 'lump_sum' OR discount_amount = 0",
      name: "quotes_lump_sum_has_no_discount"
    add_check_constraint :quotes,
      "status = 'draft' OR pricing_mode <> 'lump_sum' OR lump_sum_amount IS NOT NULL",
      name: "quotes_lump_sum_requires_amount"

    create_table :quote_materials, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :quote,
        type: :uuid,
        null: false,
        foreign_key: {on_delete: :cascade}
      table.string :description, null: false, limit: 160
      table.decimal :quantity, null: false, precision: 12, scale: 3
      table.string :unit, null: false, limit: 20
      table.integer :sort_order, null: false
    end

    add_index :quote_materials, %i[quote_id sort_order], unique: true
    add_check_constraint :quote_materials, "quantity >= 0", name: "quote_materials_nonnegative_quantity"
    add_check_constraint :quote_materials, "sort_order >= 0", name: "quote_materials_nonnegative_sort_order"
  end
end
