# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaRetentionCleanupJob do
  let(:now) { Time.zone.parse("2026-08-23 16:00:00 UTC") }
  let(:account) { UserAccount.create!(phone_e164: "+5547999998511", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:storage) { instance_double(LocalDiskStorage, delete: nil) }

  it "deletes unattached media after thirty days but preserves recent uploads" do
    old_upload = create_upload("old")
    recent_upload = create_upload("recent")
    old_upload.update_columns(updated_at: now - 31.days)
    recent_upload.update_columns(updated_at: now - 29.days)

    described_class.perform_now(now:, storage:)

    expect(MediaUpload.exists?(old_upload.id)).to be(false)
    expect(MediaUpload.exists?(recent_upload.id)).to be(true)
    expect(storage).to have_received(:delete).with(scope: :private, key: old_upload.quarantine_key)
    expect(storage).not_to have_received(:delete).with(scope: :private, key: recent_upload.quarantine_key)
  end

  private

  def create_upload(label)
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "failed",
      failure_code: "invalid_signature",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      quarantine_key: "quarantine/#{profile.id}/#{label}",
      authorization_expires_at: now - 40.days
    )
  end
end
