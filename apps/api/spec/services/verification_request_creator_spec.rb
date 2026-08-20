# frozen_string_literal: true

require "rails_helper"

RSpec.describe VerificationRequestCreator do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998144", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      birthdate: Date.new(1990, 4, 12)
    )
  end

  it "creates one pending identity request with exactly one private regenerated image" do
    upload = processed_upload

    request_record = described_class.new.call(
      profile:,
      media_upload_id: upload.id,
      verification_type: "identity"
    )
    repeated = described_class.new.call(
      profile:,
      media_upload_id: upload.id,
      verification_type: "identity"
    )

    expect(repeated).to eq(request_record)
    expect(request_record).to have_attributes(
      verification_type: "identity",
      status: "pending_review",
      claimed_birthdate: Date.new(1990, 4, 12)
    )
    expect(request_record.verification_file).to have_attributes(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      width: 640,
      height: 960
    )
    expect(upload.reload).to be_attached
  end

  it "rejects a second pending identity request without duplicating records" do
    described_class.new.call(
      profile:,
      media_upload_id: processed_upload.id,
      verification_type: "identity"
    )

    expect do
      described_class.new.call(
        profile:,
        media_upload_id: processed_upload.id,
        verification_type: "identity"
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:verification_type]).to include("já possui uma solicitação em análise")
    }
    expect(profile.verification_requests.count).to eq(1)
    expect(VerificationFile.count).to eq(1)
  end

  it "requires the supported type and a processed identity-purpose image" do
    expect do
      described_class.new.call(
        profile:,
        media_upload_id: processed_upload.id,
        verification_type: "company"
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:verification_type]).to be_present
    }

    expect do
      described_class.new.call(
        profile:,
        media_upload_id: processed_upload(purpose: "portfolio_image").id,
        verification_type: "identity"
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:media_upload_id]).to include("deve ser um envio de identidade")
    }
  end

  private

  def processed_upload(purpose: "verification_identity")
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
      state: "processed",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )
  end
end
