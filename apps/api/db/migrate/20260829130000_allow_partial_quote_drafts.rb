# frozen_string_literal: true

class AllowPartialQuoteDrafts < ActiveRecord::Migration[8.1]
  def up
    change_column_null :quotes, :customer_id, true
    change_column_null :quotes, :customer_phone_e164, true
    change_column :quotes, :customer_phone_e164, :string, limit: 20

    remove_check_constraint :quotes, name: "quotes_customer_brazilian_mobile"
    add_check_constraint :quotes,
      "status = 'draft' OR customer_phone_e164 ~ '^\\+55[1-9][0-9]9[0-9]{8}$'",
      name: "quotes_customer_brazilian_mobile"
    remove_check_constraint :quotes, name: "quotes_consistent_totals"
    add_check_constraint :quotes,
      "status = 'draft' OR (discount_amount <= subtotal_amount AND total_amount = subtotal_amount - discount_amount)",
      name: "quotes_consistent_totals"

    remove_check_constraint :quote_items, name: "quote_items_positive_quantity"
    add_check_constraint :quote_items,
      "quantity >= 0",
      name: "quote_items_nonnegative_quantity"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "partial drafts must be completed before restoring strict quote columns"
  end
end
