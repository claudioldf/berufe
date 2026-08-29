# frozen_string_literal: true

class AddLoginCountToUserAccounts < ActiveRecord::Migration[8.1]
  def up
    add_column :user_accounts, :login_count, :integer, null: false, default: 0
    add_check_constraint :user_accounts,
      "login_count >= 0",
      name: "user_accounts_nonnegative_login_count"

    execute <<~SQL
      UPDATE user_accounts
      SET login_count = GREATEST(
        (SELECT COUNT(*) FROM application_sessions WHERE application_sessions.user_account_id = user_accounts.id),
        CASE WHEN user_accounts.last_login_at IS NOT NULL THEN 1 ELSE 0 END
      )
    SQL
  end

  def down
    remove_check_constraint :user_accounts, name: "user_accounts_nonnegative_login_count"
    remove_column :user_accounts, :login_count
  end
end
