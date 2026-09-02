# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public professional listings", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Listagem pública",
      slug: "listagem-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) do
    Service.create!(
      category:,
      name: "Eletricista listado",
      slug: "eletricista-listado",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: ["elétrica listada"],
      is_active: true,
      sort_order: 0
    )
  end

  it "returns cards for a service and city, marked supply-eligible with one public professional" do
    professional = create_published_profile(phone: "+5547999996001", name: "Ana Listada")

    get "/api/v1/public/professional-listings",
      params: {service_slug: electrician.slug, state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "listing-below-threshold"}

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.fetch("professionals").pluck("id")).to contain_exactly(professional.id)
    expect(data.fetch("service")).to include("slug" => electrician.slug)
    expect(data.fetch("location")).to include("city_slug" => joinville_city.slug, "state_slug" => "sc")
    expect(data.fetch("meta")).to include("total_count" => 1)
    expect(data.fetch("indexable")).to eq(true)
    assert_api_conform(status: 200)
  end

  it "is supply-eligible once the service/city combination reaches the supply threshold" do
    create_published_profile(phone: "+5547999996300", name: "Profissional elegível")

    get "/api/v1/public/professional-listings",
      params: {service_slug: electrician.slug, state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "listing-indexable"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "indexable")).to eq(true)
    assert_api_conform(status: 200)
  end

  it "does not record a search event or consume the interactive search rate limit" do
    create_published_profile
    expect_any_instance_of(PublicSearchRateLimiter).not_to receive(:check_and_increment!)

    get "/api/v1/public/professional-listings",
      params: {service_slug: electrician.slug, state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "listing-no-audit"}

    expect(response).to have_http_status(:ok)
    expect(SearchEvent.count).to eq(0)
  end

  it "returns an empty, non-indexable result for a supported city with no supply yet" do
    get "/api/v1/public/professional-listings",
      params: {service_slug: electrician.slug, state_slug: "pr", city_slug: curitiba_city.slug},
      headers: {"X-Request-Id" => "listing-empty-supply"}

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.fetch("professionals")).to eq([])
    expect(data.dig("meta", "total_count")).to eq(0)
    expect(data.fetch("indexable")).to eq(false)
    assert_api_conform(status: 200)
  end

  it "returns 404 for an unknown service slug or an unsupported city route" do
    get "/api/v1/public/professional-listings",
      params: {service_slug: "servico-inexistente", state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "listing-unknown-service"}
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    get "/api/v1/public/professional-listings",
      params: {service_slug: electrician.slug, state_slug: "zz", city_slug: "cidade-inexistente"},
      headers: {"X-Request-Id" => "listing-unknown-city"}
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "uses the shared safe error envelope when the query is unavailable" do
    allow(PublicProfessionalSearch).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/public/professional-listings",
      params: {service_slug: electrician.slug, state_slug: "sc", city_slug: joinville_city.slug},
      headers: {"X-Request-Id" => "listing-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def create_published_profile(phone: "+5547999996000", name: "Profissional Listado")
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name, whatsapp_e164: phone)
    revision = profile.working_revision
    revision.professional_profile_services.create!(service: electrician, is_primary: true)
    revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    make_profile_publicly_eligible(profile, revision:)
  end
end
