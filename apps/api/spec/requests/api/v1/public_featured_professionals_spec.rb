# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Featured public professionals", type: :request, openapi: true do
  let!(:category) do
    ServiceCategory.create!(
      name: "Instalações em destaque",
      slug: "instalacoes-destaque",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:service) do
    Service.create!(
      category:,
      name: "Eletricista em destaque",
      slug: "eletricista-destaque",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    )
  end

  it "returns at most three eligible cards by latest approved snapshot with deterministic ties" do
    oldest = create_published_profile("+5547999997201", "Ana Antiga", reviewed_at: 3.days.ago)
    tied_id_first = "10000000-0000-4000-8000-000000000001"
    tied_id_second = "20000000-0000-4000-8000-000000000002"
    tied_review_time = 1.day.ago
    first = create_published_profile(
      "+5547999997202",
      "Beto Primeiro",
      reviewed_at: tied_review_time,
      id: tied_id_first
    )
    second = create_published_profile(
      "+5547999997203",
      "Caio Segundo",
      reviewed_at: tied_review_time,
      id: tied_id_second
    )
    newest = create_published_profile("+5547999997204", "Dora Nova", reviewed_at: 1.hour.ago)
    suspended = create_published_profile("+5547999997205", "Eva Suspensa", reviewed_at: Time.current)
    suspended.user_account.update!(status: "suspended")

    get "/api/v1/public/professionals/featured", headers: {"X-Request-Id" => "featured-200"}

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    professionals = body.dig("data", "professionals")
    expect(professionals.pluck("id")).to eq([newest.id, first.id, second.id])
    expect(professionals.pluck("id")).not_to include(oldest.id, suspended.id)
    expect(professionals.first).to include(
      "public_slug" => "dora-nova",
      "display_name" => "Dora Nova",
      "photo_url" => a_string_including("/api/v1/public/profile-photos/"),
      "primary_service" => include("name" => "Eletricista em destaque"),
      "portfolio_count" => 0,
      "relationship_count" => 0
    )
    expect(response.body).not_to include("whatsapp", "+5547")
    assert_api_conform(status: 200)
  end

  it "returns an empty collection when no profile is public" do
    get "/api/v1/public/professionals/featured", headers: {"X-Request-Id" => "featured-empty"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "professionals")).to eq([])
    assert_api_conform(status: 200)
  end

  it "uses the shared safe error envelope when the query is unavailable" do
    allow(FeaturedPublicProfessionalsQuery).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/public/professionals/featured", headers: {"X-Request-Id" => "featured-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("service_unavailable")
    assert_api_conform(status: 503)
  end

  private

  def create_published_profile(phone, name, reviewed_at:, id: SecureRandom.uuid)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(id:, user_account: account, display_name: name, whatsapp_e164: phone)
    revision = profile.working_revision
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    make_profile_publicly_eligible(profile, revision:, reviewed_at:)
  end
end
