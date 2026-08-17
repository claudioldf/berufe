# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API status", type: :request, openapi: true do
  it "returns the contracted success response" do
    get "/api/v1/status", headers: {"X-Request-Id" => "contract-status-200"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "data" => {"service" => "berufe-api", "status" => "ok"},
      "request_id" => "contract-status-200"
    )
    assert_api_conform(status: 200)
  end

  it "returns the shared error envelope when the database is unavailable" do
    allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/status", headers: {"X-Request-Id" => "contract-status-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "service_unavailable",
        "message" => "Serviço temporariamente indisponível.",
        "request_id" => "contract-status-503"
      }
    )
    assert_api_conform(status: 503)
  end
end
