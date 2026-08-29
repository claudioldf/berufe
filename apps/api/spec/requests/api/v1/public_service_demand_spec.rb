# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public service demand", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Demanda pública API",
      slug: "demanda-publica-api",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) do
    Service.create!(
      category:,
      name: "Eletricista demandado API",
      slug: "eletricista-demandado-api",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  it "omits the count below the privacy threshold and includes it once released" do
    3.times do
      SearchEvent.create!(
        service: electrician,
        city: joinville_city,
        result_count: 1,
        profile_opened: false,
        whatsapp_handoff_occurred: false,
        created_at: 1.day.ago,
        updated_at: 1.day.ago
      )
    end

    get "/api/v1/public/service-demand",
      params: {service_slug: electrician.slug, state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "demand-released"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq({"released" => true, "searches" => 3})
    assert_api_conform(status: 200)
  end

  it "returns released false and a null count without any published searches" do
    get "/api/v1/public/service-demand",
      params: {service_slug: electrician.slug, state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "demand-not-released"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to eq({"released" => false, "searches" => nil})
    assert_api_conform(status: 200)
  end

  it "returns 404 for an unknown service slug or an unsupported city route" do
    get "/api/v1/public/service-demand",
      params: {service_slug: "servico-inexistente", state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "demand-unknown-service"}
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    get "/api/v1/public/service-demand",
      params: {service_slug: electrician.slug, state_slug: "zz", city_slug: "cidade-inexistente"},
      headers: {"X-Request-Id" => "demand-unknown-city"}
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "uses the shared safe error envelope when the query is unavailable" do
    allow(PublicServiceDemand).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/public/service-demand",
      params: {service_slug: electrician.slug, state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "demand-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end
end
