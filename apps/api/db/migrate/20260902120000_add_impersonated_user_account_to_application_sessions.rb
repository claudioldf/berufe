# frozen_string_literal: true

class AddImpersonatedUserAccountToApplicationSessions < ActiveRecord::Migration[8.1]
  def change
    add_reference :application_sessions,
      :impersonated_user_account,
      type: :uuid,
      foreign_key: {to_table: :user_accounts, on_delete: :nullify}
  end
end
