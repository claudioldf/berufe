# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfessionalSearch do
  let!(:category) do
    ServiceCategory.create!(
      name: "Busca pública",
      slug: "busca-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) { create_service("Eletricista busca", "busca-eletricista", ["elétrica"], 0) }
  let!(:plumber) { create_service("Encanador busca", "busca-encanador", ["hidráulica"], 1) }
  let!(:america) do
    Neighborhood.create!(
      code: "america-busca",
      name: "América Busca",
      state_code: "SC",
      city_code: "Joinville",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:centro) do
    Neighborhood.create!(
      code: "centro-busca",
      name: "Centro Busca",
      state_code: "SC",
      city_code: "Joinville",
      is_active: true,
      sort_order: 1
    )
  end

  it "returns only eligible profiles offering the resolved service in the selected coverage" do
    all_city = create_published_profile("+5547999997401", "Ana Toda Cidade", services: [electrician], all_city: true)
    exact_area = create_published_profile(
      "+5547999997402",
      "Beto América",
      services: [plumber, electrician],
      neighborhoods: [america]
    )
    create_published_profile(
      "+5547999997403",
      "Caio Centro",
      services: [electrician],
      neighborhoods: [centro]
    )
    suspended = create_published_profile(
      "+5547999997404",
      "Dora Suspensa",
      services: [electrician],
      all_city: true
    )
    suspended.user_account.update!(status: "suspended")
    create_draft_profile("+5547999997405", "Eva Rascunho", electrician)

    result = described_class.new.call(term: "ELÉTRICA", neighborhood_code: america.code)

    expect(result.service).to eq(electrician)
    expect(result.neighborhood).to eq(america)
    expect(result.professionals).to contain_exactly(all_city, exact_area)
  end

  it "requires a resolved service before returning professionals and treats all Joinville as no area filter" do
    profile = create_published_profile(
      "+5547999997406",
      "Fábio Específico",
      services: [electrician],
      neighborhoods: [centro]
    )

    all_city_result = described_class.new.call(term: electrician.slug, neighborhood_code: "all")
    expect(all_city_result.professionals).to contain_exactly(profile)
    expect(all_city_result.neighborhood).to be_nil

    unmatched = described_class.new.call(term: "dedetização", neighborhood_code: nil)
    expect(unmatched.service).to be_nil
    expect(unmatched.professionals).to be_empty
    expect(unmatched.related_services.length).to be_between(1, 3)
  end

  it "rejects blank, oversized, non-text, and inactive neighborhood input" do
    inactive = Neighborhood.create!(
      code: "inativo-busca",
      name: "Inativo Busca",
      state_code: "SC",
      city_code: "Joinville",
      is_active: false,
      sort_order: 2
    )

    expect { described_class.new.call(term: "!!!") }
      .to raise_error(described_class::InvalidInput) { |error| expect(error.field_errors).to have_key(:service) }
    expect { described_class.new.call(term: "x" * 81) }
      .to raise_error(described_class::InvalidInput)
    expect { described_class.new.call(term: 123) }
      .to raise_error(described_class::InvalidInput)
    expect { described_class.new.call(term: electrician.slug, neighborhood_code: inactive.code) }
      .to raise_error(described_class::InvalidInput) do |error|
        expect(error.field_errors).to have_key(:neighborhoodCode)
      end
  end

  it "keeps service and neighborhood lookups backed by their search indexes" do
    connection = ActiveRecord::Base.connection

    expect(
      connection.index_exists?(
        :professional_profile_services,
        %i[service_id professional_profile_revision_id],
        name: "idx_revision_services_service_revision"
      )
    ).to be(true)
    expect(
      connection.index_exists?(
        :professional_profile_service_areas,
        %i[neighborhood_code professional_profile_revision_id],
        name: "idx_revision_service_areas_neighborhood_revision"
      )
    ).to be(true)
  end

  private

  def create_service(name, slug, aliases, order)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-zap",
      description: "Serviço residencial para busca.",
      aliases:,
      is_active: true,
      sort_order: order
    )
  end

  def create_published_profile(phone, name, services:, all_city: false, neighborhoods: [])
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name, whatsapp_e164: phone)
    revision = profile.working_revision
    services.each_with_index do |service, index|
      revision.professional_profile_services.create!(service:, is_primary: index.zero?)
    end
    if all_city
      revision.professional_profile_service_areas.create!(city_code: "Joinville")
    else
      neighborhoods.each do |neighborhood|
        revision.professional_profile_service_areas.create!(city_code: "Joinville", neighborhood:)
      end
    end
    revision.update!(status: "approved", reviewed_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision)
    profile
  end

  def create_draft_profile(phone, name, service)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name)
    profile.working_revision.professional_profile_services.create!(service:, is_primary: true)
    profile
  end
end
