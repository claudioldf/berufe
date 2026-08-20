# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public professional profile views", type: :request, openapi: true do
  let(:account) { UserAccount.create!(phone_e164: "+5547999997801", role: "professional", status: "active") }
  let(:profile) do
    record = ProfessionalProfile.create!(user_account: account, display_name: "Perfil Métrica")
    make_profile_publicly_eligible(record)
  end
  let(:token) do
    PublicProfileInteractionToken.new.issue(
      professional_id: profile.id,
      service_id: nil,
      search_event_id: nil
    )
  end

  before do
    Rails.application.config.x.berufe.public_interaction_cache.clear
  end

  it "records one daily aggregate and safely ignores a retry" do
    2.times do |index|
      post "/api/v1/public/professionals/#{profile.id}/views",
        params: {interaction_token: token},
        headers: request_headers("profile-view-204-#{index}"),
        as: :json

      expect(response).to have_http_status(:no_content)
      expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    end

    expect(ProfessionalDailyMetric.sole).to have_attributes(professional: profile, profile_views: 1)
    assert_api_conform(status: 204)
  end

  it "rejects missing, invalid, expired, and cross-profile interactions" do
    other = ProfessionalProfile.create!(
      user_account: UserAccount.create!(phone_e164: "+5547999997802", role: "professional", status: "active"),
      display_name: "Outro Perfil"
    )
    other_token = PublicProfileInteractionToken.new.issue(
      professional_id: other.id,
      service_id: nil,
      search_event_id: nil
    )

    [nil, "invalid", other_token].each_with_index do |candidate, index|
      post "/api/v1/public/professionals/#{profile.id}/views",
        params: candidate ? {interaction_token: candidate} : {},
        headers: request_headers("profile-view-422-#{index}"),
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end
    expect(ProfessionalDailyMetric.count).to eq(0)
    assert_api_conform(status: 422)
  end

  it "requires the exact browser origin" do
    post "/api/v1/public/professionals/#{profile.id}/views",
      params: {interaction_token: token},
      headers: {"X-Request-Id" => "profile-view-403", "Origin" => "https://untrusted.example"},
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
    assert_api_conform(status: 403)
  end

  it "returns a generic not-found response when the professional is no longer public" do
    profile
    account.update!(status: "suspended")

    post "/api/v1/public/professionals/#{profile.id}/views",
      params: {interaction_token: token},
      headers: request_headers("profile-view-404"),
      as: :json

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    assert_api_conform(status: 404)
  end

  it "does not expose a metric failure to profile rendering" do
    recorder = instance_double(PublicProfileViewRecorder, call: false)
    allow(PublicProfileViewRecorder).to receive(:new).and_return(recorder)

    post "/api/v1/public/professionals/#{profile.id}/views",
      params: {interaction_token: token},
      headers: request_headers("profile-view-metric-failure"),
      as: :json

    expect(response).to have_http_status(:no_content)
    expect(recorder).to have_received(:call)
  end

  it "uses a safe unavailable response when eligibility cannot be read" do
    allow(ProfessionalProfile).to receive(:publicly_eligible).and_raise(ActiveRecord::ConnectionNotEstablished)

    post "/api/v1/public/professionals/#{SecureRandom.uuid}/views",
      params: {interaction_token: "signed-but-unread"},
      headers: request_headers("profile-view-503"),
      as: :json

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def request_headers(request_id)
    {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id}
  end
end
