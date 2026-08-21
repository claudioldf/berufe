# frozen_string_literal: true

class CreateQuoteChangeRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_change_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :quote,
        type: :uuid,
        null: false,
        foreign_key: {on_delete: :cascade}
      table.integer :requested_revision, null: false
      table.text :message, null: false
      table.datetime :requested_at, null: false
      table.timestamps
    end

    add_index :quote_change_requests,
      %i[quote_id requested_revision],
      unique: true,
      name: "index_quote_change_requests_on_quote_and_revision"
    add_index :quote_change_requests,
      %i[quote_id requested_at id],
      order: {requested_at: :desc, id: :desc},
      name: "index_quote_change_requests_on_quote_and_requested_at"
    add_check_constraint :quote_change_requests,
      "requested_revision >= 0",
      name: "quote_change_requests_nonnegative_revision"
    add_check_constraint :quote_change_requests,
      "char_length(btrim(message)) BETWEEN 1 AND 700",
      name: "quote_change_requests_message_length"
  end
end
