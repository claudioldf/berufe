# frozen_string_literal: true

class AddWelcomeEmailDeliveryToUserAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :user_accounts, :welcome_email_sent_at, :datetime
  end
end
