# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application sessions", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  it "restores a local session and rotates its memory-only CSRF token" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    account = create_account
    application_session, session_token = ApplicationSession.issue!(user_account: account, now:)
    previous_csrf_digest = application_session.csrf_token_digest

    get_current_session(session_token:, request_id: "session-current-1")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body).to match(
      "data" => {
        "account" => {
          "id" => account.id,
          "role" => "professional",
          "status" => "active",
          "registration_completed" => false
        },
        "session" => {
          "authentication_method" => "sms_otp",
          "authenticated_at" => now.iso8601(3),
          "mfa_authenticated" => false,
          "idle_expires_at" => (now + 7.days).iso8601(3),
          "absolute_expires_at" => (now + 30.days).iso8601(3)
        },
        "csrf_token" => a_string_matching(/\A[A-Za-z0-9_-]{43}\z/)
      },
      "request_id" => "session-current-1"
    )
    csrf_token = response.parsed_body.dig("data", "csrf_token")
    expect(application_session.reload.csrf_token_digest).to eq(
      SessionSecurityDigest.call(purpose: "csrf_token", value: csrf_token)
    )
    expect(application_session.csrf_token_digest).not_to eq(previous_csrf_digest)
    expect(response.body).not_to include(session_token, account.phone_e164)
    assert_api_conform(status: 200)

    get_current_session(session_token:, request_id: "session-current-2")
    expect(response.parsed_body.dig("data", "csrf_token")).not_to eq(csrf_token)
  end

  it "restores an authorized admin session without exposing private account fields" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    account = UserAccount.create!(phone_e164: "+5547999992222", role: "admin", status: "active")
    _application_session, session_token = ApplicationSession.issue!(
      user_account: account,
      now:,
      mfa_authenticated_at: now
    )

    get_current_session(session_token:, request_id: "admin-session-current")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "account")).to eq(
      "id" => account.id,
      "role" => "admin",
      "status" => "active",
      "registration_completed" => false
    )
    expect(response.parsed_body.dig("data", "session", "mfa_authenticated")).to be(true)
    expect(response.body).not_to include(account.phone_e164)
    assert_api_conform(status: 200)
  end

  it "returns a generic forbidden response when record authorization denies access" do
    account = create_account
    application_session, session_token = ApplicationSession.issue!(user_account: account)
    previous_csrf_digest = application_session.csrf_token_digest
    allow_any_instance_of(ApplicationSessionPolicy).to receive(:show?).and_return(false)

    get_current_session(session_token:, request_id: "session-policy-denied")

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "authorization_denied",
        "message" => "Você não tem permissão para realizar esta ação.",
        "request_id" => "session-policy-denied"
      }
    )
    expect(response.body).not_to include(account.phone_e164)
    expect(application_session.reload.csrf_token_digest).to eq(previous_csrf_digest)
    assert_api_conform(status: 403)
  end

  it "rejects missing, unknown, idle-expired, and absolute-expired sessions generically" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    account = create_account
    _idle_session, idle_token = ApplicationSession.issue!(user_account: account, now: now - 7.days)
    absolute_session, absolute_token = ApplicationSession.issue!(user_account: account, now: now - 30.days)
    absolute_session.update_columns(
      last_active_at: now - 1.second,
      idle_expires_at: now,
      updated_at: now
    )

    [nil, "unknown-session-token", idle_token, absolute_token].each_with_index do |token, index|
      get_current_session(session_token: token, request_id: "session-invalid-#{index}")

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("authentication_required")
      expect(response.parsed_body.dig("error", "message")).to eq("Entre novamente para continuar.")
      expect(response.headers.fetch("Set-Cookie").downcase).to include(
        "__host-berufe_session=",
        "path=/",
        "secure",
        "httponly",
        "samesite=lax"
      )
    end
    assert_api_conform(status: 401)
  end

  it "logs out only the current session and clears the host-only cookie" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    account = create_account
    first_session, first_token = ApplicationSession.issue!(user_account: account, now:)
    second_session, second_token = ApplicationSession.issue!(user_account: account, now: now + 1.minute)

    get_current_session(session_token: first_token, request_id: "session-before-logout")
    csrf_token = response.parsed_body.dig("data", "csrf_token")
    delete_current_session(
      session_token: first_token,
      csrf_token:,
      origin: ENV.fetch("WEB_ORIGIN"),
      request_id: "session-logout"
    )

    expect(response).to have_http_status(:no_content)
    expect(response.body).to be_empty
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    cleared_cookie = response.headers.fetch("Set-Cookie").downcase
    expect(cleared_cookie).to include("__host-berufe_session=", "path=/", "secure", "httponly", "samesite=lax")
    expect(cleared_cookie).not_to include("domain=")
    expect(first_session.reload.revoked_at).to eq(now)
    expect(second_session.reload.revoked_at).to be_nil
    assert_api_conform(status: 204)

    get_current_session(session_token: second_token, request_id: "session-still-active")
    expect(response).to have_http_status(:ok)
  end

  it "rejects missing, invalid, malformed, preview, and cross-site mutation credentials" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = create_account
    application_session, session_token = ApplicationSession.issue!(user_account: account, now:)
    get_current_session(session_token:, request_id: "session-before-rejected-logout")
    csrf_token = response.parsed_body.dig("data", "csrf_token")
    allowed_origin = ENV.fetch("WEB_ORIGIN")
    attempts = [
      {origin: allowed_origin, csrf_token: nil},
      {origin: allowed_origin, csrf_token: "invalid-csrf-token"},
      {origin: nil, csrf_token:},
      {origin: "#{allowed_origin}/", csrf_token:},
      {origin: "#{allowed_origin}, https://untrusted.example", csrf_token:},
      {origin: "null", csrf_token:},
      {origin: "https://berufe-git-feature-preview.vercel.app", csrf_token:},
      {origin: "https://untrusted.example", csrf_token:}
    ]

    attempts.each_with_index do |attempt, index|
      delete_current_session(
        session_token:,
        request_id: "session-forbidden-#{index}",
        **attempt
      )

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
      expect(response.parsed_body.dig("error", "message")).to eq("Não foi possível validar esta solicitação.")
      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil unless attempt[:origin] == allowed_origin
      expect(response.headers["Set-Cookie"]).to be_nil
      expect(application_session.reload.revoked_at).to be_nil
    end
    assert_api_conform(status: 403)
  end

  it "clears stale cookies when logout no longer has an active session" do
    delete_current_session(session_token: "unknown-session-token", request_id: "session-logout-stale")

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("authentication_required")
    expect(response.headers.fetch("Set-Cookie").downcase).to include(
      "__host-berufe_session=",
      "path=/",
      "secure",
      "httponly",
      "samesite=lax"
    )
    assert_api_conform(status: 401)
  end

  it "invalidates every session after revoke-all or suspension" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    account = create_account
    first_session, first_token = ApplicationSession.issue!(user_account: account, now:)
    second_session, second_token = ApplicationSession.issue!(user_account: account, now: now + 1.minute)

    account.revoke_all_sessions!(now: now + 2.minutes)
    [first_token, second_token].each_with_index do |token, index|
      get_current_session(session_token: token, request_id: "session-revoked-#{index}")
      expect(response).to have_http_status(:unauthorized)
    end
    expect(first_session.reload.revoked_at).to eq(now + 2.minutes)
    expect(second_session.reload.revoked_at).to eq(now + 2.minutes)

    third_session, third_token = ApplicationSession.issue!(user_account: account, now: now + 3.minutes)
    account.suspend!(now: now + 4.minutes)
    get_current_session(session_token: third_token, request_id: "session-suspended")

    expect(response).to have_http_status(:unauthorized)
    expect(third_session.reload.revoked_at).to eq(now + 4.minutes)
  end

  it "continues authenticating locally while the SMS provider is unavailable" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = create_account
    _application_session, session_token = ApplicationSession.issue!(user_account: account, now:)
    allow(SmsOtpClient).to receive(:build).and_raise(SmsOtp::ProviderUnavailable)

    get_current_session(session_token:, request_id: "session-provider-outage")

    expect(response).to have_http_status(:ok)
    expect(SmsOtpClient).not_to have_received(:build)
  end

  it "returns a safe unavailable response when session persistence fails" do
    allow(ApplicationSessionAuthenticator).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get_current_session(session_token: "opaque-session-token", request_id: "session-db-down")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "session_unavailable",
        "message" => "Não foi possível consultar sua sessão agora.",
        "request_id" => "session-db-down"
      }
    )
    assert_api_conform(status: 503)
  end

  it "returns the same safe unavailable response when logout persistence fails" do
    allow(ApplicationSessionAuthenticator).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    delete_current_session(session_token: "opaque-session-token", request_id: "session-logout-db-down")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("session_unavailable")
    expect(response.parsed_body.dig("error", "request_id")).to eq("session-logout-db-down")
    assert_api_conform(status: 503)
  end

  private

  def create_account
    UserAccount.create!(phone_e164: "+5547999991111", role: "professional", status: "active")
  end

  def session_headers(session_token:, request_id:)
    headers = {"X-Request-Id" => request_id}
    headers["Cookie"] = "#{ApplicationSession::COOKIE_NAME}=#{session_token}" if session_token
    headers
  end

  def get_current_session(session_token:, request_id:)
    get "/api/v1/session", headers: session_headers(session_token:, request_id:)
  end

  def delete_current_session(session_token:, request_id:, csrf_token: nil, origin: nil)
    headers = session_headers(session_token:, request_id:)
    headers["X-CSRF-Token"] = csrf_token if csrf_token
    headers["Origin"] = origin if origin
    delete "/api/v1/session", headers:
  end
end
