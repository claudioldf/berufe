# frozen_string_literal: true

class AddQuoteServiceOutcomeStatuses < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :quotes, name: "quotes_known_status"
    add_check_constraint :quotes,
      "status IN ('draft', 'saved', 'shared', 'change_requested', 'approved', 'declined', 'completed', 'cancelled')",
      name: "quotes_known_status"
  end

  def down
    execute "UPDATE quotes SET status = 'approved' WHERE status IN ('completed', 'cancelled')"

    remove_check_constraint :quotes, name: "quotes_known_status"
    add_check_constraint :quotes,
      "status IN ('draft', 'saved', 'shared', 'change_requested', 'approved', 'declined')",
      name: "quotes_known_status"
  end
end
