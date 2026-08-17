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
end
