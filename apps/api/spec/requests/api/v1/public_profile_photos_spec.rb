# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public profile photos", type: :request, openapi: true do
  let(:account) { UserAccount.create!(phone_e164: "+5547999997301", role: "professional", status: "active") }
  let(:profile) do
    record = ProfessionalProfile.create!(user_account: account, display_name: "Ana Fotógrafa")
    make_profile_publicly_eligible(record)
  end
  let(:storage) { instance_double(LocalDiskStorage) }

  before do
    allow(MediaStorage).to receive(:build).and_return(storage)
    allow(storage).to receive(:read)
  end

  it "serves only the current photo from private storage for an eligible parent" do
    photo = profile.profile_photo
    allow(storage).to receive(:read).with(scope: :private, key: photo.private_key).and_return("jpeg-photo")

    get "/api/v1/public/profile-photos/#{photo.id}/image", headers: {"X-Request-Id" => "photo-200"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("jpeg-photo")
    expect(response.media_type).to eq("image/jpeg")
    expect(response.headers.fetch("Cache-Control")).to eq("max-age=0, public, must-revalidate")
    expect(response.headers.fetch("X-Content-Type-Options")).to eq("nosniff")
    expect(response.headers.fetch("Content-Disposition")).to start_with(
      "inline; filename=\"berufe-profile-photo-#{photo.id}.jpg\""
    )
    assert_api_conform(status: 200)
  end

  it "serves a replacement photo immediately" do
    photo = create_photo
    profile.update!(profile_photo: photo)
    allow(storage).to receive(:read).with(scope: :private, key: photo.private_key).and_return("pending-photo")

    get "/api/v1/public/profile-photos/#{photo.id}/image", headers: {"X-Request-Id" => "photo-pending"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("pending-photo")
    expect(response.headers.fetch("Cache-Control")).to eq("max-age=0, public, must-revalidate")
    assert_api_conform(status: 200)
  end

  it "denies a photo that is not the current pointer or whose parent becomes unavailable" do
    photo = create_photo

    get "/api/v1/public/profile-photos/#{photo.id}/image", headers: {"X-Request-Id" => "photo-not-pointer"}
    expect(response).to have_http_status(:not_found)
    expect(storage).not_to have_received(:read)
    assert_api_conform(status: 404)

    profile.update!(profile_photo: photo)
    account.update!(status: "suspended")
    get "/api/v1/public/profile-photos/#{photo.id}/image", headers: {"X-Request-Id" => "photo-suspended"}
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "returns the generic not-found response when the public object is unavailable" do
    photo = profile.profile_photo
    allow(storage).to receive(:read).and_raise(Errno::ENOENT)

    get "/api/v1/public/profile-photos/#{photo.id}/image", headers: {"X-Request-Id" => "photo-missing"}

    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def create_photo
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "attached",
      declared_content_type: "image/jpeg",
      declared_byte_size: 120,
      actual_content_type: "image/jpeg",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.jpg",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    profile.profile_photos.create!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: 1.minute.ago
    )
  end
end
