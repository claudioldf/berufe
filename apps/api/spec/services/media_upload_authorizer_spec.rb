# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaUploadAuthorizer do
  include ActiveSupport::Testing::TimeHelpers

  let(:profile) do
    account = UserAccount.create!(phone_e164: "+5547999998121", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  after { travel_back }

  it "creates an opaque ten-minute local authorization without retaining a client filename" do
    now = Time.zone.parse("2026-08-17 12:00:00 UTC")
    travel_to(now) do
      upload, instruction = described_class.new.call(
        profile:,
        purpose: "profile_photo",
        content_type: "image/jpeg",
        byte_size: 123
      )

      expect(upload).to have_attributes(
        state: "authorized",
        authorization_expires_at: now + 10.minutes,
        declared_byte_size: 123
      )
      expect(upload.quarantine_key).to start_with("quarantine/#{profile.id}/")
      expect(instruction).to include(strategy: "rails", method: "PUT")
      expect(instruction[:url]).to end_with("/media-uploads/#{upload.id}/content")
    end
  end

  it "rejects unsupported types, purposes, and declarations before persistence" do
    expect do
      described_class.new.call(
        profile:,
        purpose: "document",
        content_type: "image/svg+xml",
        byte_size: 0
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors.keys).to contain_exactly(:purpose, :content_type, :byte_size)
    }
    expect(profile.media_uploads).to be_empty
  end
end
