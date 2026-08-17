# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional profile supply", type: :model do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996301", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:category) do
    ServiceCategory.create!(
      name: "Instalações",
      slug: "instalacoes-supply",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let(:service) do
    Service.create!(
      category:,
      name: "Eletricista",
      slug: "eletricista-supply",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    )
  end

  it "normalizes specialization notes and prevents duplicate services or primary rows" do
    described_service = ProfessionalProfileService.create!(
      professional_profile: profile,
      service:,
      is_primary: true,
      note: "  Quadros   e circuitos  "
    )

    expect(described_service.note).to eq("Quadros e circuitos")
    expect do
      ProfessionalProfileService.create!(
        professional_profile: profile,
        service:,
        is_primary: false
      )
    end.to raise_error(ActiveRecord::RecordInvalid)

    second = Service.create!(
      category:,
      name: "Instalador",
      slug: "instalador-supply",
      icon: "i-lucide-wrench",
      description: "Instalações residenciais.",
      aliases: ["instalação"],
      is_active: true,
      sort_order: 1
    )
    expect do
      ProfessionalProfileService.create!(
        professional_profile: profile,
        service: second,
        is_primary: true
      )
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "prevents duplicate all-city and neighborhood coverage through PostgreSQL indexes" do
    Neighborhood.create!(
      code: "america-supply",
      state_code: "SC",
      city_code: "Joinville",
      name: "América Supply",
      is_active: true,
      sort_order: 0
    )
    ProfessionalProfileServiceArea.create!(professional_profile: profile, city_code: "Joinville")

    expect do
      ProfessionalProfileServiceArea.create!(professional_profile: profile, city_code: "Joinville")
    end.to raise_error(ActiveRecord::RecordNotUnique)

    ProfessionalProfileServiceArea.create!(
      professional_profile: profile,
      city_code: "Joinville",
      neighborhood_code: "america-supply"
    )
    expect do
      ProfessionalProfileServiceArea.create!(
        professional_profile: profile,
        city_code: "Joinville",
        neighborhood_code: "america-supply"
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end
end
