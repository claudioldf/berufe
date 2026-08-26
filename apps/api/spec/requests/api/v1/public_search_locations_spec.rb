# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public search location", type: :request, openapi: true do
  it "returns the supported effective location without allowing response caching" do
    result = PublicSearchLocationResolver::Result.new(
      location: SupportedSearchLocations::FALLBACK,
      source: "ip"
    )
    allow_any_instance_of(PublicSearchLocationResolver).to receive(:call).and_return(result)

    get "/api/v1/public/search-location",
      headers: {"X-Real-IP" => "8.8.8.8", "X-Request-Id" => "search-location-200"}

    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.parsed_body).to eq(
      "data" => {
        "state_code" => "SC",
        "city" => "Joinville",
        "state_slug" => "sc",
        "city_slug" => "joinville",
        "source" => "ip"
      },
      "request_id" => "search-location-200"
    )
    assert_api_conform(status: 200)
  end
end
