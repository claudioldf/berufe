# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfileVisibilityUpdater do
  let(:profile) do
    account = UserAccount.create!(
      phone_e164: "+5547999998173",
      role: "professional",
      status: "active"
    )
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Visibilidade")
  end

  it "persists a known visibility for a published profile" do
    make_profile_publicly_eligible(profile)

    described_class.new.call(profile:, visibility: "direct_link")

    expect(profile.reload.public_visibility).to eq("direct_link")
  end

  it "rejects unknown visibility values" do
    make_profile_publicly_eligible(profile)

    expect do
      described_class.new.call(profile:, visibility: "private")
    end.to raise_error(described_class::Invalid) do |error|
      expect(error.field_errors).to include(:visibility)
    end
    expect(profile.reload.public_visibility).to eq("discoverable")
  end

  it "rejects visibility changes for a draft or moderated profile" do
    expect do
      described_class.new.call(profile:, visibility: "unpublished")
    end.to raise_error(described_class::Unavailable)

    make_profile_publicly_eligible(profile)
    profile.update!(profile_status: "suspended")

    expect do
      described_class.new.call(profile:, visibility: "unpublished")
    end.to raise_error(described_class::Unavailable)
  end
end
