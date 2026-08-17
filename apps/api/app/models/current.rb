# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :admin_action_context, :application_session, :request_id, :user_account
end
