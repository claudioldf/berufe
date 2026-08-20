# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional verification requests", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996208", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      birthdate: Date.new(1990, 4, 12)
    )
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "submits exactly one private regenerated identity image" do
    upload = processed_upload

    post "/api/v1/professional/verification-requests",
      params: create_params(upload.id),
      headers: session_headers(request_id: "verification-create", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    request_record = VerificationRequest.last
    expect(response.headers["Location"]).to end_with(request_record.id)
    expect(response.parsed_body.dig("data", "profile", "verification", "current")).to include(
      "id" => request_record.id,
      "verification_type" => "identity",
      "status" => "pending_review",
      "rejection_reason" => nil
    )
    expect(response.parsed_body.to_json).not_to include(upload.sanitized_key)
    assert_api_conform(status: 201)
  end

  it "rejects another identity request while one is pending" do
    VerificationRequestCreator.new.call(
      profile:,
      media_upload_id: processed_upload.id,
      verification_type: "identity"
    )

    post "/api/v1/professional/verification-requests",
      params: create_params(processed_upload.id),
      headers: session_headers(request_id: "verification-invalid", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "verification_type")).to be_present
    assert_api_conform(status: 422)
  end

  it "denies anonymous and invalid-origin requests" do
    post "/api/v1/professional/verification-requests",
      params: create_params(SecureRandom.uuid),
      headers: {"X-Request-Id" => "verification-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/verification-requests",
      params: create_params(SecureRandom.uuid),
      headers: session_headers(request_id: "verification-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  it "returns not found for an unregistered professional" do
    unregistered = UserAccount.create!(phone_e164: "+5547999996209", role: "professional", status: "active")
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last

    post "/api/v1/professional/verification-requests",
      params: create_params(SecureRandom.uuid),
      headers: session_headers(
        request_id: "verification-missing",
        origin: true,
        token: unregistered_token
      ),
      as: :json

    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def create_params(upload_id)
    {
      verification_request: {
        media_upload_id: upload_id,
        verification_type: "identity"
      }
    }
  end

  def processed_upload
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "verification_identity",
      state: "processed",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
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
