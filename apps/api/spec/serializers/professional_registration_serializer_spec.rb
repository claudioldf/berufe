# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalRegistrationSerializer do
  it "returns only the draft profile fields required by the existing registration flow" do
    account = UserAccount.create!(phone_e164: "+5547999998001", role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")

    serialized = described_class.new(profile).as_json

    expect(serialized).to eq(
      status: "completed",
      profile: {id: profile.id, display_name: "Ana Souza", profile_status: "draft"}
    )
    expect(serialized.to_json).not_to include(
      account.phone_e164,
      "user_account_id",
      "terms_version",
      "privacy_notice_version",
      "created_at",
      "updated_at"
    )
  end
end
