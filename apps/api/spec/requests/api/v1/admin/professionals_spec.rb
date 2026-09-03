# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator professional directory", type: :request, openapi: true do
  let(:admin) do
    UserAccount.create!(
      email: "professionals-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:admin_token) { ApplicationSession.issue!(user_account: admin).last }

  let(:unregistered_account) do
    UserAccount.create!(phone_e164: "+5547999994001", role: "professional", status: "active")
  end
  let(:published_profile) do
    account = UserAccount.create!(
      phone_e164: "+5547999994002",
      role: "professional",
      status: "active",
      last_login_at: 2.hours.ago,
      login_count: 3
    )
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
    make_profile_publicly_eligible(profile)
    account.update!(
      terms_accepted_at: Time.current,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
    profile
  end

  before do
    unregistered_account
    published_profile
  end

  it "returns the paginated directory with counts, contact status, and a filtered summary" do
    get "/api/v1/admin/professionals",
      params: {page: 1, per_page: 20},
      headers: session_headers(admin_token, "professionals-index")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    data = response.parsed_body.fetch("data")
    expect(data.fetch("meta")).to eq("page" => 1, "per_page" => 20, "total_count" => 2, "total_pages" => 1)
    expect(data.fetch("summary")).to eq(
      "total" => 2,
      "published" => 1,
      "suspended" => 0,
      "onboarding_finished" => 1,
      "identity_verified" => 0
    )
    published_item = data.fetch("items").find { |item| item.fetch("id") == published_profile.user_account_id }
    expect(published_item).to include(
      "professional_profile_id" => published_profile.id,
      "display_name" => "Ana Souza",
      "profile_status" => "published",
      "city" => "Joinville",
      "state" => "SC",
      "phone_verified" => true,
      "phone_last4" => "4002",
      "account_status" => "active",
      "impersonation_eligible" => true,
      "login_count" => 3
    )
    expect(response.body).not_to include(published_profile.user_account.phone_e164)
    assert_api_conform(status: 200)
  end

  it "filters by name and onboarding completion" do
    get "/api/v1/admin/professionals",
      params: {q: "souza", onboarding_finished: "yes"},
      headers: session_headers(admin_token, "professionals-filtered")

    expect(response).to have_http_status(:ok)
    ids = response.parsed_body.dig("data", "items").pluck("id")
    expect(ids).to eq([published_profile.user_account_id])
    assert_api_conform(status: 200)

    get "/api/v1/admin/professionals",
      params: {onboarding_finished: "no"},
      headers: session_headers(admin_token, "professionals-unfinished")
    ids = response.parsed_body.dig("data", "items").pluck("id")
    expect(ids).to eq([unregistered_account.id])
    assert_api_conform(status: 200)
  end

  it "validates the filters and rejects anonymous and non-admin callers" do
    get "/api/v1/admin/professionals",
      params: {page: 0, per_page: 101, identity_verified: "unknown"},
      headers: session_headers(admin_token, "professionals-invalid")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors").keys).to contain_exactly(
      "page", "per_page", "identity_verified"
    )

    get "/api/v1/admin/professionals", headers: {"X-Request-Id" => "professionals-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    professional = UserAccount.create!(phone_e164: "+5547999994009", role: "professional", status: "active")
    professional_token = ApplicationSession.issue!(user_account: professional).last
    get "/api/v1/admin/professionals", headers: session_headers(professional_token, "professionals-professional")
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  private

  def session_headers(token, request_id)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
  end
end
