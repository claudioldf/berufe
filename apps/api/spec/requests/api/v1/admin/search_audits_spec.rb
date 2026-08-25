# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator search audits", type: :request, openapi: true do
  let(:admin) do
    UserAccount.create!(
      email: "search-audits-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:admin_token) { ApplicationSession.issue!(user_account: admin).last }

  it "returns only the rolling seven-day prompt window in newest-first pages" do
    now = Time.current
    older = create_audit(prompt: "Busca antiga", created_at: now - 8.days)
    newest = create_audit(prompt: "Preciso de pintor", created_at: now - 1.hour)
    limited = create_audit(
      prompt: "Preciso de eletricista",
      status: "application_rate_limited",
      raw_response: nil,
      parsed_response: nil,
      result_count: 0,
      created_at: now - 2.hours
    )

    get "/api/v1/admin/search-audits",
      params: {page: 1, per_page: 2},
      headers: session_headers(admin_token, "search-audits-index")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    data = response.parsed_body.fetch("data")
    expect(data.fetch("meta")).to eq(
      "page" => 1,
      "per_page" => 2,
      "total_count" => 2,
      "total_pages" => 1
    )
    expect(data.fetch("items").pluck("id")).to eq([newest.id, limited.id])
    expect(data.fetch("items").first).to include(
      "input_prompt" => "Preciso de pintor",
      "raw_llm_response" => '{"service_ids":[]}',
      "status" => "completed",
      "response_source" => "provider",
      "result_count" => 3
    )
    expect(data.fetch("items").second).to include(
      "input_prompt" => "Preciso de eletricista",
      "raw_llm_response" => nil,
      "parsed_response" => nil,
      "status" => "application_rate_limited",
      "result_count" => 0
    )
    expect(data.fetch("items").pluck("id")).not_to include(older.id)
    assert_api_conform(status: 200)
  end

  it "validates pagination and rejects anonymous and non-admin callers" do
    get "/api/v1/admin/search-audits",
      params: {page: 0, per_page: 101},
      headers: session_headers(admin_token, "search-audits-invalid")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors").keys).to contain_exactly("page", "per_page")

    get "/api/v1/admin/search-audits", headers: {"X-Request-Id" => "search-audits-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    professional = UserAccount.create!(phone_e164: "+5547999998111", role: "professional", status: "active")
    professional_token = ApplicationSession.issue!(user_account: professional).last
    get "/api/v1/admin/search-audits",
      headers: session_headers(professional_token, "search-audits-professional")
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  private

  def create_audit(
    prompt:,
    created_at:,
    status: "completed",
    raw_response: '{"service_ids":[]}',
    parsed_response: {
      service_ids: [], services: [], locations: [], keywords: [], normalized_request: nil
    },
    result_count: 3
  )
    SearchEvent.create!(
      input_prompt: prompt,
      raw_llm_response: raw_response,
      parsed_response:,
      audit_status: status,
      response_source: raw_response && "provider",
      llm_adapter: raw_response && "fake",
      llm_model: raw_response && "gpt-5-mini",
      llm_prompt_digest: raw_response && "a" * 64,
      city_code: SearchEvent::JOINVILLE,
      result_count:,
      reportable: status == "completed",
      created_at:
    )
  end

  def session_headers(token, request_id)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
  end
end
