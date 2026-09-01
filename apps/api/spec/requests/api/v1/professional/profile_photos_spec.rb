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
  let(:storage) { instance_double(LocalDiskStorage) }

  before do
    allow(MediaStorage).to receive(:build).and_return(storage)
    allow(storage).to receive(:read)
  end

  it "attaches the owned processed photo and publishes it immediately" do
    upload = processed_upload

    put "/api/v1/professional/profile/photo",
      params: {media_upload_id: upload.id},
      headers: session_headers(request_id: "profile-photo", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile", "photo")).to match(
      "current" => hash_including(
        "id" => ProfessionalProfilePhoto.last.id
      ),
      "has_photo" => true,
      "image_url" => a_string_including(ProfessionalProfilePhoto.last.id),
      "latest_upload" => nil
    )
    expect(upload.reload).to be_attached
    assert_api_conform(status: 200)
  end

  it "serves the current photo to its owner while the profile is draft or suspended" do
    photo = ProfessionalProfilePhotoAttacher.new.call(
      profile:,
      media_upload_id: processed_upload.id
    )
    allow(storage).to receive(:read).with(scope: :private, key: photo.private_key).and_return("owner-photo")

    get "/api/v1/professional/profile-photos/#{photo.id}/image",
      headers: session_headers(request_id: "profile-photo-owner-draft")

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("owner-photo")
    expect(response.media_type).to eq("image/jpeg")
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.headers.fetch("X-Content-Type-Options")).to eq("nosniff")
    assert_api_conform(status: 200)

    profile.update!(profile_status: "suspended")
    get "/api/v1/professional/profile-photos/#{photo.id}/image",
      headers: session_headers(request_id: "profile-photo-owner-suspended")

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("owner-photo")
    assert_api_conform(status: 200)
  end

  it "does not expose owner photo previews anonymously or through stale pointers" do
    photo = ProfessionalProfilePhotoAttacher.new.call(
      profile:,
      media_upload_id: processed_upload.id
    )

    get "/api/v1/professional/profile-photos/#{photo.id}/image",
      headers: {"X-Request-Id" => "profile-photo-owner-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    profile.update!(profile_photo: nil)
    get "/api/v1/professional/profile-photos/#{photo.id}/image",
      headers: session_headers(request_id: "profile-photo-owner-stale")
    expect(response).to have_http_status(:not_found)
    expect(storage).not_to have_received(:read)
    assert_api_conform(status: 404)
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

    delete "/api/v1/professional/profile/photo",
      headers: session_headers(request_id: "profile-photo-remove", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile", "photo")).to eq(
      "current" => nil,
      "has_photo" => false,
      "image_url" => nil,
      "latest_upload" => nil
    )
    expect(profile.reload.profile_photo).to be_nil
    expect(photo.reload.deleted_at).to be_present
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
