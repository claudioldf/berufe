# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional profile photo", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996204", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "attaches the owned processed photo and returns its review state" do
    upload = processed_upload

    put "/api/v1/professional/profile/photo",
      params: {media_upload_id: upload.id},
      headers: session_headers(request_id: "profile-photo", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile", "photo")).to match(
      "current" => hash_including(
        "id" => ProfessionalProfilePhoto.last.id,
        "status" => "pending_review",
        "rejection_reason" => nil
      ),
      "has_published_photo" => false,
      "published_image_url" => nil,
      "latest_upload" => nil
    )
    expect(upload.reload).to be_attached
    assert_api_conform(status: 200)
  end

  it "rejects a photo that has not finished processing" do
    upload = processed_upload(state: "processing")

    put "/api/v1/professional/profile/photo",
      params: {media_upload_id: upload.id},
      headers: session_headers(request_id: "profile-photo-invalid", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "media_upload_id")).to be_present
    assert_api_conform(status: 422)
  end

  it "removes the active photo and returns the refreshed workspace" do
    photo = ProfessionalProfilePhotoAttacher.new.call(
      profile:,
      media_upload_id: processed_upload.id
    )
    profile.update!(published_photo: photo)

    delete "/api/v1/professional/profile/photo",
      headers: session_headers(request_id: "profile-photo-remove", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile", "photo")).to eq(
      "current" => nil,
      "has_published_photo" => false,
      "published_image_url" => nil,
      "latest_upload" => nil
    )
    expect(profile.reload).to have_attributes(
      working_photo: nil,
      published_photo: nil,
      approved_photo: nil
    )
    expect(photo.reload).to be_superseded
    assert_api_conform(status: 200)
  end

  it "denies anonymous, invalid-origin, and missing-profile photo removal" do
    delete "/api/v1/professional/profile/photo",
      headers: {"X-Request-Id" => "profile-photo-remove-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    delete "/api/v1/professional/profile/photo",
      headers: session_headers(request_id: "profile-photo-remove-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    unregistered = UserAccount.create!(phone_e164: "+5547999996206", role: "professional", status: "active")
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    delete "/api/v1/professional/profile/photo",
      headers: session_headers(
        request_id: "profile-photo-remove-missing",
        origin: true,
        token: unregistered_token
      ),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "denies anonymous, invalid-origin, and missing-profile access" do
    put "/api/v1/professional/profile/photo",
      params: {media_upload_id: SecureRandom.uuid},
      headers: {"X-Request-Id" => "profile-photo-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    put "/api/v1/professional/profile/photo",
      params: {media_upload_id: SecureRandom.uuid},
      headers: session_headers(request_id: "profile-photo-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    unregistered = UserAccount.create!(phone_e164: "+5547999996205", role: "professional", status: "active")
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    put "/api/v1/professional/profile/photo",
      params: {media_upload_id: SecureRandom.uuid},
      headers: session_headers(
        request_id: "profile-photo-missing",
        origin: true,
        token: unregistered_token
      ),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def processed_upload(state: "processed")
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state:,
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.jpg",
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
