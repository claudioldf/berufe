# frozen_string_literal: true

class CreatePublicSearchEventDeduplications < ActiveRecord::Migration[8.1]
  def change
    create_table :public_search_event_deduplications, id: :uuid do |table|
      table.references :search_event,
        type: :uuid,
        null: false,
        index: false,
        foreign_key: {on_delete: :cascade}
      table.string :subject_digest, limit: 64, null: false
      table.string :query_digest, limit: 64, null: false
      table.integer :result_count, null: false
      table.datetime :expires_at, null: false
      table.timestamps

      table.index %i[subject_digest query_digest result_count],
        unique: true,
        name: "idx_public_search_event_deduplications_unique_claim"
      table.index :expires_at
      table.check_constraint "subject_digest ~ '^[0-9a-f]{64}$'",
        name: "public_search_event_deduplications_subject_digest_format"
      table.check_constraint "query_digest ~ '^[0-9a-f]{64}$'",
        name: "public_search_event_deduplications_query_digest_format"
      table.check_constraint "result_count >= 0",
        name: "public_search_event_deduplications_result_count_nonnegative"
    end
  end
end
