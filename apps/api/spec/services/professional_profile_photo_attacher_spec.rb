# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfilePhotoAttacher do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998142", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  it "attaches an owned processed JPEG for review and is idempotent" do
    upload = processed_upload

    photo = described_class.new.call(profile:, media_upload_id: upload.id)
    repeated = described_class.new.call(profile:, media_upload_id: upload.id)

    expect(repeated).to eq(photo)
    expect(photo).to have_attributes(
      status: "pending_review",
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      width: 640,
      height: 960
    )
    expect(upload.reload).to be_attached
    expect(profile.reload.working_photo).to eq(photo)
  end

  it "supersedes only the previous pending photo and preserves the approved pointer" do
    approved = profile.profile_photos.create!(
      media_upload: processed_upload,
      status: "approved",
      private_key: "sanitized/#{profile.id}/approved.jpg",
      public_key: "public/#{profile.id}/approved.jpg",
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: 2.days.ago,
      reviewed_at: 1.day.ago
    )
    profile.update!(published_photo: approved)
    first = described_class.new.call(profile:, media_upload_id: processed_upload.id)

    replacement = described_class.new.call(profile:, media_upload_id: processed_upload.id)

    expect(first.reload).to be_superseded
    expect(replacement).to be_pending_review
    expect(profile.reload).to have_attributes(working_photo: replacement, published_photo: approved)
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
