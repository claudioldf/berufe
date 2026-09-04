# frozen_string_literal: true

class ReplaceQuoteMarkupWithFixedPrice < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :quotes, name: "quotes_consistent_totals"
    remove_check_constraint :quotes, name: "quotes_itemized_without_markup"
    remove_check_constraint :quotes, name: "quotes_nonnegative_markup"

    rename_column :quotes, :markup_amount, :fixed_price_amount

    execute <<~SQL.squish
      UPDATE quotes
      SET fixed_price_amount = CASE WHEN pricing_mode = 'fixed_price' THEN total_amount ELSE 0 END,
          discount_amount = CASE WHEN pricing_mode = 'fixed_price' THEN 0 ELSE discount_amount END
    SQL

    add_check_constraint :quotes,
      "fixed_price_amount >= 0",
      name: "quotes_nonnegative_fixed_price"
    add_check_constraint :quotes,
      "pricing_mode = 'fixed_price' OR fixed_price_amount = 0",
      name: "quotes_itemized_without_fixed_price"
    add_check_constraint :quotes,
      "pricing_mode = 'itemized' OR discount_amount = 0",
      name: "quotes_fixed_price_without_discount"
    add_check_constraint :quotes,
      "status = 'draft' OR " \
      "((pricing_mode = 'fixed_price' AND discount_amount = 0 AND " \
      "total_amount = fixed_price_amount) OR " \
      "(pricing_mode = 'itemized' AND fixed_price_amount = 0 AND " \
      "discount_amount <= subtotal_amount AND " \
      "total_amount = subtotal_amount - discount_amount))",
      name: "quotes_consistent_totals"
  end

  def down
    remove_check_constraint :quotes, name: "quotes_consistent_totals"
    remove_check_constraint :quotes, name: "quotes_fixed_price_without_discount"
    remove_check_constraint :quotes, name: "quotes_itemized_without_fixed_price"
    remove_check_constraint :quotes, name: "quotes_nonnegative_fixed_price"

    rename_column :quotes, :fixed_price_amount, :markup_amount

    execute <<~SQL.squish
      UPDATE quotes
      SET markup_amount = CASE
            WHEN pricing_mode = 'fixed_price' THEN GREATEST(total_amount - subtotal_amount, 0)
            ELSE 0
          END,
          discount_amount = CASE
            WHEN pricing_mode = 'fixed_price' THEN GREATEST(subtotal_amount - total_amount, 0)
            ELSE discount_amount
          END
    SQL

    add_check_constraint :quotes,
      "markup_amount >= 0",
      name: "quotes_nonnegative_markup"
    add_check_constraint :quotes,
      "pricing_mode = 'fixed_price' OR markup_amount = 0",
      name: "quotes_itemized_without_markup"
    add_check_constraint :quotes,
      "status = 'draft' OR " \
      "(discount_amount <= subtotal_amount + markup_amount AND " \
      "total_amount = subtotal_amount + markup_amount - discount_amount)",
      name: "quotes_consistent_totals"
  end
end
