# frozen_string_literal: true

class AddQuotePricingModesAndMaterials < ActiveRecord::Migration[8.1]
  def up
    add_column :quotes, :pricing_mode, :string, null: false, default: "itemized", limit: 16
    add_column :quotes, :markup_amount, :decimal,
      null: false,
      default: 0,
      precision: 14,
      scale: 2
    add_column :professional_profiles, :last_quote_pricing_mode, :string,
      null: false,
      default: "fixed_price",
      limit: 16

    add_check_constraint :quotes,
      "pricing_mode IN ('fixed_price', 'itemized')",
      name: "quotes_known_pricing_mode"
    add_check_constraint :quotes,
      "markup_amount >= 0",
      name: "quotes_nonnegative_markup"
    add_check_constraint :quotes,
      "pricing_mode = 'fixed_price' OR markup_amount = 0",
      name: "quotes_itemized_without_markup"
    add_check_constraint :professional_profiles,
      "last_quote_pricing_mode IN ('fixed_price', 'itemized')",
      name: "professional_profiles_known_quote_pricing_mode"

    remove_check_constraint :quotes, name: "quotes_consistent_totals"
    add_check_constraint :quotes,
      "status = 'draft' OR " \
      "(discount_amount <= subtotal_amount + markup_amount AND " \
      "total_amount = subtotal_amount + markup_amount - discount_amount)",
      name: "quotes_consistent_totals"

    create_table :quote_materials, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :quote,
        type: :uuid,
        null: false,
        foreign_key: {on_delete: :cascade}
      table.string :description, null: false, limit: 160
      table.decimal :quantity, null: false, precision: 12, scale: 3
      table.string :unit, null: false, limit: 20
      table.integer :sort_order, null: false
      table.timestamps
    end

    add_index :quote_materials, %i[quote_id sort_order], unique: true
    add_check_constraint :quote_materials,
      "quantity >= 0",
      name: "quote_materials_nonnegative_quantity"
    add_check_constraint :quote_materials,
      "sort_order >= 0",
      name: "quote_materials_nonnegative_sort_order"
  end

  def down
    drop_table :quote_materials
    remove_check_constraint :professional_profiles,
      name: "professional_profiles_known_quote_pricing_mode"
    remove_column :professional_profiles, :last_quote_pricing_mode

    remove_check_constraint :quotes, name: "quotes_consistent_totals"
    remove_check_constraint :quotes, name: "quotes_itemized_without_markup"
    remove_check_constraint :quotes, name: "quotes_nonnegative_markup"
    remove_check_constraint :quotes, name: "quotes_known_pricing_mode"
    remove_column :quotes, :markup_amount
    remove_column :quotes, :pricing_mode
    add_check_constraint :quotes,
      "status = 'draft' OR " \
      "(discount_amount <= subtotal_amount AND total_amount = subtotal_amount - discount_amount)",
      name: "quotes_consistent_totals"
  end
end
