# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfileIdentityUpdater do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996101", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  it "normalizes and persists the complete identity/contact step" do
    result = described_class.new.call(
      profile:,
      attributes: {
        display_name: "  Ana   Souza  ",
        headline: "  Elétrica residencial com cuidado. ",
        bio: "  Instalações e manutenção   em Joinville. ",
        years_experience: "12",
        whatsapp: "(47) 99999-6102",
        instagram: "@ana.obras",
        youtube: "youtube.com/@AnaObras?utm_source=berufe"
      }
    )

    expect(result.working_revision.attributes).to include(
      "display_name" => "Ana Souza",
      "headline" => "Elétrica residencial com cuidado.",
      "bio" => "Instalações e manutenção em Joinville.",
      "years_experience" => 12,
      "whatsapp_e164" => "+5547999996102",
      "instagram_url" => "https://www.instagram.com/ana.obras/",
      "youtube_url" => "https://www.youtube.com/@AnaObras"
    )
  end

  it "returns actionable field errors without partially updating" do
    expect do
      described_class.new.call(
        profile:,
        attributes: {
          display_name: "A",
          headline: "",
          bio: "",
          years_experience: 71,
          whatsapp: "123",
          instagram: nil,
          youtube: nil
        }
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors).to include(whatsapp: ["informe um celular brasileiro com DDD"])
    }

    expect(profile.reload.display_name).to eq("Ana Souza")
    expect(profile.headline).to be_nil
  end
end
