# frozen_string_literal: true

require "rails_helper"

RSpec.describe VerificationFileRetentionCleanupJob do
  let(:account) { UserAccount.create!(phone_e164: "+5547999998211", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:storage) { instance_double(LocalDiskStorage, delete: nil) }
  let(:now) { Time.zone.parse("2026-08-17 12:00:00 UTC") }

  it "deletes only evidence whose approval or rejection is at least thirty days old" do
    approved = create_file(status: "approved", reviewed_at: now - 31.days)
    rejected = create_file(status: "rejected", reviewed_at: now - 30.days)
    recent = create_file(status: "approved", reviewed_at: now - 29.days)
    pending = create_file(status: "pending_review", reviewed_at: nil)

    described_class.perform_now(now:, storage:)

    expect(approved.reload.deleted_at).to eq(now)
    expect(rejected.reload.deleted_at).to eq(now)
    expect(recent.reload.deleted_at).to be_nil
    expect(pending.reload.deleted_at).to be_nil
    expect(storage).to have_received(:delete).with(scope: :private, key: approved.private_key)
    expect(storage).to have_received(:delete).with(scope: :private, key: rejected.private_key)
    expect(storage).not_to have_received(:delete).with(scope: :private, key: recent.private_key)
  end

  it "is retry-safe when private storage is temporarily unavailable" do
    file = create_file(status: "rejected", reviewed_at: now - 31.days)
    allow(storage).to receive(:delete).and_raise(Errno::EIO).once
    allow(Rails.error).to receive(:report)

    described_class.perform_now(now:, storage:)
    expect(file.reload.deleted_at).to be_nil
    expect(Rails.error).to have_received(:report).with(
      instance_of(Errno::EIO),
      context: {verification_file_id: file.id}
    )

    allow(storage).to receive(:delete).and_return(nil)
    described_class.perform_now(now:, storage:)
    expect(file.reload.deleted_at).to eq(now)
  end

  private

  def create_file(status:, reviewed_at:)
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "verification_identity",
      state: "attached",
      declared_content_type: "image/png",
      declared_byte_size: 100,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 100,
      sanitized_byte_size: 100,
      width: 10,
      height: 10,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    request_record = profile.verification_requests.create!(
      verification_type: "identity",
      status:,
      submitted_at: 40.days.ago,
      reviewed_at:
    )
    request_record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 10,
      height: 10,
      uploaded_at: 40.days.ago
    )
  end
end
