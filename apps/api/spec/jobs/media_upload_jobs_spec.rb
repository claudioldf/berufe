# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe "Media upload jobs", type: :job do
  let(:profile) do
    account = UserAccount.create!(phone_e164: "+5547999998151", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:root) { Dir.mktmpdir("berufe-media-jobs") }
  let(:storage) { LocalDiskStorage.new(root:) }

  after { FileUtils.remove_entry(root) if File.exist?(root) }

  it "processes an existing upload idempotently on the default queue" do
    body = Vips::Image.black(4, 3).jpegsave_buffer
    upload = create_upload(state: "uploaded", byte_size: body.bytesize)
    storage.write(scope: :private, key: upload.quarantine_key, body:, content_type: "image/jpeg")
    allow(MediaStorage).to receive(:build).and_return(storage)

    2.times { MediaUploadProcessingJob.perform_now(upload.id) }

    expect(upload.reload).to be_processed
    expect(upload.processing_attempts).to eq(1)
    expect(MediaUploadProcessingJob.new.queue_name).to eq("default")
  end

  it "expires only abandoned authorizations and deletes any quarantined object" do
    expired = create_upload(expires_at: 1.minute.ago)
    active = create_upload(expires_at: 1.minute.from_now)
    storage.write(scope: :private, key: expired.quarantine_key, body: "partial")

    MediaUploadAuthorizationCleanupJob.perform_now(now: Time.current, storage:)

    expect(expired.reload).to be_expired
    expect(active.reload).to be_authorized
    expect { storage.read(scope: :private, key: expired.quarantine_key) }.to raise_error(Errno::ENOENT)
    expect(MediaUploadAuthorizationCleanupJob.new.queue_name).to eq("default")
  end

  private

  def create_upload(state: "authorized", byte_size: 10, expires_at: 10.minutes.from_now)
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state:,
      declared_content_type: "image/jpeg",
      declared_byte_size: byte_size,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: expires_at,
      uploaded_at: (Time.current if state == "uploaded")
    )
  end
end
