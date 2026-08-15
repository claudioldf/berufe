# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :application_session, :request_id, :user_account
end
