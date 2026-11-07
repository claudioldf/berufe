# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public support messages", type: :request, openapi: true do
  let(:config) { Rails.application.config.x.berufe }
  let(:emails) { ["ops@example.com", "owner@example.com"] }
  let(:payload) do
    {support_message: {
      name: "Ana Souza", email: "ana@example.com", phone: "(47) 9 9999-7701",
      message: "Quero entender o que acontece com meus dados.", topic: "excluir-conta"
    }}
  end

  before do
    allow(config).to receive(:environment).and_return(config.environment.with(admin_notification_emails: emails))
    ActiveJob::Base.queue_adapter = :test
  end

  it "queues one e-mail per administrator and stores nothing" do
    expect {
      post "/api/v1/public/support-messages", params: payload, headers: request_headers("support-202"), as: :json
    }.to have_enqueued_job(SupportMessageDeliveryJob).exactly(2).times

    expect(response).to have_http_status(:accepted)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body.dig("data", "received")).to be(true)
    assert_api_conform(status: 202)
  end

  it "normalizes the phone before queueing" do
    post "/api/v1/public/support-messages", params: payload, headers: request_headers("support-phone"), as: :json

    expect(SupportMessageDeliveryJob).to have_been_enqueued.with("ops@example.com", hash_including("phone" => "+5547999997701"))
  end

  it "accepts a message without a phone" do
    payload[:support_message].delete(:phone)

    post "/api/v1/public/support-messages", params: payload, headers: request_headers("support-nophone"), as: :json

    expect(response).to have_http_status(:accepted)
  end

  it "returns field errors for invalid input" do
    post "/api/v1/public/support-messages",
      params: {support_message: {name: "A", email: "nope", phone: "123", message: "curto", topic: "geral"}},
      headers: request_headers("support-422"), as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors").keys).to match_array(%w[name email phone message])
    assert_api_conform(status: 422)
  end

  it "rejects a missing support_message envelope" do
    post "/api/v1/public/support-messages", params: {}, headers: request_headers("support-missing"), as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "is unavailable when no administrator address is configured" do
    allow(config).to receive(:environment).and_return(config.environment.with(admin_notification_emails: []))

    post "/api/v1/public/support-messages", params: payload, headers: request_headers("support-503"), as: :json

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("support_unavailable")
    assert_api_conform(status: 503)
  end

  it "rate limits repeated messages from one address" do
    SupportMessageRateLimiter::LIMIT.times do |index|
      post "/api/v1/public/support-messages", params: payload, headers: request_headers("support-rl-#{index}"), as: :json
      expect(response).to have_http_status(:accepted)
    end

    post "/api/v1/public/support-messages", params: payload, headers: request_headers("support-429"), as: :json

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers.fetch("Retry-After").to_i).to be_positive
    assert_api_conform(status: 429)
  end

  it "requires the exact browser origin" do
    post "/api/v1/public/support-messages",
      params: payload,
      headers: request_headers("support-403").merge("Origin" => "https://untrusted.example"),
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
    assert_api_conform(status: 403)
  end

  def request_headers(request_id)
    {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id}
  end
end
