# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public service coverage", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Cobertura pública",
      slug: "cobertura-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) do
    Service.create!(
      category:,
      name: "Eletricista coberto",
      slug: "eletricista-coberto",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: ["elétrica coberta"],
      is_active: true,
      sort_order: 0
    )
  end
  let!(:painter) do
    Service.create!(
      category:,
      name: "Pintor coberto",
      slug: "pintor-coberto",
      icon: "i-lucide-paintbrush",
      description: "Pintura residencial.",
      aliases: [],
      is_active: true,
      sort_order: 1
    )
  end

  it "counts professionals per service and city, matching the listing supply threshold" do
    2.times { |index| create_published_profile(service: electrician, phone: "+554799999640#{index}") }
    create_published_profile(service: painter, phone: "+5547999996410")

    get "/api/v1/public/service-coverage", headers: {"X-Request-Id" => "coverage-all"}

    expect(response).to have_http_status(:ok)
    entries = response.parsed_body.dig("data", "entries")
    electrician_entry = entries.find { |entry| entry.dig("service", "slug") == electrician.slug }
    painter_entry = entries.find { |entry| entry.dig("service", "slug") == painter.slug }
    expect(electrician_entry).to include("professional_count" => 2, "indexable" => true)
    expect(electrician_entry.dig("location", "city_slug")).to eq(joinville_city.slug)
    expect(painter_entry).to include("professional_count" => 1, "indexable" => true)
    assert_api_conform(status: 200)
  end

  it "filters by service_slug or by state_slug/city_slug" do
    create_published_profile(service: electrician, phone: "+5547999996420")

    get "/api/v1/public/service-coverage",
      params: {service_slug: electrician.slug},
      headers: {"X-Request-Id" => "coverage-by-service"}
    expect(response.parsed_body.dig("data", "entries").pluck("service").pluck("slug").uniq).to eq([electrician.slug])
    assert_api_conform(status: 200)

    get "/api/v1/public/service-coverage",
      params: {state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "coverage-by-city"}
    cities = response.parsed_body.dig("data", "entries").pluck("location").pluck("city_slug").uniq
    expect(cities).to eq([joinville_city.slug])
    assert_api_conform(status: 200)
  end

  it "returns an empty result for a filter that does not resolve, rather than an error" do
    get "/api/v1/public/service-coverage",
      params: {service_slug: "servico-inexistente"},
      headers: {"X-Request-Id" => "coverage-unknown-service"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "entries")).to eq([])
    assert_api_conform(status: 200)
  end

  it "uses the shared safe error envelope when the query is unavailable" do
    allow(PublicServiceCoverageQuery).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/public/service-coverage", headers: {"X-Request-Id" => "coverage-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def create_published_profile(service:, phone:, name: "Profissional Coberto #{phone}")
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name, whatsapp_e164: phone)
    revision = profile.working_revision
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    make_profile_publicly_eligible(profile, revision:)
  end
end
