# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phone OTP challenge requests", type: :request, openapi: true do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:otp_client) { instance_double(FakeSmsOtpClient) }

  before do
    allow(SmsOtpClient).to receive(:build).and_return(otp_client)
  end

  after do
    clear_enqueued_jobs
    travel_back
  end

  it "refuses to start a challenge for a missing or cross-site browser origin" do
    invalid_origins = [nil, "https://untrusted.example", "#{ENV.fetch("WEB_ORIGIN")}/", "null"]

    invalid_origins.each_with_index do |origin, index|
      expect do
        post_json(phone: "(47) 99999-1111", request_id: "otp-challenge-origin-#{index}", origin:)
      end.not_to change(OtpChallenge, :count)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
    end
    assert_api_conform(status: 403)
  end

  it "normalizes the phone, starts synchronously, and returns only the browser challenge token" do
    allow(otp_client).to receive(:start_challenge)
      .with(phone: "+5547999991111")
      .and_return(SmsOtp::Challenge.new(reference: "provider-reference", status: "accepted"))

    enqueued_job_count = enqueued_jobs.size
    expect do
      post_json(phone: "(47) 99999-1111", request_id: "otp-accepted")
    end.to change(OtpChallenge, :count).by(1)
      .and change(OtpRequestCounter, :count).by(2)
    expect(enqueued_jobs.size).to eq(enqueued_job_count)

    challenge = OtpChallenge.last
    response_data = response.parsed_body.fetch("data")

    expect(response).to have_http_status(:created)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response_data).to include(
      "status" => "accepted",
      "expires_in" => 600,
      "resend_available_in" => 30
    )
    expect(response_data.fetch("challenge_token")).not_to eq(challenge.public_token_digest)
    expect(response.parsed_body.to_json).not_to include("+5547", "provider-reference")
    expect(challenge.phone_e164).to eq("+5547999991111")
    expect(challenge.provider_reference).to eq("provider-reference")
    expect(OtpRequestCounter.pluck(:subject_digest)).to all(match(/\A[0-9a-f]{64}\z/))
    assert_api_conform(status: 201)
  end

  it "returns the safe invalid-phone outcome without contacting the provider" do
    expect(otp_client).not_to receive(:start_challenge)

    post_json(phone: "47 3333-1111", request_id: "otp-invalid")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "invalid_phone",
        "message" => "Digite um número brasileiro válido.",
        "field_errors" => {"phone" => ["não é válido"]},
        "request_id" => "otp-invalid"
      }
    )
    expect(OtpChallenge.count).to eq(0)
    assert_api_conform(status: 422)
  end

  it "enforces the 30-second resend cooldown with Retry-After" do
    allow_accepted_challenges
    travel_to(Time.zone.parse("2026-08-15 12:00:00 UTC"))
    post_json(phone: "47999991111", request_id: "otp-first")

    travel 10.seconds
    post_json(phone: "47999991111", request_id: "otp-cooldown")

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers.fetch("Retry-After")).to eq("20")
    expect(response.parsed_body.dig("error", "code")).to eq("otp_rate_limited")
    expect(response.parsed_body.dig("error", "message")).to eq("Aguarde antes de pedir outro código.")
    expect(otp_client).to have_received(:start_challenge).once
    assert_api_conform(status: 429)
  end

  it "enforces the approved daily phone allowance" do
    with_otp_setting(:daily_phone_limit, 2) do
      allow_accepted_challenges
      travel_to(Time.zone.parse("2026-08-15 12:00:00 UTC"))

      post_json(phone: "47999991111", request_id: "otp-phone-1")
      travel 31.seconds
      post_json(phone: "47999991111", request_id: "otp-phone-2")
      travel 31.seconds
      post_json(phone: "47999991111", request_id: "otp-phone-limit")

      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers.fetch("Retry-After").to_i).to be > 40_000
      expect(response.parsed_body.dig("error", "message")).to eq(
        "Limite diário de códigos atingido. Tente novamente amanhã."
      )
      expect(otp_client).to have_received(:start_challenge).twice
    end
  end

  it "enforces the approved daily IP allowance across different phones" do
    with_otp_setting(:daily_ip_limit, 2) do
      allow_accepted_challenges
      travel_to(Time.zone.parse("2026-08-15 12:00:00 UTC"))

      post_json(phone: "47999991111", request_id: "otp-ip-1", remote_ip: "203.0.113.8")
      post_json(phone: "48999992222", request_id: "otp-ip-2", remote_ip: "203.0.113.8")
      post_json(phone: "49999993333", request_id: "otp-ip-limit", remote_ip: "203.0.113.8")

      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers.fetch("Retry-After").to_i).to be > 40_000
      expect(otp_client).to have_received(:start_challenge).twice
    end
  end

  it "returns a safe delivery-rejected outcome" do
    allow(otp_client).to receive(:start_challenge).and_raise(SmsOtp::DeliveryRejected)

    post_json(phone: "47999991111", request_id: "otp-rejected")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("otp_delivery_rejected")
    expect(response.parsed_body.to_json).not_to include("47999991111")
    assert_api_conform(status: 422)
  end

  it "returns a safe unavailable outcome when the provider times out" do
    allow(otp_client).to receive(:start_challenge).and_raise(SmsOtp::ProviderUnavailable)

    post_json(phone: "47999991111", request_id: "otp-unavailable")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "otp_provider_unavailable",
        "message" => "Não foi possível enviar o código agora. Tente novamente em instantes.",
        "request_id" => "otp-unavailable"
      }
    )
    assert_api_conform(status: 503)
  end

  it "rejects an accepted provider response without its server-side reference" do
    allow(otp_client).to receive(:start_challenge)
      .and_return(SmsOtp::Challenge.new(reference: "", status: "accepted"))

    post_json(phone: "47999991111", request_id: "otp-malformed-provider")

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("otp_provider_unavailable")
    expect(OtpChallenge.count).to eq(0)
  end

  it "preserves a valid provider Retry-After value and safely defaults an invalid one" do
    allow(otp_client).to receive(:start_challenge)
      .and_raise(SmsOtp::RateLimited.new(retry_after: "45"))

    post_json(phone: "47999991111", request_id: "otp-provider-limit")

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers.fetch("Retry-After")).to eq("45")

    OtpRequestCounter.delete_all
    allow(otp_client).to receive(:start_challenge)
      .and_raise(SmsOtp::RateLimited.new(retry_after: "private"))
    post_json(phone: "47999991111", request_id: "otp-provider-limit-fallback")

    expect(response.headers.fetch("Retry-After")).to eq("60")
  end

  private

  def post_json(phone:, request_id:, remote_ip: "203.0.113.5", origin: ENV.fetch("WEB_ORIGIN"))
    headers = {
      "CONTENT_TYPE" => "application/json",
      "REMOTE_ADDR" => remote_ip,
      "X-Request-Id" => request_id
    }
    headers["Origin"] = origin if origin
    post "/api/v1/auth/otp/challenges", params: {phone:}.to_json, headers:
  end

  def allow_accepted_challenges
    allow(otp_client).to receive(:start_challenge)
      .and_return(SmsOtp::Challenge.new(reference: "provider-reference", status: "accepted"))
  end

  def with_otp_setting(name, value)
    settings = Rails.configuration.x.berufe.otp
    original = settings[name]
    settings[name] = value
    yield
  ensure
    settings[name] = original
  end
end
