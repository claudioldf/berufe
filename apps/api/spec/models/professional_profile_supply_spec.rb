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
      professional_profile_revision: profile.working_revision,
      service:,
      is_primary: true,
      note: "  Quadros   e circuitos  "
    )

    expect(described_service.note).to eq("Quadros e circuitos")
    expect do
      ProfessionalProfileService.create!(
        professional_profile_revision: profile.working_revision,
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
        professional_profile_revision: profile.working_revision,
        service: second,
        is_primary: true
      )
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "prevents duplicate neighborhood coverage through PostgreSQL indexes" do
    neighborhood = create_location_neighborhood(code: "4209102003", name: "América Supply")
    revision = profile.working_revision
    revision.update!(coverage_city: joinville_city, covers_whole_city: false)

    ProfessionalProfileServiceArea.create!(
      professional_profile_revision: revision,
      neighborhood:
    )
    expect do
      ProfessionalProfileServiceArea.create!(
        professional_profile_revision: revision,
        neighborhood:
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end
end
