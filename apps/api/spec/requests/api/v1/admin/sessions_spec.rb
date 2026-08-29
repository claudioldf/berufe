# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator password sessions", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "a-secure-admin-password" }

  after { travel_back }

  it "creates a short Rails session from a normalized email and password" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    account = create_admin(email: "admin@example.com")

    login(email: "admin@example.com", password:, request_id: "admin-login-success")

    session = ApplicationSession.last
    cookie_header = response.headers.fetch("Set-Cookie")
    raw_session_token = cookie_header.match(/__Host-berufe_session=([^;]+)/)[1]
    normalized_cookie_header = cookie_header.downcase
    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body).to eq(
      "data" => {"status" => "authenticated"},
      "request_id" => "admin-login-success"
    )
    expect(session.user_account).to eq(account)
    expect(session.authentication_method).to eq("password")
    expect(session.token_digest).to eq(ApplicationSession.digest_token(raw_session_token))
    expect(session.idle_expires_at).to eq(now + 30.minutes)
    expect(session.absolute_expires_at).to eq(now + 12.hours)
    expect(account.reload.last_login_at).to eq(now)
    expect(account.login_count).to eq(1)
    expect(normalized_cookie_header).to include("path=/", "secure", "httponly", "samesite=lax")
    expect(normalized_cookie_header).not_to include("domain=")
    expect(response.body).not_to include(account.email, password, account.password_digest, raw_session_token)
    assert_api_conform(status: 200)
  end

  it "uses one generic response for unknown, incorrect, and suspended administrator credentials" do
    active = create_admin(email: "active@example.com")
    suspended = create_admin(email: "suspended@example.com", status: "suspended")
    attempts = [
      {email: "unknown@example.com", password:},
      {email: active.email, password: "an-incorrect-password"},
      {email: suspended.email, password:}
    ]

    attempts.each_with_index do |credentials, index|
      login(**credentials, request_id: "admin-login-invalid-#{index}")

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_credentials")
      expect(response.parsed_body.dig("error", "message")).to eq("E-mail ou senha inválidos.")
      expect(response.headers["Set-Cookie"]).to be_nil
    end
    expect(ApplicationSession.count).to eq(0)
    assert_api_conform(status: 401)
  end

  it "requires the exact configured browser origin before checking credentials" do
    account = create_admin(email: "admin@example.com")

    login(
      email: account.email,
      password:,
      origin: "https://untrusted.example",
      request_id: "admin-login-forbidden"
    )

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
    expect(ApplicationSession.count).to eq(0)
    expect(AdminLoginAttemptCounter.count).to eq(0)
    assert_api_conform(status: 403)
  end

  it "rate limits repeated failures without storing raw login identifiers" do
    create_admin(email: "admin@example.com")

    5.times do |index|
      login(
        email: "admin@example.com",
        password: "an-incorrect-password",
        request_id: "admin-login-rate-limit-#{index}"
      )
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig("error", "code")).to eq("login_rate_limited")
    expect(response.headers.fetch("Retry-After").to_i).to be_between(1, 15.minutes.to_i)
    expect(AdminLoginAttemptCounter.pluck(:subject_digest)).to all(match(/\A[0-9a-f]{64}\z/))
    expect(AdminLoginAttemptCounter.all.to_json).not_to include("admin@example.com", "127.0.0.1")
    expect(ApplicationSession.count).to eq(0)
    assert_api_conform(status: 429)
  end

  it "returns a safe unavailable response when authentication persistence fails" do
    allow(AdminPasswordAuthenticator).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    login(email: "admin@example.com", password:, request_id: "admin-login-unavailable")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "admin_login_unavailable",
        "message" => "Não foi possível entrar agora. Tente novamente em instantes.",
        "request_id" => "admin-login-unavailable"
      }
    )
    assert_api_conform(status: 503)
  end

  private

  def create_admin(email:, status: "active")
    UserAccount.create!(
      email:,
      password:,
      password_confirmation: password,
      role: "admin",
      status:
    )
  end

  def login(email:, password:, request_id:, origin: ENV.fetch("WEB_ORIGIN"))
    post "/api/v1/admin/session",
      params: {email:, password:},
      headers: {"Origin" => origin, "X-Request-Id" => request_id},
      as: :json
  end
end
