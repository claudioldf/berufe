# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe MediaUploadProcessor do
  let(:profile) do
    account = UserAccount.create!(phone_e164: "+5547999998141", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:root) { Dir.mktmpdir("berufe-media-processor") }
  let(:storage) { LocalDiskStorage.new(root:) }

  after { FileUtils.remove_entry(root) if File.exist?(root) }

  it "sanitizes a valid private image and deletes its quarantined original" do
    body = Vips::Image.black(16, 10).pngsave_buffer
    upload = create_uploaded(body:, content_type: "image/png")

    described_class.new.call(upload:, storage:)

    upload.reload
    expect(upload).to have_attributes(
      state: "processed",
      actual_content_type: "image/png",
      actual_byte_size: body.bytesize,
      width: 16,
      height: 10,
      processing_attempts: 1,
      failure_code: nil
    )
    expect(storage.read(scope: :private, key: upload.sanitized_key)).to start_with("\x89PNG".b)
    expect { storage.read(scope: :private, key: upload.quarantine_key) }.to raise_error(Errno::ENOENT)
  end

  it "normalizes profile-photo PNG uploads into bounded private JPEG variants" do
    body = Vips::Image.black(1_200, 1_800).pngsave_buffer
    upload = create_uploaded(body:, content_type: "image/png", purpose: "profile_photo")

    described_class.new.call(upload:, storage:)

    upload.reload
    expect(upload).to have_attributes(
      state: "processed",
      actual_content_type: "image/png",
      sanitized_content_type: "image/jpeg",
      width: 1_024,
      height: 1_536
    )
    expect(upload.sanitized_key).to end_with(".jpg")
    expect(storage.read(scope: :private, key: upload.sanitized_key)).to start_with("\xFF\xD8\xFF".b)
  end

  it "deletes terminally invalid originals and does not make them retryable" do
    body = "\xFF\xD8\xFFnot-a-jpeg".b
    upload = create_uploaded(body:, content_type: "image/jpeg")

    described_class.new.call(upload:, storage:)

    expect(upload.reload).to have_attributes(state: "failed", failure_code: "invalid_image")
    expect(upload).not_to be_retryable
    expect { storage.read(scope: :private, key: upload.quarantine_key) }.to raise_error(Errno::ENOENT)
  end

  it "keeps transient storage failures explicitly retryable" do
    upload = create_upload(content_type: "image/jpeg", byte_size: 10)
    unavailable = instance_double(LocalDiskStorage)
    allow(unavailable).to receive(:read).and_raise(Errno::EIO)
    allow(Rails.error).to receive(:report)

    described_class.new.call(upload:, storage: unavailable)

    expect(upload.reload).to have_attributes(state: "failed", failure_code: "storage_unavailable")
    expect(upload).to be_retryable
    expect(Rails.error).to have_received(:report).with(
      instance_of(Errno::EIO),
      context: {media_upload_id: upload.id, failure_code: "storage_unavailable"}
    )
  end

  private

  def create_uploaded(body:, content_type:, purpose: "portfolio_image")
    upload = create_upload(content_type:, byte_size: body.bytesize, purpose:)
    storage.write(scope: :private, key: upload.quarantine_key, body:, content_type:)
    upload
  end

  def create_upload(content_type:, byte_size:, purpose: "portfolio_image")
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
      state: "uploaded",
      declared_content_type: content_type,
      declared_byte_size: byte_size,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: 10.minutes.from_now,
      uploaded_at: Time.current
    )
  end
end
