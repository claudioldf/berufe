# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locations", type: :request, openapi: true do
  let!(:joinville) { joinville_city }
  let!(:america) { create_location_neighborhood }

  it "lists states in display order" do
    get "/api/v1/locations/states", headers: {"X-Request-Id" => "locations-states"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to include(
      "code" => "42",
      "abbreviation" => "SC",
      "name" => "Santa Catarina"
    )
    assert_api_conform(status: 200)
  end

  it "lists cities for a state abbreviation" do
    get "/api/v1/locations/states/SC/cities", headers: {"X-Request-Id" => "locations-cities"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to include(
      "code" => joinville.code,
      "name" => "Joinville",
      "slug" => "joinville",
      "state_code" => "42",
      "state_abbreviation" => "SC",
      "state_name" => "Santa Catarina"
    )
    assert_api_conform(status: 200)
  end

  it "lists neighborhoods only for the selected city" do
    get "/api/v1/locations/cities/#{joinville.code}/neighborhoods",
      headers: {"X-Request-Id" => "locations-neighborhoods"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq([
      {"code" => america.code, "city_code" => joinville.code, "name" => "América"}
    ])
    assert_api_conform(status: 200)
  end

  it "returns not found for an unknown state or city" do
    get "/api/v1/locations/states/XX/cities"
    expect(response).to have_http_status(:not_found)

    get "/api/v1/locations/cities/0000000/neighborhoods"
    expect(response).to have_http_status(:not_found)
  end

  it "returns unavailable responses when location queries fail" do
    allow(State).to receive(:ordered).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/locations/states", headers: {"X-Request-Id" => "locations-states-unavailable"}
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)

    allow(State).to receive(:find_by!).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/locations/states/SC/cities", headers: {"X-Request-Id" => "locations-cities-unavailable"}
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)

    allow(City).to receive(:find).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/locations/cities/#{joinville.code}/neighborhoods",
      headers: {"X-Request-Id" => "locations-neighborhoods-unavailable"}
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end
end
