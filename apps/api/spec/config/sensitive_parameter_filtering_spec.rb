# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sensitive parameter filtering" do
  it "redacts phone and OTP challenge inputs from structured request parameters" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter(
      "phone" => "+5547999991111",
      "code" => "123456",
      "challenge_token" => "browser-secret",
      "request_id" => "safe-request-id"
    )

    expect(filtered).to include(
      "phone" => "[FILTERED]",
      "code" => "[FILTERED]",
      "challenge_token" => "[FILTERED]",
      "request_id" => "safe-request-id"
    )
  end
end
