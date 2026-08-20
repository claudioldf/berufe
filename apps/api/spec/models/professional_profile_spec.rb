# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfile, type: :model do
  it "belongs to one Rails account, normalizes the approved display name, and starts as a draft" do
    account = UserAccount.create!(phone_e164: "+5547999995001", role: "professional", status: "active")

    profile = described_class.create!(user_account: account, display_name: "  Ana   Souza  ")

    expect(profile.id).to match(/\A[0-9a-f-]{36}\z/)
    expect(profile.display_name).to eq("Ana Souza")
    expect(profile.profile_status).to eq("draft")
    expect(account.reload.professional_profile).to eq(profile)
  end

  it "enforces one profile per account and known status/name values in Rails and PostgreSQL" do
    account = UserAccount.create!(phone_e164: "+5547999995002", role: "professional", status: "active")
    described_class.create!(user_account: account, display_name: "Ana Souza")

    expect do
      described_class.create!(user_account: account, display_name: "Outra Pessoa")
    end.to raise_error(ActiveRecord::RecordNotUnique)

    invalid = described_class.new(user_account: account, display_name: "A", profile_status: "public")
    expect(invalid).not_to be_valid
    expect(invalid.errors[:display_name]).to be_present
    expect(invalid.errors[:profile_status]).to be_present
  end

  it "enforces identity limits and canonical social URLs in Rails" do
    account = UserAccount.create!(phone_e164: "+5547999995003", role: "professional", status: "active")
    profile = described_class.new(
      user_account: account,
      display_name: "Ana Souza",
      headline: "H" * 121,
      bio: "B" * 501,
      years_experience: 71,
      whatsapp_e164: "+5547999995003",
      instagram_url: "https://example.com/ana",
      youtube_url: "https://www.youtube.com/watch?v=unsafe"
    )

    expect(profile).not_to be_valid
    expect(profile.errors).to include(:headline, :bio, :years_experience, :instagram_url, :youtube_url)
  end

  it "keeps the creation source immutable" do
    account = UserAccount.create!(phone_e164: "+5547999995004", role: "professional", status: "active")
    profile = described_class.create!(
      user_account: account,
      display_name: "Ana Externa",
      creation_source: "external",
      external_published_at: Time.current
    )

    profile.creation_source = "self_service"

    expect(profile).not_to be_valid
    expect(profile.errors[:creation_source]).to be_present
  end
end
