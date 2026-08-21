# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional workspace identity", type: :request, openapi: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996201", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "returns the owned draft and defaults WhatsApp to the confirmed account phone" do
    get "/api/v1/professional/workspace", headers: session_headers(request_id: "workspace-show")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "data" => {
        "dashboard" => {
          "local_date" => Time.current
            .in_time_zone(ProfessionalDailyActivity::PRODUCT_TIME_ZONE)
            .to_date
            .iso8601,
          "readiness" => {
            "percentage" => 0,
            "steps" => {
              "identity_contact" => false,
              "service_coverage" => false,
              "reviewable_portfolio" => false,
              "approved_identity" => false
            }
          },
          "recent_quotes" => [],
          "recent_service_jobs" => []
        },
        "pending_relationships" => [],
        "relationships" => [],
        "profile" => {
          "id" => profile.id,
          "public_slug" => "ana-souza",
          "profile_status" => "draft",
          "presentation_type" => "self_service",
          "revision_status" => "draft",
          "revision_rejection_reason" => nil,
          "has_published_revision" => false,
          "is_public" => false,
          "is_search_eligible" => false,
          "publication_blockers" => %w[identity photo services coverage],
          "photo" => {
            "current" => nil,
            "has_published_photo" => false,
            "published_image_url" => nil,
            "latest_upload" => nil
          },
          "portfolio_items" => [],
          "verification" => {"current" => nil},
          "identity" => {
            "display_name" => "Ana Souza",
            "birthdate" => nil,
            "headline" => "",
            "bio" => "",
            "years_experience" => nil,
            "whatsapp" => account.phone_e164,
            "instagram" => nil,
            "youtube" => nil
          },
          "services" => [],
          "coverage" => {"all_joinville" => false, "neighborhoods" => []}
        }
      },
      "request_id" => "workspace-show"
    )
    expect(response.headers["Cache-Control"]).to include("no-store")
    assert_api_conform(status: 200)
  end

  it "uses the São Paulo product date in the dashboard summary" do
    travel_to(Time.zone.parse("2026-08-18 02:30:00 UTC")) do
      get "/api/v1/professional/workspace", headers: session_headers(request_id: "workspace-product-date")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "dashboard", "local_date")).to eq("2026-08-17")
      assert_api_conform(status: 200)
    end
  end

  it "returns inbound pending alerts and active relationships in both directions" do
    older_initiator = create_relationship_initiator("+5547999981201", "Beto Antigo")
    newer_initiator = create_relationship_initiator("+5547999981202", "Caio Novo")
    older = ProfessionalRelationship.create!(
      initiator_professional: older_initiator,
      recipient_professional: profile,
      relationship_type: "recommendation",
      created_at: 2.days.ago
    )
    newer = ProfessionalRelationship.create!(
      initiator_professional: newer_initiator,
      recipient_professional: profile,
      relationship_type: "worked_together",
      context_note: "Atuamos juntos em uma obra.",
      created_at: 1.day.ago
    )
    outbound = ProfessionalRelationship.create!(
      initiator_professional: profile,
      recipient_professional: newer_initiator,
      relationship_type: "recommendation"
    )
    declined = ProfessionalRelationship.create!(
      initiator_professional: older_initiator,
      recipient_professional: profile,
      relationship_type: "worked_together",
      status: "declined",
      responded_at: Time.current
    )
    accepted = ProfessionalRelationship.create!(
      initiator_professional: profile,
      recipient_professional: older_initiator,
      relationship_type: "worked_together",
      status: "accepted",
      responded_at: Time.current
    )
    removed = ProfessionalRelationship.create!(
      initiator_professional: newer_initiator,
      recipient_professional: profile,
      relationship_type: "recommendation",
      deleted_at: Time.current
    )

    get "/api/v1/professional/workspace", headers: session_headers(request_id: "workspace-relationships")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "pending_relationships").pluck("id")).to eq(
      [older.id, newer.id]
    )
    expect(response.parsed_body.dig("data", "pending_relationships", 1)).to include(
      "relationship_type" => "worked_together",
      "context_note" => "Atuamos juntos em uma obra.",
      "initiator" => hash_including("display_name" => "Caio Novo")
    )
    expect(response.parsed_body.dig("data", "relationships").pluck("id")).to contain_exactly(
      older.id, newer.id, outbound.id, accepted.id
    )
    expect(response.parsed_body.dig("data", "relationships").pluck("id")).not_to include(
      declined.id, removed.id
    )
    other_party = response.parsed_body.dig("data", "relationships").find do |relationship|
      relationship["id"] == outbound.id
    end.fetch("recipient")
    expect(other_party).to include(
      "display_name" => "Caio Novo",
      "photo_url" => nil,
      "profile_available" => false
    )
    assert_api_conform(status: 200)
  end

  it "persists active services, one primary, specialization notes, and Joinville coverage" do
    category = ServiceCategory.create!(
      name: "Instalações Workspace",
      slug: "instalacoes-workspace",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    service = Service.create!(
      category:,
      name: "Eletricista Workspace",
      slug: "eletricista-workspace",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    )
    neighborhood = Neighborhood.create!(
      code: "america-workspace",
      state_code: "SC",
      city_code: "Joinville",
      name: "América Workspace",
      is_active: true,
      sort_order: 0
    )

    patch "/api/v1/professional/profile",
      params: {
        services: [{service_id: service.id, is_primary: true, note: "Quadros elétricos"}],
        coverage: {all_joinville: false, neighborhood_codes: [neighborhood.code]}
      },
      headers: session_headers(request_id: "workspace-supply", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile", "services")).to eq(
      [{"id" => service.id, "name" => service.name, "is_primary" => true, "note" => "Quadros elétricos"}]
    )
    expect(response.parsed_body.dig("data", "profile", "coverage")).to eq(
      "all_joinville" => false,
      "neighborhoods" => [{"code" => neighborhood.code, "name" => neighborhood.name}]
    )
    expect(ProfessionalDailyActivity.sole).to have_attributes(
      professional: profile,
      profile_updates: 1
    )
    assert_api_conform(status: 200)
  end

  it "persists normalized identity and social profile data" do
    patch "/api/v1/professional/profile",
      params: {
        identity: {
          display_name: " Ana Souza ",
          birthdate: "1990-04-12",
          headline: "Elétrica residencial com cuidado.",
          bio: "Instalações e manutenção em Joinville.",
          years_experience: 12,
          whatsapp: "(47) 99999-6202",
          instagram: "@ana.obras",
          youtube: "youtube.com/@AnaObras?view_as=subscriber"
        }
      },
      headers: session_headers(request_id: "workspace-update", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "profile", "identity")).to include(
      "display_name" => "Ana Souza",
      "birthdate" => "1990-04-12",
      "whatsapp" => "+5547999996202",
      "instagram" => "https://www.instagram.com/ana.obras/",
      "youtube" => "https://www.youtube.com/@AnaObras"
    )
    expect(profile.reload.whatsapp_e164).to eq("+5547999996202")
    expect(ProfessionalDailyActivity.sole.profile_updates).to eq(1)
    assert_api_conform(status: 200)

    patch "/api/v1/professional/profile",
      params: {
        identity: {
          display_name: "Ana Souza",
          birthdate: "1990-04-12",
          headline: "Elétrica residencial com cuidado.",
          bio: "Instalações e manutenção em Joinville.",
          years_experience: 12,
          whatsapp: "+5547999996202",
          instagram: "@ana.obras",
          youtube: "youtube.com/@AnaObras"
        }
      },
      headers: session_headers(request_id: "workspace-no-material-update", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(ProfessionalDailyActivity.sole.profile_updates).to eq(1)
    assert_api_conform(status: 200)
  end

  it "rejects invalid profile URLs with field-level errors" do
    patch "/api/v1/professional/profile",
      params: {
        identity: {
          display_name: "Ana Souza",
          birthdate: "1990-04-12",
          headline: "Elétrica residencial.",
          bio: "Instalações em Joinville.",
          whatsapp: account.phone_e164,
          instagram: "instagram.com/reel/unsafe",
          youtube: ""
        }
      },
      headers: session_headers(request_id: "workspace-invalid", origin: true),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "instagram")).to be_present
    expect(profile.reload.instagram_url).to be_nil
    assert_api_conform(status: 422)
  end

  it "denies anonymous, invalid-origin, and unregistered access" do
    get "/api/v1/professional/workspace", headers: {"X-Request-Id" => "workspace-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/profile",
      params: {identity: valid_identity},
      headers: {"X-Request-Id" => "workspace-patch-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/profile",
      params: {identity: valid_identity},
      headers: session_headers(request_id: "workspace-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    unregistered = UserAccount.create!(phone_e164: "+5547999996203", role: "professional", status: "active")
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    get "/api/v1/professional/workspace",
      headers: session_headers(request_id: "workspace-missing", token: unregistered_token)
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    patch "/api/v1/professional/profile",
      params: {identity: valid_identity},
      headers: session_headers(request_id: "workspace-patch-missing", origin: true, token: unregistered_token),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def valid_identity
    {
      display_name: "Ana Souza",
      birthdate: "1990-04-12",
      headline: "Elétrica residencial.",
      bio: "Instalações em Joinville.",
      whatsapp: account.phone_e164,
      instagram: "",
      youtube: ""
    }
  end

  def create_relationship_initiator(phone, display_name)
    initiator_account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: initiator_account, display_name:)
  end

  def session_headers(request_id:, origin: false, token: session_token)
    headers = {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{token}"
    }
    headers["Origin"] = (origin == true) ? ENV.fetch("WEB_ORIGIN") : origin if origin
    headers
  end
end
