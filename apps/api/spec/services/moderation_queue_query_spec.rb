# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModerationQueueQuery do
  it "lists only identity verification requests oldest first without storage keys" do
    older = create_verification(2.hours.ago)
    newer = create_verification(1.hour.ago)

    result = described_class.new.call

    expect(result[:items].pluck(:target_id)).to eq([older.id, newer.id])
    expect(result[:items].pluck(:target_type).uniq).to eq(["verification_request"])
    expect(result[:summary]).to include(pending_count: 2)
    expect(result.to_json).not_to include("private_key", "sanitized/")
  end

  it "filters, searches accent-insensitively, and paginates" do
    first = create_verification(2.hours.ago)
    create_verification(1.hour.ago)

    searched = described_class.new.call(search: "ana")
    paged = described_class.new.call(page: 2, per_page: 1)

    expect(searched[:items].length).to eq(2)
    expect(paged[:items].sole.fetch(:target_id)).not_to eq(first.id)
    expect(paged[:meta]).to eq(page: 2, per_page: 1, total_count: 2, total_pages: 2)
  end

  it "exposes only retained identity evidence as available" do
    request_record = create_verification(1.hour.ago)
    file = attach_file(request_record)

    expect(described_class.new.call[:items].sole.fetch(:verification_file_id)).to eq(file.id)

    file.update!(deleted_at: Time.current)
    expect(described_class.new.call[:items].sole.fetch(:verification_file_id)).to be_nil
  end

  it "rejects invalid or unbounded filters" do
    expect do
      described_class.new.call(status: "waiting", search: "x" * 101, page: 0, per_page: 51)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors.keys).to contain_exactly(:status, :search, :page, :per_page)
    }
  end

  private

  def create_verification(submitted_at)
    @profile_sequence = @profile_sequence.to_i + 1
    account = UserAccount.create!(
      phone_e164: "+554799998#{format("%04d", @profile_sequence)}",
      role: "professional",
      status: "active"
    )
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ána Souza")
    profile.verification_requests.create!(
      verification_type: "identity",
      status: "pending_review",
      submitted_at:
    )
  end

  def attach_file(request_record)
    profile = request_record.professional_profile
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
