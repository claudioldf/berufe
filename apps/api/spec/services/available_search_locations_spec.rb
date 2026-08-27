# frozen_string_literal: true

require "rails_helper"

RSpec.describe AvailableSearchLocations do
  it "returns only supported cities covered by a publicly searchable professional" do
    available_profile = create_profile(phone: "+5547999990001", name: "Profissional disponível")
    unavailable_profile = create_profile(phone: "+5547999990002", name: "Profissional suspenso")

    make_profile_publicly_eligible(available_profile)
    make_profile_publicly_eligible(unavailable_profile)
    unavailable_profile.user_account.update!(status: "suspended")

    expect(described_class.new.all).to eq([SupportedSearchLocations::FALLBACK])
  end

  it "returns no cities when no professional is publicly searchable" do
    draft_profile = create_profile(phone: "+5547999990003", name: "Profissional em rascunho")
    ensure_public_supply(draft_profile.working_revision)

    expect(described_class.new.all).to be_empty
  end

  it "does not duplicate a city covered by multiple professionals" do
    first_profile = create_profile(phone: "+5547999990004", name: "Primeiro profissional")
    second_profile = create_profile(phone: "+5547999990005", name: "Segundo profissional")

    make_profile_publicly_eligible(first_profile)
    make_profile_publicly_eligible(second_profile)

    expect(described_class.new.all).to eq([SupportedSearchLocations::FALLBACK])
  end

  private

  def create_profile(phone:, name:)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: name, whatsapp_e164: phone)
  end
end
