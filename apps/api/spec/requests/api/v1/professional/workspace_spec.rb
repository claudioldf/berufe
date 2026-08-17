# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional workspace identity", type: :request, openapi: true do
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
        "profile" => {
          "id" => profile.id,
          "public_slug" => "ana-souza",
          "profile_status" => "draft",
          "revision_status" => "draft",
          "has_published_revision" => false,
          "photo" => {
            "current" => nil,
            "has_published_photo" => false,
            "latest_upload" => nil
          },
          "portfolio_items" => [],
          "verification" => {"current" => nil},
          "identity" => {
            "display_name" => "Ana Souza",
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
    assert_api_conform(status: 200)
  end

  it "persists normalized identity and social profile data" do
    patch "/api/v1/professional/profile",
      params: {
        identity: {
          display_name: " Ana Souza ",
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
      "whatsapp" => "+5547999996202",
      "instagram" => "https://www.instagram.com/ana.obras/",
      "youtube" => "https://www.youtube.com/@AnaObras"
    )
    expect(profile.reload.whatsapp_e164).to eq("+5547999996202")
    assert_api_conform(status: 200)
  end

  it "rejects invalid profile URLs with field-level errors" do
    patch "/api/v1/professional/profile",
      params: {
        identity: {
          display_name: "Ana Souza",
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
      headline: "Elétrica residencial.",
      bio: "Instalações em Joinville.",
      whatsapp: account.phone_e164,
      instagram: "",
      youtube: ""
    }
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
