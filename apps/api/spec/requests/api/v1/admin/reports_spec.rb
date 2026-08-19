# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator growth report", type: :request, openapi: true do
  let(:admin) do
    UserAccount.create!(
      email: "reports-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:admin_token) { ApplicationSession.issue!(user_account: admin).last }

  it "returns every aggregate section, null rates, and no-cache protection for an empty product" do
    get "/api/v1/admin/reports/growth",
      headers: session_headers(admin_token, "growth-empty")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    data = response.parsed_body.fetch("data")
    expect(data.keys).to contain_exactly(
      "generated_at", "period", "privacy_notice", "summary", "supply",
      "discovery", "engagement", "trust", "quotes", "moderation"
    )
    expect(data.dig("period", "key")).to eq("since_launch")
    expect(data.dig("summary", "search_coverage")).to include(
      "numerator" => 0, "denominator" => 0, "rate" => nil
    )
    expect(data.dig("moderation", "oldest_pending_target_hours")).to eq(24)
    expect(data.dig("discovery", "stages").pluck("key")).to eq(
      %w[searches results choice profile_open contact]
    )
    expect(response.body).not_to include("query_text_normalized", "customer_name", "context_note")
    assert_api_conform(status: 200)
  end

  it "validates the period and authorizes anonymous and non-admin callers" do
    allow(Admin::Reports::Period).to receive(:new).and_raise(Admin::Reports::Period::Invalid)
    get "/api/v1/admin/reports/growth",
      params: {period: "since_launch"},
      headers: session_headers(admin_token, "growth-invalid")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to have_key("period")
    assert_api_conform(status: 422)

    get "/api/v1/admin/reports/growth", headers: {"X-Request-Id" => "growth-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    professional = UserAccount.create!(phone_e164: "+5547999998999", role: "professional", status: "active")
    professional_token = ApplicationSession.issue!(user_account: professional).last
    get "/api/v1/admin/reports/growth",
      headers: session_headers(professional_token, "growth-professional")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  private

  def session_headers(token, request_id)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
  end
end
