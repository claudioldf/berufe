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
        birthdate: "1990-04-12",
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
    expect(result.birthdate).to eq(Date.new(1990, 4, 12))
  end

  it "returns actionable field errors without partially updating" do
    expect do
      described_class.new.call(
        profile:,
        attributes: {
          display_name: "A",
          birthdate: "not-a-date",
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

  it "expires identity verification when the private birthdate changes" do
    profile.update!(birthdate: Date.new(1990, 4, 12))
    request_record = profile.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      claimed_birthdate: Date.new(1990, 4, 12),
      identity_match_confirmed_at: 1.day.ago,
      submitted_at: 2.days.ago,
      reviewed_at: 1.day.ago,
      verified_at: 1.day.ago,
      public_label: ModerationDecision::IDENTITY_LABEL
    )

    described_class.new.call(
      profile:,
      attributes: {
        display_name: "Ana Souza",
        birthdate: "1991-05-13",
        headline: "",
        bio: "",
        years_experience: nil,
        whatsapp: "",
        instagram: "",
        youtube: ""
      }
    )

    expect(request_record.reload).to have_attributes(
      status: "expired",
      public_label: nil,
      verified_at: nil,
      identity_match_confirmed_at: nil
    )
    expect(request_record.expired_at).to be_present
  end

  it "accepts biographies up to 2,500 characters and rejects longer content" do
    attributes = {
      display_name: "Ana Souza",
      birthdate: "1990-04-12",
      headline: "",
      bio: "B" * 2500,
      years_experience: nil,
      whatsapp: "",
      instagram: "",
      youtube: ""
    }

    result = described_class.new.call(profile:, attributes:)

    expect(result.working_revision.bio.length).to eq(2500)
    expect do
      described_class.new.call(profile:, attributes: attributes.merge(bio: "B" * 2501))
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:bio]).to include("deve ter entre 1 e 2500 caracteres")
    }
  end
end
