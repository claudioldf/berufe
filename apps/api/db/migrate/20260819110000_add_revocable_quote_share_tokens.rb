# frozen_string_literal: true

class AddRevocableQuoteShareTokens < ActiveRecord::Migration[8.1]
  def up
    add_column :quotes, :share_token_ciphertext, :text

    # Share tokens used to be a deterministic HMAC of the quote id, so the same
    # link could never be replaced or revoked. They are random from now on and
    # the owner's copy is kept encrypted, which means every previously issued
    # link has to be retired: the quote returns to `draft` and the professional
    # shares it again to get a fresh link.
    execute(<<~SQL.squish)
      UPDATE quotes
      SET status = 'draft', share_token_hash = NULL, shared_at = NULL
      WHERE status = 'shared'
    SQL

    remove_check_constraint :quotes, name: "quotes_consistent_share_state"
    add_check_constraint :quotes,
      "(status = 'draft' AND share_token_hash IS NULL AND share_token_ciphertext IS NULL AND shared_at IS NULL) " \
        "OR (status = 'shared' AND share_token_hash IS NOT NULL AND share_token_ciphertext IS NOT NULL AND shared_at IS NOT NULL)",
      name: "quotes_consistent_share_state"
  end

  def down
    remove_check_constraint :quotes, name: "quotes_consistent_share_state"
    add_check_constraint :quotes,
      "(status = 'draft' AND share_token_hash IS NULL AND shared_at IS NULL) " \
        "OR (status = 'shared' AND share_token_hash IS NOT NULL AND shared_at IS NOT NULL)",
      name: "quotes_consistent_share_state"
    remove_column :quotes, :share_token_ciphertext
  end
end
