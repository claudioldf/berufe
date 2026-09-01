# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfilePhotoAttacher do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998142", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  it "attaches an owned processed JPEG and is idempotent" do
    upload = processed_upload

    photo = described_class.new.call(profile:, media_upload_id: upload.id)
    repeated = described_class.new.call(profile:, media_upload_id: upload.id)

    expect(repeated).to eq(photo)
    expect(photo).to have_attributes(
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      width: 640,
      height: 960
    )
    expect(upload.reload).to be_attached
    expect(profile.reload.profile_photo).to eq(photo)
  end

  it "replaces the current photo and soft-deletes the previous one" do
    previous = profile.profile_photos.create!(
      media_upload: processed_upload,
      private_key: "sanitized/#{profile.id}/approved.jpg",
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: 2.days.ago
    )
    profile.update!(profile_photo: previous)
    replacement = described_class.new.call(profile:, media_upload_id: processed_upload.id)

    expect(previous.reload.deleted_at).to be_present
    expect(profile.reload.profile_photo).to eq(replacement)
  end

  it "rejects unprocessed uploads and uploads for another purpose" do
    unprocessed = processed_upload(state: "processing")
    wrong_purpose = processed_upload(purpose: "portfolio_image")

    expect do
      described_class.new.call(profile:, media_upload_id: unprocessed.id)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:media_upload_id]).to include("a imagem ainda não terminou de processar")
    }
    expect do
      described_class.new.call(profile:, media_upload_id: wrong_purpose.id)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:media_upload_id]).to include("deve ser um envio de foto de perfil")
    }
  end

  private

  def processed_upload(state: "processed", purpose: "profile_photo")
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
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
end
