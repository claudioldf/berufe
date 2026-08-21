# frozen_string_literal: true

class BackfillQuoteChangeRequestHistory < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO quote_change_requests (
        id,
        quote_id,
        requested_revision,
        message,
        requested_at,
        created_at,
        updated_at
      )
      SELECT
        gen_random_uuid(),
        quotes.id,
        GREATEST(quotes.lock_version - 1, 0),
        quotes.customer_decision_message,
        COALESCE(quotes.customer_decided_at, quotes.updated_at),
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM quotes
      WHERE quotes.status = 'change_requested'
        AND quotes.customer_decision_message IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM quote_change_requests
          WHERE quote_change_requests.quote_id = quotes.id
        )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Backfilled customer history cannot be distinguished from new requests"
  end
end
