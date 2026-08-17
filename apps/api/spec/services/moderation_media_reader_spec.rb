# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModerationMediaReader do
  let(:admin) do
    UserAccount.create!(
      email: "moderation-media@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:account) { UserAccount.create!(phone_e164: "+5547999998204", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: "moderation-media-read") }
  let(:storage) { instance_double(LocalDiskStorage) }

  it "reads only regenerated private bytes and records the administrator access" do
    photo = create_photo
    allow(storage).to receive(:read).with(scope: :private, key: photo.private_key).and_return("private-image")

    result = described_class.new(context:, storage:).call(
      target_type: "profile_photo",
      target_id: photo.id
    )

    expect(result).to have_attributes(body: "private-image", content_type: "image/jpeg")
    expect(result.filename).to eq("berufe-analise-profile_photo-#{photo.id}.jpg")
    expect(ModerationMediaAccessEvent.sole).to have_attributes(
      admin_user: admin,
      target_type: "profile_photo",
      target_id: photo.id,
      request_id: "moderation-media-read"
    )
  end

  it "does not log access when the object cannot be read" do
    photo = create_photo
    allow(storage).to receive(:read).and_raise(Errno::ENOENT)

    expect do
      described_class.new(context:, storage:).call(target_type: "profile_photo", target_id: photo.id)
    end.to raise_error(Errno::ENOENT)
    expect(ModerationMediaAccessEvent.count).to eq(0)
  end

  private

  def create_photo
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "processed",
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
      processed_at: Time.current
    )
    profile.profile_photos.create!(
      media_upload: upload,
      status: "pending_review",
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: Time.current
    )
  end
end
