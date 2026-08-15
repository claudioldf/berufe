# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public catalog", type: :request, openapi: true do
  it "returns only active entries in configured order with approved mockup metadata" do
    installations = ServiceCategory.create!(
      name: "Instalações",
      slug: "instalacoes",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 1
    )
    finishes = ServiceCategory.create!(
      name: "Acabamentos",
      slug: "acabamentos",
      icon: "i-lucide-paint-roller",
      is_active: true,
      sort_order: 0
    )
    hidden_category = ServiceCategory.create!(
      name: "Oculta",
      slug: "oculta",
      icon: "i-lucide-eye-off",
      is_active: false,
      sort_order: 2
    )
    painter = Service.create!(
      category: finishes,
      name: "Pintor",
      slug: "pintor",
      icon: "i-lucide-paintbrush",
      description: "Pintura residencial.",
      aliases: ["pintura"],
      is_active: true,
      sort_order: 0
    )
    electrician = Service.create!(
      category: installations,
      name: "Eletricista",
      slug: "eletricista",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 1
    )
    Service.create!(
      category: installations,
      name: "Inativo",
      slug: "inativo",
      icon: "i-lucide-ban",
      description: "Serviço inativo.",
      aliases: [],
      is_active: false,
      sort_order: 2
    )
    Service.create!(
      category: hidden_category,
      name: "Categoria inativa",
      slug: "categoria-inativa",
      icon: "i-lucide-ban",
      description: "Serviço oculto.",
      aliases: [],
      is_active: true,
      sort_order: 3
    )
    america = Neighborhood.create!(
      code: "america",
      state_code: "SC",
      city_code: "Joinville",
      name: "América",
      is_active: true,
      sort_order: 0
    )
    Neighborhood.create!(
      code: "atiradores",
      state_code: "SC",
      city_code: "Joinville",
      name: "Atiradores",
      is_active: false,
      sort_order: 1
    )

    get "/api/v1/catalog", headers: {"X-Request-Id" => "catalog-200"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "data" => {
        "categories" => [
          {"id" => finishes.id, "slug" => "acabamentos", "name" => "Acabamentos", "icon" => "i-lucide-paint-roller"},
          {"id" => installations.id, "slug" => "instalacoes", "name" => "Instalações", "icon" => "i-lucide-wrench"}
        ],
        "services" => [
          {"id" => painter.id, "name" => "Pintor", "slug" => "pintor", "categorySlug" => "acabamentos", "icon" => "i-lucide-paintbrush", "description" => "Pintura residencial.", "aliases" => ["pintura"]},
          {"id" => electrician.id, "name" => "Eletricista", "slug" => "eletricista", "categorySlug" => "instalacoes", "icon" => "i-lucide-zap", "description" => "Instalações elétricas.", "aliases" => ["elétrica"]}
        ],
        "neighborhoods" => [
          {"code" => america.code, "name" => "América", "stateCode" => "SC", "city" => "Joinville"}
        ]
      },
      "request_id" => "catalog-200"
    )
    assert_api_conform(status: 200)
  end

  it "returns the shared safe error when the catalog query is unavailable" do
    allow(ServiceCategory).to receive(:active).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/api/v1/catalog", headers: {"X-Request-Id" => "catalog-503"}

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq(
      "error" => {
        "code" => "service_unavailable",
        "message" => "Catálogo temporariamente indisponível.",
        "request_id" => "catalog-503"
      }
    )
    assert_api_conform(status: 503)
  end
end
