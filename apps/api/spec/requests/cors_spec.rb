# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CORS", type: :request do
  it "allows credentials from the exact configured Nuxt origin" do
    options "/api/v1/status", headers: {
      "Origin" => ENV.fetch("WEB_ORIGIN"),
      "Access-Control-Request-Method" => "GET",
      "Access-Control-Request-Headers" => "X-CSRF-Token,X-Request-Id"
    }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Access-Control-Allow-Origin")).to eq(ENV.fetch("WEB_ORIGIN"))
    expect(response.headers.fetch("Access-Control-Allow-Origin")).not_to eq("*")
    expect(response.headers.fetch("Access-Control-Allow-Credentials")).to eq("true")
    expect(response.headers.fetch("Access-Control-Allow-Headers").downcase).to include("x-csrf-token", "x-request-id")
    expect(response.headers.fetch("Access-Control-Expose-Headers").downcase).to include("retry-after", "x-request-id")
  end

  it "does not emit CORS permission for any other origin" do
    invalid_origins = [
      "https://untrusted.example",
      "https://berufe-git-feature-preview.vercel.app",
      "#{ENV.fetch("WEB_ORIGIN")}/",
      "#{ENV.fetch("WEB_ORIGIN")}, https://untrusted.example",
      "null",
      "*"
    ]

    invalid_origins.each do |origin|
      options "/api/v1/session", headers: {
        "Origin" => origin,
        "Access-Control-Request-Method" => "DELETE",
        "Access-Control-Request-Headers" => "X-CSRF-Token,X-Request-Id"
      }

      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
      expect(response.headers["Access-Control-Allow-Credentials"]).to be_nil
    end
  end
end
