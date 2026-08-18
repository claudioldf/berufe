# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaUpload, type: :model do
  let(:profile) do
    account = UserAccount.create!(phone_e164: "+5547999998101", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  it "accepts only the documented purposes, image types, size, and authorization lifetime" do
    upload = described_class.new(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "authorized",
      declared_content_type: "image/jpeg",
      declared_byte_size: 1024,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: 10.minutes.from_now
    )

    expect(upload).to be_valid
    upload.purpose = "other"
    upload.declared_content_type = "image/svg+xml"
    upload.declared_byte_size = MediaUpload::MAX_BYTE_SIZE + 1
    expect(upload).not_to be_valid
  end

  it "only permits explicit retry for transient processing failures" do
    upload = create_upload

    upload.update!(state: "failed", failure_code: "invalid_image")
    expect(upload).not_to be_retryable

    upload.update!(failure_code: "storage_unavailable")
    expect(upload).to be_retryable
  end

  it "enforces media state and size boundaries in PostgreSQL" do
    upload = create_upload

    expect do
      described_class.where(id: upload.id).update_all(state: "unknown")
    end.to raise_error(ActiveRecord::StatementInvalid)
    expect do
      described_class.where(id: upload.id).update_all(declared_byte_size: 0)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  private

  def create_upload
    described_class.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "authorized",
      declared_content_type: "image/jpeg",
      declared_byte_size: 1024,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: 10.minutes.from_now
    )
  end
end
