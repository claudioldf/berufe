# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional profile submission", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998151", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "submits only the already-persisted complete profile" do
    complete_profile

    post "/api/v1/professional/profile/submission",
      headers: session_headers(request_id: "profile-submit", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile")).to include(
      "profile_status" => "published",
      "is_public" => true,
      "is_search_eligible" => true
    )
    expect(profile.reload.published_revision).to eq(profile.working_revision)
    assert_api_conform(status: 200)
  end

  it "returns actionable checklist errors for an incomplete profile" do
    post "/api/v1/professional/profile/submission",
      headers: session_headers(request_id: "profile-incomplete", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "code")).to eq("profile_incomplete")
    expect(response.parsed_body.dig("error", "field_errors").keys).to contain_exactly(
      "identity",
      "photo",
      "services",
      "coverage"
    )
    assert_api_conform(status: 422)
  end

  it "requires an authenticated owner and the exact browser origin" do
    post "/api/v1/professional/profile/submission",
      headers: {"X-Request-Id" => "profile-submit-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/profile/submission",
      headers: session_headers(request_id: "profile-submit-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    unregistered = UserAccount.create!(
      phone_e164: "+5547999998152",
      role: "professional",
      status: "active"
    )
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    post "/api/v1/professional/profile/submission",
      headers: session_headers(
        request_id: "profile-submit-missing",
        origin: true,
        token: unregistered_token
      ),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def complete_profile
    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: "Ana Souza",
        birthdate: "1990-04-12",
        headline: "Elétrica residencial.",
        bio: "Instalações e manutenção em Joinville.",
        years_experience: 8,
        whatsapp: account.phone_e164,
        instagram: "",
        youtube: ""
      }
    )
    service = create_service
    ProfessionalProfileSupplyUpdater.new.call(
      profile:,
      services: [{service_id: service.id, is_primary: true, note: nil}],
      coverage: {city_code: joinville_city.code, whole_city: true, neighborhood_codes: []}
    )
    ProfessionalProfilePhotoAttacher.new.call(
      profile:,
      media_upload_id: processed_upload("profile_photo").id
    )
  end

  def create_service
    category = ServiceCategory.create!(
      name: "Submissão Request",
      slug: "submissao-request",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    Service.create!(
      category:,
      name: "Eletricista Request",
      slug: "eletricista-request",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  def processed_upload(purpose)
    content_type = (purpose == "profile_photo") ? "image/jpeg" : "image/png"
    extension = (content_type == "image/jpeg") ? "jpg" : "png"
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
      state: "processed",
      declared_content_type: content_type,
      declared_byte_size: 120,
      actual_content_type: content_type,
      sanitized_content_type: content_type,
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.#{extension}",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )
  end

  def session_headers(request_id:, origin: false, token: session_token)
    headers = {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
    headers["Origin"] = (origin == true) ? ENV.fetch("WEB_ORIGIN") : origin if origin
    headers
  end
end
