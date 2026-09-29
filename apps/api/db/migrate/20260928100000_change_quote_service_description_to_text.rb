# frozen_string_literal: true

class ChangeQuoteServiceDescriptionToText < ActiveRecord::Migration[8.1]
  CONSTRAINT_NAME = "quotes_service_description_length"

  def up
    change_column :quotes, :service_description, :text, null: false
    add_check_constraint :quotes,
      "char_length(service_description) <= 1000",
      name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :quotes, name: CONSTRAINT_NAME
    execute <<~SQL.squish
      UPDATE quotes
      SET service_description = left(service_description, 160)
      WHERE char_length(service_description) > 160
    SQL
    change_column :quotes, :service_description, :string, limit: 160, null: false
  end
end
