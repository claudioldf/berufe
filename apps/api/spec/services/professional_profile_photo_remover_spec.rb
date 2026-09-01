# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfilePhotoRemover do
  let(:account) { UserAccount.create!(phone_e164: "+5547999998144", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "clears and soft-deletes the current photo idempotently" do
    now = Time.zone.parse("2026-08-24 12:00:00")
    photo = create_public_profile_photo(profile)
    profile.update!(profile_photo: photo)

    described_class.new.call(profile:, now:)
    described_class.new.call(profile:, now:)

    expect(profile.reload.profile_photo).to be_nil
    expect(photo.reload.deleted_at).to eq(now)
  end
end
