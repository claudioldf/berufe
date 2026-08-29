# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional data erasure requests", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.parse("2026-08-29 15:00:00 UTC") }
  let(:account) do
    UserAccount.create!(
      phone_e164: "+5547999998611",
      role: "professional",
      status: "active",
      phone_verified_at: now - 1.day
    )
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  before { travel_to(now) }
  after { travel_back }

  it "accepts an authenticated request, clears the session, and exposes only safe status fields" do
    profile.update_columns(profile_status: "published", updated_at: now)
    session, token = ApplicationSession.issue!(user_account: account, now: now - 5.minutes)

    post_request(token:, request_id: "self-erasure-accepted")

    expect(response).to have_http_status(:accepted)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.headers.fetch("Set-Cookie").downcase).to include(
      "__host-berufe_session=", "path=/", "secure", "httponly", "samesite=lax"
    )
    status_token = response.parsed_body.dig("data", "status_token")
    request_data = response.parsed_body.dig("data", "request")
    expect(status_token).to match(DataErasureStatusToken::PATTERN)
    expect(request_data).to include(
      "status" => "requested",
      "requested_at" => now.iso8601(3),
      "unpublished_at" => now.iso8601(3),
      "completion_deadline_at" => (now + 30.days).iso8601(3),
      "completed_at" => nil
    )
    expect(response.body).not_to include(account.id, account.phone_e164, PrivacySubjectDigest.call(account.phone_e164))
    expect(account.reload.status).to eq("suspended")
    expect(profile.reload.profile_status).to eq("suspended")
    expect(session.reload.revoked_at).to eq(now)
    expect(ProfessionalDataErasureJob).to have_been_enqueued.with(DataErasureRequest.sole.id)
    expect(DataErasureRequest.sole.verification_method).to eq("authenticated_session")
    assert_api_conform(status: 202)

    get "/api/v1/data-erasure-requests/#{status_token}", headers: {"X-Request-Id" => "erasure-status"}

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body.fetch("data")).to eq(request_data)
    expect(response.body).not_to include(account.id, account.phone_e164, PrivacySubjectDigest.call(account.phone_e164))
    assert_api_conform(status: 200)
  end

  it "does not require a recent SMS authentication" do
    profile
    _session, token = ApplicationSession.issue!(user_account: account, now: now - 31.minutes)

    post_request(token:, request_id: "self-erasure-stale-session")

    expect(response).to have_http_status(:accepted)
    expect(account.reload.status).to eq("suspended")
    assert_api_conform(status: 202)
  end

  it "returns service unavailable when the erasure request cannot be persisted" do
    profile
    _session, token = ApplicationSession.issue!(user_account: account, now: now - 5.minutes)
    allow(ProfessionalDataErasureRequester).to receive(:new).and_raise(
      ActiveRecord::StatementInvalid, "database unavailable"
    )

    post_request(token:, request_id: "self-erasure-unavailable")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("erasure_request_unavailable")
    assert_api_conform(status: 503)
  end

  it "rejects anonymous and non-professional sessions" do
    profile
    post_request(token: nil, request_id: "self-erasure-anonymous")
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    admin = UserAccount.create!(
      email: "privacy-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
    _admin_session, admin_token = ApplicationSession.issue!(user_account: admin, now:)
    post_request(token: admin_token, request_id: "self-erasure-admin")

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("authorization_denied")
    expect(account.reload).to be_active
    assert_api_conform(status: 403)
  end

  it "returns a generic not-found response for invalid or unknown status tokens" do
    unknown_token = DataErasureStatusToken.issue
    get "/api/v1/data-erasure-requests/#{unknown_token}", headers: {"X-Request-Id" => "erasure-invalid-token"}

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    assert_api_conform(status: 404)
  end

  it "returns service unavailable when the erasure status cannot be read" do
    status_token = DataErasureStatusToken.issue
    allow(DataErasureRequest).to receive(:find_by!).and_raise(
      ActiveRecord::StatementInvalid, "database unavailable"
    )

    get "/api/v1/data-erasure-requests/#{status_token}",
      headers: {"X-Request-Id" => "erasure-status-unavailable"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("erasure_status_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def post_request(token:, request_id:)
    headers = {
      "Origin" => ENV.fetch("WEB_ORIGIN"),
      "X-Request-Id" => request_id
    }
    headers["Cookie"] = "#{ApplicationSession::COOKIE_NAME}=#{token}" if token
    post "/api/v1/professional/data-erasure-request",
      headers:
  end
end
