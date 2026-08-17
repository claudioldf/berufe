# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public professional searches", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Busca contratada",
      slug: "busca-contratada",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) do
    Service.create!(
      category:,
      name: "Eletricista contratado",
      slug: "eletricista-contratado",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: ["elétrica contratada"],
      is_active: true,
      sort_order: 0
    )
  end
  let!(:neighborhood) do
    Neighborhood.create!(
      code: "america-contratada",
      name: "América Contratada",
      state_code: "SC",
      city_code: "Joinville",
      is_active: true,
      sort_order: 0
    )
  end

  it "returns a safe matching card for an exact normalized alias and active neighborhood" do
    profile = create_published_profile

    post "/api/v1/public/professional-searches",
      params: {service: "ELÉTRICA CONTRATADA!", neighborhoodCode: neighborhood.code},
      headers: request_headers("search-200"),
      as: :json

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.dig("query", "normalizedTerm")).to eq("eletrica contratada")
    expect(data.dig("query", "service", "id")).to eq(electrician.id)
    expect(data.dig("query", "neighborhood", "code")).to eq(neighborhood.code)
    expect(data.fetch("professionals").sole).to include(
      "id" => profile.id,
      "matchingService" => include("id" => electrician.id),
      "verificationLabels" => include(include("type" => "phone", "label" => "Telefone confirmado"))
    )
    expect(response.body).not_to include("whatsapp", "+5547")
    assert_api_conform(status: 200)
  end

  it "returns no profiles and no inactive suggestion for an unmatched service" do
    inactive = Service.create!(
      category:,
      name: "Dedetizador inativo",
      slug: "dedetizador-inativo",
      icon: "i-lucide-scan-search",
      description: "Serviço fora da oferta ativa.",
      aliases: ["dedetização"],
      is_active: false,
      sort_order: 1
    )

    post "/api/v1/public/professional-searches",
      params: {service: "dedetização", neighborhoodCode: nil},
      headers: request_headers("search-unmatched"),
      as: :json

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.dig("query", "service")).to be_nil
    expect(data.fetch("professionals")).to eq([])
    expect(data.fetch("relatedServices").pluck("id")).not_to include(inactive.id)
    assert_api_conform(status: 200)
  end

  it "rejects an inactive neighborhood and a missing exact browser origin" do
    inactive = Neighborhood.create!(
      code: "bairro-inativo-contratado",
      name: "Bairro Inativo Contratado",
      state_code: "SC",
      city_code: "Joinville",
      is_active: false,
      sort_order: 1
    )
    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug, neighborhoodCode: inactive.code},
      headers: request_headers("search-422"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "neighborhoodCode")).to be_present
    assert_api_conform(status: 422)

    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug},
      headers: {"X-Request-Id" => "search-403"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  it "returns validation and availability errors through the shared envelope" do
    post "/api/v1/public/professional-searches",
      params: {service: "!!!"},
      headers: request_headers("search-empty"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "service")).to be_present
    assert_api_conform(status: 422)

    allow(PublicProfessionalSearch).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)
    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug},
      headers: request_headers("search-503"),
      as: :json
    expect(response).to have_http_status(:service_unavailable)
    assert_api_conform(status: 503)
  end

  private

  def request_headers(request_id)
    {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id}
  end

  def create_published_profile
    account = UserAccount.create!(phone_e164: "+5547999997501", role: "professional", status: "active")
    profile = ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Contratada",
      headline: "Elétrica residencial segura.",
      whatsapp_e164: account.phone_e164
    )
    revision = profile.working_revision
    revision.professional_profile_services.create!(service: electrician, is_primary: true)
    revision.professional_profile_service_areas.create!(city_code: "Joinville", neighborhood:)
    revision.update!(status: "approved", reviewed_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision)
    profile
  end
end
