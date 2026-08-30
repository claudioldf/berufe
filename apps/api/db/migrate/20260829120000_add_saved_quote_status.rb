# frozen_string_literal: true

class AddSavedQuoteStatus < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :quotes, name: "quotes_consistent_share_state"
    remove_check_constraint :quotes, name: "quotes_known_status"
    add_check_constraint :quotes,
      "status IN ('draft', 'saved', 'shared', 'change_requested', 'approved', 'declined')",
      name: "quotes_known_status"
    add_check_constraint :quotes,
      "(status IN ('draft', 'saved') AND share_token_hash IS NULL AND share_token_ciphertext IS NULL AND shared_at IS NULL) OR " \
        "(status NOT IN ('draft', 'saved') AND share_token_hash IS NOT NULL AND share_token_ciphertext IS NOT NULL AND shared_at IS NOT NULL)",
      name: "quotes_consistent_share_state"
  end

  def down
    execute("UPDATE quotes SET status = 'draft' WHERE status = 'saved'")
    remove_check_constraint :quotes, name: "quotes_consistent_share_state"
    remove_check_constraint :quotes, name: "quotes_known_status"
    add_check_constraint :quotes,
      "status IN ('draft', 'shared', 'change_requested', 'approved', 'declined')",
      name: "quotes_known_status"
    add_check_constraint :quotes,
      "(status = 'draft' AND share_token_hash IS NULL AND share_token_ciphertext IS NULL AND shared_at IS NULL) OR " \
        "(status <> 'draft' AND share_token_hash IS NOT NULL AND share_token_ciphertext IS NOT NULL AND shared_at IS NOT NULL)",
      name: "quotes_consistent_share_state"
  end
end
