# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe "Media upload pipeline services" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:profile) do
    account = UserAccount.create!(phone_e164: "+5547999998131", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:root) { Dir.mktmpdir("berufe-media-pipeline") }
  let(:storage) { LocalDiskStorage.new(root:) }
  let(:jpeg) { Vips::Image.black(8, 6).jpegsave_buffer }

  after do
    clear_enqueued_jobs
    FileUtils.remove_entry(root) if File.exist?(root)
    travel_back
  end

  it "accepts exact authorized bytes and enqueues asynchronous processing on completion" do
    upload = create_upload(byte_size: jpeg.bytesize)

    MediaUploadReceiver.new.call(upload:, body: jpeg, content_type: "image/jpeg", storage:)
    expect(storage.read(scope: :private, key: upload.quarantine_key)).to eq(jpeg)
    expect(upload.reload).to be_uploaded

    expect do
      MediaUploadCompleter.new.call(upload:, storage:)
    end.to have_enqueued_job(MediaUploadProcessingJob).with(upload.id)
  end

  it "terminally rejects declaration mismatches and requires a new upload" do
    upload = create_upload(byte_size: jpeg.bytesize + 1)

    expect do
      MediaUploadReceiver.new.call(upload:, body: jpeg, content_type: "image/jpeg", storage:)
    end.to raise_error(MediaUploadReceiver::Rejected, "byte_size_mismatch")
    expect(upload.reload).to have_attributes(state: "failed", failure_code: "byte_size_mismatch")
    expect(upload).not_to be_retryable
  end

  it "expires unused authorizations without accepting late bytes" do
    now = Time.zone.parse("2026-08-17 12:20:00 UTC")
    upload = create_upload(byte_size: jpeg.bytesize, expires_at: now - 1.second)

    expect do
      MediaUploadReceiver.new.call(
        upload:,
        body: jpeg,
        content_type: "image/jpeg",
        now:,
        storage:
      )
    end.to raise_error(MediaUploadReceiver::Rejected, "upload_expired")
    expect(upload.reload).to be_expired
  end

  it "deletes a directly uploaded object whose size does not match its authorization" do
    upload = create_upload(byte_size: jpeg.bytesize + 1)
    storage.write(scope: :private, key: upload.quarantine_key, body: jpeg, content_type: "image/jpeg")

    expect do
      MediaUploadCompleter.new.call(upload:, storage:)
    end.to raise_error(MediaUploadCompleter::Rejected, "uploaded_object_mismatch")
    expect(upload.reload.failure_code).to eq("uploaded_object_mismatch")
    expect { storage.read(scope: :private, key: upload.quarantine_key) }.to raise_error(Errno::ENOENT)
  end

  it "requeues only a transient failure whose quarantined object still exists" do
    upload = create_upload(byte_size: jpeg.bytesize)
    storage.write(scope: :private, key: upload.quarantine_key, body: jpeg, content_type: "image/jpeg")
    upload.update!(state: "failed", failure_code: "storage_unavailable")

    expect do
      MediaUploadRetry.new.call(upload:, storage:)
    end.to have_enqueued_job(MediaUploadProcessingJob).with(upload.id)
    expect(upload.reload).to have_attributes(state: "uploaded", failure_code: nil)

    upload.update!(state: "failed", failure_code: "invalid_image")
    expect do
      MediaUploadRetry.new.call(upload:, storage:)
    end.to raise_error(MediaUploadRetry::Rejected, "upload_not_retryable")
  end

  private

  def create_upload(byte_size:, expires_at: 10.minutes.from_now)
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      declared_content_type: "image/jpeg",
      declared_byte_size: byte_size,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: expires_at
    )
  end
end
