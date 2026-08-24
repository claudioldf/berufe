# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfilePhotoRemover do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998144", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:publisher) { instance_double(ModerationMediaPublisher, delete: nil) }

  it "retires every active photo pointer and deletes published variants" do
    now = Time.zone.parse("2026-08-24 12:00:00")
    approved = create_photo(
      status: "approved",
      public_key: "moderation/profile_photo/approved.jpg"
    )
    pending = create_photo(
      status: "pending_review",
      public_key: "moderation/profile_photo/pending.jpg"
    )
    profile.update!(
      working_photo: pending,
      published_photo: pending,
      approved_photo: approved
    )

    described_class.new(publisher:).call(profile:, now:)
    described_class.new(publisher:).call(profile:, now:)

    expect(profile.reload).to have_attributes(
      working_photo: nil,
      published_photo: nil,
      approved_photo: nil
    )
    expect([approved.reload, pending.reload]).to all(
      have_attributes(
        status: "superseded",
        public_key: nil,
        reviewed_at: now
      )
    )
    expect(publisher).to have_received(:delete).with("moderation/profile_photo/approved.jpg").once
    expect(publisher).to have_received(:delete).with("moderation/profile_photo/pending.jpg").once
  end

  private

  def create_photo(status:, public_key:)
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "attached",
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
      processed_at: 1.minute.ago,
      attached_at: Time.current
    )
    profile.profile_photos.create!(
      media_upload: upload,
      status:,
      private_key: upload.sanitized_key,
      public_key:,
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: 2.days.ago,
      reviewed_at: (status == "approved") ? 1.day.ago : nil
    )
  end
end
