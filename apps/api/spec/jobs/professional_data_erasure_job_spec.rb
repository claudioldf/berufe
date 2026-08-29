# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalDataErasureJob do
  let(:now) { Time.zone.parse("2026-08-23 16:00:00 UTC") }
  let(:storage) { instance_double(LocalDiskStorage, delete: nil) }
  let(:account) do
    UserAccount.create!(
      phone_e164: "+5547999998411",
      role: "professional",
      status: "suspended",
      phone_verified_at: now - 1.day,
      registered_at: now - 1.day,
      terms_accepted_at: now - 1.day,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "deletes eligible account data and storage while retaining only a pseudonymous acceptance record" do
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "attached",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      actual_content_type: "image/jpeg",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 100,
      sanitized_byte_size: 100,
      width: 100,
      height: 100,
      quarantine_key: "quarantine/#{profile.id}/photo",
      sanitized_key: "sanitized/#{profile.id}/photo.jpg",
      authorization_expires_at: now + 5.minutes,
      uploaded_at: now - 1.day,
      processed_at: now - 1.day,
      attached_at: now - 1.day
    )
    photo = profile.profile_photos.create!(
      media_upload: upload,
      status: "rejected",
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      byte_size: 100,
      width: 100,
      height: 100,
      submitted_at: now - 1.day,
      reviewed_at: now - 1.day
    )
    request_record = DataErasureRequest.create!(
      target_user_account_id: account.id,
      subject_digest: PrivacySubjectDigest.call(account.phone_e164),
      ticket_reference: "SUP-2026-003",
      status: "requested",
      verification_method: "recent_sms_otp",
      requested_at: now,
      verified_at: now,
      unpublished_at: now,
      retained_until: now + 5.years
    )

    described_class.perform_now(request_record.id, now:, storage:)

    expect(UserAccount.exists?(account.id)).to be(false)
    expect(ProfessionalProfile.exists?(profile.id)).to be(false)
    expect(MediaUpload.exists?(upload.id)).to be(false)
    expect(ProfessionalProfilePhoto.exists?(photo.id)).to be(false)
    expect(request_record.reload).to have_attributes(status: "completed", completed_at: now)
    expect(request_record.target_user_account_id).to be_nil
    expect(LegalRetentionRecord.sole).to have_attributes(
      subject_digest: request_record.subject_digest,
      record_type: "legal_acceptance",
      occurred_at: account.terms_accepted_at
    )
    expect(LegalRetentionRecord.sole.metadata).to eq(
      "terms_version" => "1.0",
      "privacy_notice_version" => "1.0"
    )
    expect(storage).to have_received(:delete).with(scope: :private, key: upload.quarantine_key)
    expect(storage).to have_received(:delete).with(scope: :private, key: upload.sanitized_key)
  end

  it "is idempotent when a duplicate job runs after completion" do
    profile
    request_record = create_request

    described_class.perform_now(request_record.id, now:, storage:)
    described_class.perform_now(request_record.id, now:, storage:)

    expect(request_record.reload.status).to eq("completed")
    expect(LegalRetentionRecord.where(subject_digest: request_record.subject_digest).count).to eq(1)
  end

  it "keeps the profile unpublished and safely retries after a storage failure" do
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "authorized",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      quarantine_key: "quarantine/#{profile.id}/retry-photo",
      authorization_expires_at: now + 5.minutes
    )
    request_record = create_request
    failed_storage = instance_double(LocalDiskStorage)
    allow(failed_storage).to receive(:delete).and_raise(Aws::S3::Errors::ServiceError.new(nil, "offline"))
    allow(Rails.error).to receive(:report)

    expect do
      described_class.new.perform(request_record.id, now:, storage: failed_storage)
    end.to raise_error(Aws::S3::Errors::ServiceError)

    expect(request_record.reload).to have_attributes(status: "failed", failure_code: "processing_error")
    expect(account.reload.status).to eq("suspended")
    expect(profile.reload.profile_status).to eq("draft")

    described_class.perform_now(request_record.id, now: now + 1.minute, storage:)

    expect(request_record.reload.status).to eq("completed")
    expect(MediaUpload.exists?(upload.id)).to be(false)
    expect(UserAccount.exists?(account.id)).to be(false)
  end

  private

  def create_request
    DataErasureRequest.create!(
      target_user_account_id: account.id,
      subject_digest: PrivacySubjectDigest.call(account.phone_e164),
      ticket_reference: "SUP-2026-retry",
      status: "requested",
      verification_method: "recent_sms_otp",
      requested_at: now,
      verified_at: now,
      unpublished_at: now,
      retained_until: now + 5.years
    )
  end
end
