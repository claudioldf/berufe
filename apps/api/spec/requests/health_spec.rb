# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health", type: :request do
  it "reports database readiness without configuration details" do
    get "/up"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("status" => "ok")
  end

  it "returns a generic unavailable response when PostgreSQL cannot be reached" do
    allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/up"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq("status" => "unavailable")
    expect(response.body).not_to include("postgresql", "DATABASE_URL")
  end
end
