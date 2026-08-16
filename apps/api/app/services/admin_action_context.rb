# frozen_string_literal: true

class AdminActionContext
  attr_reader :admin_user_id, :request_id

  def initialize(admin_user_id:, request_id:)
    @admin_user_id = admin_user_id
    @request_id = request_id
  end
end
