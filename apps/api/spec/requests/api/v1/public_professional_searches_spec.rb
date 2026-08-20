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
      params: {service: "ELÉTRICA CONTRATADA!", neighborhood_code: neighborhood.code},
      headers: request_headers("search-200"),
      as: :json

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.dig("query", "normalized_term")).to eq("eletrica contratada")
    expect(data.dig("query", "service", "id")).to eq(electrician.id)
    expect(data.dig("query", "neighborhood", "code")).to eq(neighborhood.code)
    expect(data.fetch("professionals").sole).to include(
      "id" => profile.id,
      "matching_service" => include("id" => electrician.id),
      "verification_labels" => include(include("type" => "phone", "label" => "Telefone confirmado"))
    )
    event = SearchEvent.find(data.dig("interaction", "search_event_id"))
    expect(event).to have_attributes(
      service_id: electrician.id,
      query_text_normalized: "eletrica contratada",
      city_code: "Joinville",
      neighborhood_code: neighborhood.code,
      result_count: 1,
      profile_opened: false,
      whatsapp_handoff_occurred: false
    )
    expect(PublicInteractionToken.new.verify(data.dig("interaction", "token"))).to have_attributes(
      search_event_id: event.id,
      service_id: electrician.id
    )
    expect(response.headers["Cache-Control"].to_s).not_to include("no-store")
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
      params: {service: "dedetização", neighborhood_code: nil},
      headers: request_headers("search-unmatched"),
      as: :json

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.dig("query", "service")).to be_nil
    expect(data.fetch("professionals")).to eq([])
    expect(data.fetch("related_services").pluck("id")).not_to include(inactive.id)
    expect(SearchEvent.find(data.dig("interaction", "search_event_id"))).to have_attributes(
      service_id: nil,
      query_text_normalized: "dedetizacao",
      result_count: 0
    )
    assert_api_conform(status: 200)
  end

  it "does not retain sensitive search text" do
    post "/api/v1/public/professional-searches",
      params: {service: "ana@example.com"},
      headers: request_headers("search-sensitive"),
      as: :json

    expect(response).to have_http_status(:ok)
    event = SearchEvent.find(response.parsed_body.dig("data", "interaction", "search_event_id"))
    expect(event.query_text_normalized).to be_nil
    expect(event.service_id).to be_nil
    expect(response.body).not_to include("ana@example.com")
    assert_api_conform(status: 200)
  end

  it "returns cards in the deterministic evidence order" do
    all_city = create_published_profile(
      phone: "+5547999997502",
      name: "Beto Toda Cidade",
      all_city: true,
      reviewed_at: 1.day.ago
    )
    exact_area = create_published_profile(
      phone: "+5547999997503",
      name: "Ana Área Exata",
      reviewed_at: 30.days.ago
    )

    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug, neighborhood_code: neighborhood.code},
      headers: request_headers("search-ranking"),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "professionals").pluck("id")).to eq([
      exact_area.id,
      all_city.id
    ])
    assert_api_conform(status: 200)
  end

  it "returns customer results when event persistence fails" do
    create_published_profile
    allow(SearchEvent).to receive(:create!).and_raise(ActiveRecord::ConnectionNotEstablished)
    allow(Rails.logger).to receive(:error)

    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug, neighborhood_code: neighborhood.code},
      headers: request_headers("search-event-failed"),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "professionals").size).to eq(1)
    expect(response.parsed_body.dig("data", "interaction")).to be_nil
    expect(Rails.logger).to have_received(:error).with(
      "public_search_event_recording_failed class=ActiveRecord::ConnectionNotEstablished request_id=search-event-failed"
    )
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
      params: {service: electrician.slug, neighborhood_code: inactive.code},
      headers: request_headers("search-422"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "neighborhood_code")).to be_present
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

  it "returns one bounded page while the search event records every match" do
    25.times do |index|
      create_published_profile(
        phone: format("+554799999%04d", 7600 + index),
        name: "Profissional Paginado #{index}"
      )
    end

    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug, neighborhood_code: neighborhood.code},
      headers: request_headers("search-page-1"),
      as: :json

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.fetch("professionals").length).to eq(20)
    expect(data.fetch("meta")).to eq(
      "page" => 1,
      "per_page" => 20,
      "total_count" => 25,
      "total_pages" => 2
    )
    expect(SearchEvent.find(data.dig("interaction", "search_event_id")).result_count).to eq(25)
    assert_api_conform(status: 200)

    first_page_ids = data.fetch("professionals").pluck("id")
    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug, neighborhood_code: neighborhood.code, page: 2},
      headers: request_headers("search-page-2"),
      as: :json

    expect(response).to have_http_status(:ok)
    second_page = response.parsed_body.fetch("data")
    expect(second_page.fetch("professionals").length).to eq(5)
    expect(second_page.fetch("professionals").pluck("id")).not_to include(*first_page_ids)
    expect(second_page.dig("meta", "page")).to eq(2)
    assert_api_conform(status: 200)

    # The contract already rejects these bounds, so this only proves Rails does
    # not depend on that and refuses them itself.
    post "/api/v1/public/professional-searches",
      params: {service: electrician.slug, page: 0, per_page: 51},
      headers: request_headers("search-page-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors").keys).to contain_exactly("page", "per_page")
  end

  private

  def request_headers(request_id)
    {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id}
  end

  def create_published_profile(
    phone: "+5547999997501",
    name: "Ana Contratada",
    all_city: false,
    reviewed_at: Time.current
  )
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(
      user_account: account,
      display_name: name,
      headline: "Elétrica residencial segura.",
      whatsapp_e164: account.phone_e164
    )
    revision = profile.working_revision
    revision.professional_profile_services.create!(service: electrician, is_primary: true)
    revision.professional_profile_service_areas.create!(
      city_code: "Joinville",
      neighborhood: (neighborhood unless all_city)
    )
    make_profile_publicly_eligible(profile, revision:, reviewed_at:)
  end
end
