# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Security headers", type: :request do
  it "protects Rails responses against content sniffing, framing, and referrer leakage" do
    get "/api/v1/status"

    expect(response.headers.fetch("X-Content-Type-Options")).to eq("nosniff")
    expect(response.headers.fetch("X-Frame-Options")).to eq("DENY")
    expect(response.headers.fetch("Referrer-Policy")).to eq("no-referrer")
  end
end
