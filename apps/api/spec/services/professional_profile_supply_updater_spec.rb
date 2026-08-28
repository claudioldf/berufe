# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfileSupplyUpdater do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996401", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:category) do
    ServiceCategory.create!(
      name: "Reparos Supply",
      slug: "reparos-supply-updater",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let(:service) do
    Service.create!(
      category:,
      name: "Eletricista Supply",
      slug: "eletricista-supply-updater",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    )
  end
  let!(:neighborhood) do
    create_location_neighborhood(code: "4209102002", name: "América Supply Updater")
  end

  it "atomically replaces active services and specific Joinville coverage" do
    described_class.new.call(
      profile:,
      services: [{service_id: service.id, is_primary: true, note: "  Quadros  elétricos "}],
      coverage: {city_code: joinville_city.code, whole_city: false, neighborhood_codes: [neighborhood.code]}
    )

    selection = profile.working_revision.professional_profile_services.includes(:service).sole
    expect(selection.service).to eq(service)
    expect(selection).to be_is_primary
    expect(selection.note).to eq("Quadros elétricos")
    expect(profile.working_revision.professional_profile_service_areas.sole.neighborhood).to eq(neighborhood)
  end

  it "represents whole-city coverage on the revision without an area row" do
    described_class.new.call(
      profile:,
      services: [{service_id: service.id, is_primary: true, note: nil}],
      coverage: {city_code: joinville_city.code, whole_city: true, neighborhood_codes: []}
    )

    expect(profile.working_revision).to have_attributes(
      coverage_city_code: joinville_city.code,
      covers_whole_city: true
    )
    expect(profile.working_revision.professional_profile_service_areas).to be_empty
  end

  it "rejects contradictory, inactive, duplicate, and primary-less selections without partial replacement" do
    invalid_inputs = [
      {
        services: [{service_id: service.id, is_primary: false}],
        coverage: {city_code: joinville_city.code, whole_city: true, neighborhood_codes: []}
      },
      {
        services: [{service_id: service.id, is_primary: true}],
        coverage: {city_code: joinville_city.code, whole_city: true, neighborhood_codes: [neighborhood.code]}
      },
      {
        services: [
          {service_id: service.id, is_primary: true},
          {service_id: service.id, is_primary: false}
        ],
        coverage: {city_code: joinville_city.code, whole_city: false, neighborhood_codes: [neighborhood.code]}
      }
    ]

    invalid_inputs.each do |input|
      expect do
        described_class.new.call(profile:, **input)
      end.to raise_error(described_class::Invalid)
    end
    expect(profile.working_revision.professional_profile_services).to be_empty
  end
end
