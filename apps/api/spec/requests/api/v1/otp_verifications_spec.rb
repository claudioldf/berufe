# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phone OTP verification", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:otp_client) { instance_double(FakeSmsOtpClient) }

  before do
    allow(SmsOtpClient).to receive(:build).and_return(otp_client)
  end

  after { travel_back }

  it "verifies through the provider, consumes the challenge, and creates an opaque professional session" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    challenge, challenge_token = issue_challenge
    allow(otp_client).to receive(:verify_challenge)
      .with(reference: "provider-reference", code: "123456")
      .and_return(SmsOtp::Verification.new(verified: true, status: "verified"))

    expect do
      verify_json(challenge_token:, code: "123456", request_id: "otp-verified")
    end.to change(UserAccount, :count).by(1)
      .and change(ApplicationSession, :count).by(1)

    account = UserAccount.last
    session = ApplicationSession.last
    cookie_header = response.headers.fetch("Set-Cookie")
    raw_session_token = cookie_header.match(/__Host-berufe_session=([^;]+)/)[1]
    normalized_cookie_header = cookie_header.downcase

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body).to eq(
      "data" => {"status" => "verified"},
      "request_id" => "otp-verified"
    )
    expect(account.phone_e164).to eq("+5547999991111")
    expect(account.role).to eq("professional")
    expect(account.last_login_at).to eq(now)
    expect(session.user_account).to eq(account)
    expect(session.authentication_method).to eq("sms_otp")
    expect(session.token_digest).to eq(ApplicationSession.digest_token(raw_session_token))
    expect(challenge.reload.consumed_at).to eq(now)
    expect(normalized_cookie_header).to include("path=/", "secure", "httponly", "samesite=lax")
    expect(normalized_cookie_header).not_to include("domain=")
    expect(response.parsed_body.to_json).not_to include(
      raw_session_token,
      challenge_token,
      "+5547999991111",
      "provider-reference",
      "123456"
    )
    assert_api_conform(status: 200)
  end

  it "finds an existing Rails account without using the provider reference as identity" do
    account = UserAccount.create!(
      phone_e164: "+5547999991111",
      role: "professional",
      status: "active"
    )
    _challenge, challenge_token = issue_challenge(provider_reference: account.id)
    allow_verified_provider(reference: account.id)

    expect do
      verify_json(challenge_token:, code: "123456", request_id: "otp-existing")
    end.not_to change(UserAccount, :count)

    expect(ApplicationSession.last.user_account).to eq(account)
    expect(UserAccount.find_by(id: account.id)).to eq(account)
  end

  it "uses one generic outcome for malformed, unknown, expired, consumed, and incorrect codes" do
    allow(otp_client).to receive(:verify_challenge)
      .and_return(SmsOtp::Verification.new(verified: false, status: "not_verified"))

    invalid_attempts = [
      {challenge_token: "unknown-token-value-that-is-long-enough-for-contract", code: "123456"},
      {challenge_token: issue_expired_challenge, code: "123456"},
      {challenge_token: issue_challenge(consumed_at: 1.second.from_now).last, code: "123456"},
      {challenge_token: issue_challenge.last, code: "12ab56"},
      {challenge_token: issue_challenge.last, code: "000000"}
    ]

    invalid_attempts.each_with_index do |attempt, index|
      verify_json(**attempt, request_id: "otp-invalid-#{index}")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_otp")
      expect(response.parsed_body.dig("error", "message")).to eq("Código inválido ou expirado.")
      expect(response.headers["Set-Cookie"]).to be_nil
    end
    expect(UserAccount.count).to eq(0)
    expect(ApplicationSession.count).to eq(0)
    assert_api_conform(status: 422)
  end

  it "cannot reuse a consumed challenge" do
    challenge, challenge_token = issue_challenge
    allow_verified_provider
    verify_json(challenge_token:, code: "123456", request_id: "otp-first-verification")

    expect(otp_client).not_to receive(:verify_challenge)
    verify_json(challenge_token:, code: "123456", request_id: "otp-consumed")

    expect(response).to have_http_status(:unprocessable_content)
    expect(challenge.reload.consumed_at).to be_present
    expect(ApplicationSession.count).to eq(1)
  end

  it "keeps the challenge usable and returns a safe result when the provider is unavailable" do
    challenge, challenge_token = issue_challenge
    allow(otp_client).to receive(:verify_challenge).and_raise(SmsOtp::ProviderUnavailable)

    verify_json(challenge_token:, code: "123456", request_id: "otp-verify-unavailable")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "otp_provider_unavailable",
        "message" => "Não foi possível confirmar o código agora. Tente novamente em instantes.",
        "request_id" => "otp-verify-unavailable"
      }
    )
    expect(challenge.reload.consumed_at).to be_nil
    expect(UserAccount.count).to eq(0)
    expect(ApplicationSession.count).to eq(0)
    assert_api_conform(status: 503)
  end

  it "never turns a provider reference into an administrator SMS session" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    travel_to(now)
    admin = UserAccount.create!(
      email: "admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
    _challenge, challenge_token = issue_challenge(provider_reference: admin.id)
    allow_verified_provider(reference: admin.id)

    verify_json(challenge_token:, code: "123456", request_id: "otp-admin-sms")

    session = ApplicationSession.last
    expect(session.user_account).not_to eq(admin)
    expect(session.user_account).to be_professional
    expect(session.authentication_method).to eq("sms_otp")
    expect(session.idle_expires_at).to eq(now + 7.days)
    expect(session.absolute_expires_at).to eq(now + 30.days)
  end

  private

  def issue_challenge(
    phone: "+5547999991111",
    provider_reference: "provider-reference",
    expires_at: 10.minutes.from_now,
    consumed_at: nil
  )
    challenge, token = OtpChallenge.issue!(phone_e164: phone, provider_reference:, expires_at:)
    challenge.update!(consumed_at:) if consumed_at
    [challenge, token]
  end

  def allow_verified_provider(reference: "provider-reference")
    allow(otp_client).to receive(:verify_challenge)
      .with(reference:, code: "123456")
      .and_return(SmsOtp::Verification.new(verified: true, status: "verified"))
  end

  def issue_expired_challenge
    token = nil
    travel_to(20.minutes.ago) do
      _challenge, token = issue_challenge(expires_at: 10.minutes.from_now)
    end
    token
  end

  def verify_json(challenge_token:, code:, request_id:)
    post "/api/v1/auth/otp/verifications",
      params: {challenge_token:, code:}.to_json,
      headers: {
        "CONTENT_TYPE" => "application/json",
        "X-Request-Id" => request_id
      }
  end
end
