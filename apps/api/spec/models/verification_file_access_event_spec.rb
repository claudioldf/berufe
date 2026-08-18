# frozen_string_literal: true

require "rails_helper"

RSpec.describe VerificationFileAccessEvent do
  it "is an immutable administrator-owned restricted-file audit record" do
    file = create_verification_file
    admin = UserAccount.create!(
      email: "restricted-audit@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
    event = described_class.create!(
      verification_file: file,
      admin_user: admin,
      action: "viewed",
      request_id: "restricted-file-audit",
      created_at: Time.current
    )

    expect { event.update!(request_id: "changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  private

  def create_verification_file
    account = UserAccount.create!(phone_e164: "+5547999998210", role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
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
      status: "pending_review",
      submitted_at: Time.current
    )
    request_record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 10,
      height: 10,
      uploaded_at: Time.current
    )
  end
end
