# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sensitive parameter filtering" do
  it "redacts legal, profile, quote, recommendation, and authentication input" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    result = filter.filter(
      password: "secret",
      phone_e164: "+5547999999999",
      birthdate: "1990-01-01",
      display_name: "Ana Souza",
      service_address: "Rua das Flores, 100",
      recommendation_text: "Texto público após consentimento",
      query_text_normalized: "eletricista",
      status: "published"
    )

    expect(result.except(:status).values).to all(eq("[FILTERED]"))
    expect(result[:status]).to eq("published")
  end
end
