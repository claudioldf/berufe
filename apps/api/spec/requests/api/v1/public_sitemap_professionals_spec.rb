# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public sitemap professionals", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Sitemap pública",
      slug: "sitemap-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:service) do
    Service.create!(
      category:,
      name: "Eletricista sitemap",
      slug: "eletricista-sitemap",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  it "lists only professionals whose canonical profiles are indexable" do
    indexable = create_published_profile("+5547999996501", "Ana Sitemap")
    thin = create_published_profile("+5547999996502", "Beto Sem Evidência")
    thin.user_account.update_columns(phone_verified_at: nil, registered_at: nil)
    suspended = create_published_profile("+5547999996503", "Caio Suspenso")
    suspended.user_account.update!(status: "suspended")
    account = UserAccount.create!(phone_e164: "+5547999996504", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Dora Rascunho")

    get "/api/v1/public/sitemap-professionals", headers: {"X-Request-Id" => "sitemap-professionals-200"}

    expect(response).to have_http_status(:ok)
    professionals = response.parsed_body.dig("data", "professionals")
    expect(professionals.pluck("slug")).to eq([indexable.public_slug])
    expect(professionals.first["updated_at"]).to be_present
    assert_api_conform(status: 200)
  end

  it "uses the shared safe error envelope when the query is unavailable" do
    allow(PublicSitemapProfessionalsQuery).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/public/sitemap-professionals", headers: {"X-Request-Id" => "sitemap-professionals-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def create_published_profile(phone, name)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name, whatsapp_e164: phone)
    revision = profile.working_revision
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    make_profile_publicly_eligible(profile, revision:)
  end
end
