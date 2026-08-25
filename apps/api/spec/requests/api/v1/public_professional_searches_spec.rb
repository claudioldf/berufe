# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public professional searches", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Busca por expressão",
      slug: "busca-por-expressao",
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
  let(:criteria) do
    LlmSearchParser::Criteria.new(
      service_ids: [electrician.id],
      locations: [
        LlmSearchParser::Location.new(
          state_code: "SC",
          city: "Joinville",
          neighborhood_code: neighborhood.code
        )
      ],
      keywords: ["troca chuveiro"],
      normalized_request: "Eu preciso trocar meu chuveiro no América."
    )
  end

  before do
    allow_any_instance_of(LlmSearchParser).to receive(:call).and_return(criteria)
  end

  it "returns matching cards without echoing or retaining the raw expression" do
    profile = create_published_profile
    expression = "Preciso trocar meu chuveiro no bairro América Contratada"

    post "/api/v1/public/professional-searches",
      params: {expression:},
      headers: request_headers("expression-search-200"),
      as: :json

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.fetch("professionals").sole).to include(
      "id" => profile.id,
      "matching_service" => include("id" => electrician.id)
    )
    expect(data.keys).to contain_exactly(
      "professionals",
      "related_services",
      "meta",
      "interpretation",
      "interaction"
    )
    expect(data.fetch("interpretation")).to eq(
      "services" => [
        {
          "id" => electrician.id,
          "name" => electrician.name,
          "slug" => electrician.slug,
          "icon" => electrician.icon,
          "description" => electrician.description
        }
      ],
      "locations" => [
        {
          "state_code" => "SC",
          "city" => "Joinville",
          "neighborhood" => {"code" => neighborhood.code, "name" => neighborhood.name}
        }
      ],
      "normalized_request" => "Eu preciso trocar meu chuveiro no América."
    )
    expect(data.fetch("related_services")).not_to include(include("id" => electrician.id))
    expect(data.fetch("related_services").length).to be <= 3
    expect(response.body).not_to include(expression)

    event = SearchEvent.find(data.dig("interaction", "search_event_id"))
    expect(event).to have_attributes(
      service_id: electrician.id,
      neighborhood_code: neighborhood.code,
      query_text_normalized: nil,
      result_count: 1
    )
    expect(PublicInteractionToken.new.verify(data.dig("interaction", "token"))).to have_attributes(
      search_event_id: event.id,
      service_ids: [electrician.id]
    )
    assert_api_conform(status: 200)
  end

  it "searches by controlled service and city without invoking the LLM or expression limiter" do
    profile = create_published_profile
    expect_any_instance_of(LlmSearchParser).not_to receive(:call)
    expect_any_instance_of(PublicSearchRateLimiter).not_to receive(:check_and_increment!)

    post "/api/v1/public/professional-searches",
      params: {service_id: electrician.id, state_code: "SC", city: "Joinville"},
      headers: request_headers("structured-search-200"),
      as: :json

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.fetch("professionals").sole).to include("id" => profile.id)
    expect(data.fetch("interpretation")).to include(
      "services" => [include("id" => electrician.id)],
      "locations" => [
        {
          "state_code" => "SC",
          "city" => "Joinville",
          "neighborhood" => nil
        }
      ],
      "normalized_request" => nil
    )
    assert_api_conform(status: 200)
  end

  it "returns validation, rate-limit, and provider failures through the shared envelope" do
    post "/api/v1/public/professional-searches",
      params: {},
      headers: request_headers("expression-missing"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "expression")).to be_present

    allow_any_instance_of(LlmSearchParser).to receive(:call)
      .and_raise(LlmSearchParser::LocationUnsupported)
    post "/api/v1/public/professional-searches",
      params: {expression: "Eletricista em Curitiba"},
      headers: request_headers("expression-location-unsupported"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "expression")).to be_present
    assert_api_conform(status: 422)

    allow_any_instance_of(PublicSearchRateLimiter).to receive(:check_and_increment!)
      .and_raise(PublicSearchRateLimiter::RateLimited.new(retry_after: 42))
    post "/api/v1/public/professional-searches",
      params: {expression: "Eletricista"},
      headers: request_headers("expression-rate-limited"),
      as: :json
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("42")
    assert_api_conform(status: 429)

    allow_any_instance_of(PublicSearchRateLimiter).to receive(:check_and_increment!).and_return(nil)
    allow_any_instance_of(LlmSearchParser).to receive(:call)
      .and_raise(LlmSearchParser::ProviderRateLimited.new(retry_after: 37))
    post "/api/v1/public/professional-searches",
      params: {expression: "Eletricista"},
      headers: request_headers("expression-provider-rate-limited"),
      as: :json
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("37")
    expect(response.parsed_body.dig("error", "code")).to eq("public_search_rate_limited")
    assert_api_conform(status: 429)

    allow_any_instance_of(LlmSearchParser).to receive(:call)
      .and_raise(LlmSearchParser::ProviderUnavailable)
    post "/api/v1/public/professional-searches",
      params: {expression: "Eletricista"},
      headers: request_headers("expression-provider-failed"),
      as: :json
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("llm_search_unavailable")
    assert_api_conform(status: 503)
  end

  it "requires the exact browser origin" do
    post "/api/v1/public/professional-searches",
      params: {expression: "Eletricista em Joinville"},
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "expression-origin-403"},
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
    assert_api_conform(status: 403)
  end

  it "paginates the parsed query while recording the full result count" do
    21.times do |index|
      create_published_profile(
        phone: format("+554799998%04d", 7000 + index),
        name: "Profissional Expressão #{index}"
      )
    end

    post "/api/v1/public/professional-searches",
      params: {expression: "Eletricista no América"},
      headers: request_headers("expression-page-1"),
      as: :json

    data = response.parsed_body.fetch("data")
    expect(data.fetch("professionals").length).to eq(20)
    expect(data.fetch("meta")).to eq(
      "page" => 1,
      "per_page" => 20,
      "total_count" => 21,
      "total_pages" => 2
    )
    expect(SearchEvent.find(data.dig("interaction", "search_event_id")).result_count).to eq(21)
    assert_api_conform(status: 200)

    post "/api/v1/public/professional-searches",
      params: {expression: "Eletricista no América", page: 2},
      headers: request_headers("expression-page-2"),
      as: :json
    expect(response.parsed_body.dig("data", "professionals").length).to eq(1)
    assert_api_conform(status: 200)
  end

  private

  def request_headers(request_id)
    {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id}
  end

  def create_published_profile(
    phone: "+5547999997501",
    name: "Ana Contratada"
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
    revision.professional_profile_service_areas.create!(city_code: "Joinville", neighborhood:)
    make_profile_publicly_eligible(profile, revision:)
  end
end
