# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :actor_user_account, :admin_action_context, :application_session, :request_id, :user_account

  def self.delegated_request?
    application_session&.impersonating? || false
  end
end
