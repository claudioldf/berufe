# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator catalog management", type: :request, openapi: true do
  let!(:installations) { create_category(name: "Instalações", slug: "instalacoes", icon: "i-lucide-wrench", order: 0) }
  let!(:finishes) { create_category(name: "Acabamentos", slug: "acabamentos", icon: "i-lucide-paint-roller", order: 1) }
  let!(:electrician) { create_service(category: installations, name: "Eletricista", slug: "eletricista", order: 0) }
  let!(:inactive_service) { create_service(category: finishes, name: "Pintor", slug: "pintor", active: false, order: 1) }
  let!(:america) { create_neighborhood(code: "america", name: "América", order: 0) }
  let!(:inactive_neighborhood) { create_neighborhood(code: "atiradores", name: "Atiradores", active: false, order: 1) }
  let(:admin) { create_admin }
  let(:admin_session) { issue_session(admin, request_id: "catalog-admin-session") }

  it "persists, audits, orders, and publicly reflects the existing admin-screen operations" do
    get_admin_catalog(session_token: admin_session.fetch(:token), request_id: "catalog-list")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body.dig("data", "services").pluck("slug")).to eq(%w[eletricista pintor])
    expect(response.parsed_body.dig("data", "services").last.fetch("is_active")).to be(false)
    expect(response.parsed_body.dig("data", "neighborhoods").pluck("code")).to eq(%w[america atiradores])
    expect(response.parsed_body.to_json).not_to include("Toda Joinville", '"code":"all"')
    assert_api_conform(status: 200)

    mutate(
      :post,
      "/api/v1/admin/catalog/services",
      params: {
        name: "Encanador",
        slug: "encanador",
        category_slug: "instalacoes",
        description: "Instalações e reparos hidráulicos."
      },
      session: admin_session,
      request_id: "catalog-service-create"
    )

    expect(response).to have_http_status(:created)
    created_service = Service.find_by!(slug: "encanador")
    expect(created_service).to have_attributes(
      category: installations,
      icon: installations.icon,
      aliases: [],
      is_active: true,
      sort_order: 2
    )
    assert_api_conform(status: 201)

    mutate(
      :patch,
      "/api/v1/admin/catalog/services/#{created_service.id}",
      params: {
        name: "Encanador residencial",
        category_slug: "acabamentos",
        description: "Reparos hidráulicos residenciais."
      },
      session: admin_session,
      request_id: "catalog-service-update"
    )

    expect(response).to have_http_status(:ok)
    expect(created_service.reload).to have_attributes(
      name: "Encanador residencial",
      category: finishes,
      slug: "encanador",
      icon: installations.icon,
      aliases: []
    )
    assert_api_conform(status: 200)

    get "/api/v1/catalog", headers: {"X-Request-Id" => "catalog-public-after-update"}
    expect(response.parsed_body.dig("data", "services").pluck("name")).to include("Encanador residencial")
    assert_api_conform(status: 200)

    mutate(
      :patch,
      "/api/v1/admin/catalog/services/#{created_service.id}",
      params: {is_active: false},
      session: admin_session,
      request_id: "catalog-service-deactivate"
    )
    expect(response).to have_http_status(:ok)
    expect(created_service.reload).not_to be_is_active
    assert_api_conform(status: 200)

    service_order = [created_service.id, inactive_service.id, electrician.id].map(&:to_s)
    mutate(
      :put,
      "/api/v1/admin/catalog/services/order",
      params: {ids: service_order},
      session: admin_session,
      request_id: "catalog-services-reorder"
    )
    expect(response).to have_http_status(:ok)
    expect(Service.ordered.pluck(:id).map(&:to_s)).to eq(service_order)
    expect(Service.ordered.pluck(:sort_order)).to eq([0, 1, 2])
    assert_api_conform(status: 200)

    mutate(
      :post,
      "/api/v1/admin/catalog/neighborhoods",
      params: {name: "Santo Antônio", code: "santo-antonio", state_code: "SC", city: "Joinville"},
      session: admin_session,
      request_id: "catalog-neighborhood-create"
    )
    expect(response).to have_http_status(:created)
    created_neighborhood = Neighborhood.find("santo-antonio")
    expect(created_neighborhood).to have_attributes(is_active: true, sort_order: 2)
    assert_api_conform(status: 201)

    mutate(
      :patch,
      "/api/v1/admin/catalog/neighborhoods/santo-antonio",
      params: {name: "Santo Antônio", state_code: "SC", city: "Joinville", is_active: false},
      session: admin_session,
      request_id: "catalog-neighborhood-deactivate"
    )
    expect(response).to have_http_status(:ok)
    expect(created_neighborhood.reload).not_to be_is_active
    assert_api_conform(status: 200)

    neighborhood_order = [created_neighborhood.code, inactive_neighborhood.code, america.code]
    mutate(
      :put,
      "/api/v1/admin/catalog/neighborhoods/order",
      params: {codes: neighborhood_order},
      session: admin_session,
      request_id: "catalog-neighborhoods-reorder"
    )
    expect(response).to have_http_status(:ok)
    expect(Neighborhood.ordered.pluck(:code)).to eq(neighborhood_order)
    expect(Neighborhood.ordered.pluck(:sort_order)).to eq([0, 1, 2])
    assert_api_conform(status: 200)

    expect(CatalogChangeEvent.order(:created_at, :id).pluck(:action)).to eq(
      %w[created updated deactivated reordered created deactivated reordered]
    )
    expect(CatalogChangeEvent.distinct.pluck(:admin_user_id)).to eq([admin.id])
    expect(CatalogChangeEvent.pluck(:request_id)).to contain_exactly(
      "catalog-service-create",
      "catalog-service-update",
      "catalog-service-deactivate",
      "catalog-services-reorder",
      "catalog-neighborhood-create",
      "catalog-neighborhood-deactivate",
      "catalog-neighborhoods-reorder"
    )

    get "/api/v1/catalog", headers: {"X-Request-Id" => "catalog-public-after-deactivate"}
    expect(response.parsed_body.dig("data", "services").pluck("slug")).not_to include("encanador")
    expect(response.parsed_body.dig("data", "neighborhoods").pluck("code")).not_to include("santo-antonio")
  end

  it "rejects anonymous and professional callers before exposing private catalog data" do
    private_requests(session: nil).each do |request|
      perform_private_request(**request, request_id: "catalog-anonymous-#{request.fetch(:name)}")
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("authentication_required")
      assert_api_conform(status: 401)
    end

    professional = UserAccount.create!(phone_e164: "+5547999998333", role: "professional", status: "active")
    professional_session = issue_session(professional, request_id: "catalog-professional-session")
    get_admin_catalog(session_token: professional_session.fetch(:token), request_id: "catalog-professional-list")
    expect(response).to have_http_status(:unauthorized)
    expect(response.body).not_to include(electrician.name, america.name)
    assert_api_conform(status: 401)
  end

  it "requires the exact browser origin for every mutation" do
    mutation_requests(session: admin_session).each_with_index do |request, index|
      mutate(
        request.fetch(:method),
        request.fetch(:path),
        params: request.fetch(:params),
        session: admin_session,
        request_id: "catalog-origin-denied-#{index}",
        origin: "https://untrusted.example"
      )
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("request_not_allowed")
      assert_api_conform(status: 403)
    end

    mutate(
      :post,
      "/api/v1/admin/catalog/services",
      params: valid_service_params,
      session: admin_session,
      request_id: "catalog-origin-missing",
      origin: nil
    )
    expect(response).to have_http_status(:forbidden)
    expect(Service.find_by(slug: "encanador")).to be_nil
  end

  it "returns not-found, conflict, and field-safe validation envelopes" do
    mutate(
      :post,
      "/api/v1/admin/catalog/services",
      params: valid_service_params.merge(category_slug: "categoria-inexistente"),
      session: admin_session,
      request_id: "catalog-service-category-missing"
    )
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    mutate(
      :patch,
      "/api/v1/admin/catalog/services/00000000-0000-4000-8000-000000000001",
      params: {name: "Serviço ausente"},
      session: admin_session,
      request_id: "catalog-service-missing"
    )
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    mutate(
      :patch,
      "/api/v1/admin/catalog/neighborhoods/nao-existe",
      params: {name: "Bairro ausente"},
      session: admin_session,
      request_id: "catalog-neighborhood-missing"
    )
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    mutate(
      :post,
      "/api/v1/admin/catalog/services",
      params: valid_service_params.merge(slug: electrician.slug),
      session: admin_session,
      request_id: "catalog-service-conflict"
    )
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    mutate(
      :put,
      "/api/v1/admin/catalog/services/order",
      params: {ids: [electrician.id.to_s]},
      session: admin_session,
      request_id: "catalog-service-order-conflict"
    )
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    mutate(
      :post,
      "/api/v1/admin/catalog/neighborhoods",
      params: {name: "América duplicada", code: america.code, state_code: "SC", city: "Joinville"},
      session: admin_session,
      request_id: "catalog-neighborhood-conflict"
    )
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    mutate(
      :put,
      "/api/v1/admin/catalog/neighborhoods/order",
      params: {codes: [america.code]},
      session: admin_session,
      request_id: "catalog-neighborhood-order-conflict"
    )
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    duplicate_inactive = create_neighborhood(
      code: "america-inativa",
      name: america.name,
      active: false,
      order: 3
    )
    mutate(
      :patch,
      "/api/v1/admin/catalog/neighborhoods/#{duplicate_inactive.code}",
      params: {is_active: true},
      session: admin_session,
      request_id: "catalog-neighborhood-activation-conflict"
    )
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    mutate(
      :post,
      "/api/v1/admin/catalog/services",
      params: valid_service_params.merge(description: " "),
      session: admin_session,
      request_id: "catalog-service-invalid"
    )
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to include("description")
    assert_api_conform(status: 422)

    mutate(
      :patch,
      "/api/v1/admin/catalog/services/#{electrician.id}",
      params: {name: " "},
      session: admin_session,
      request_id: "catalog-service-update-invalid"
    )
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    mutate(
      :post,
      "/api/v1/admin/catalog/neighborhoods",
      params: {name: " ", code: "bairro-novo", state_code: "SC", city: "Joinville"},
      session: admin_session,
      request_id: "catalog-neighborhood-invalid"
    )
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    mutate(
      :patch,
      "/api/v1/admin/catalog/neighborhoods/#{america.code}",
      params: {name: " "},
      session: admin_session,
      request_id: "catalog-neighborhood-update-invalid"
    )
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)
  end

  it "rolls back catalog mutations and returns safe unavailable responses" do
    allow(CatalogManagement).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    private_requests(session: admin_session).each do |request|
      perform_private_request(**request, request_id: "catalog-unavailable-#{request.fetch(:name)}")
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig("error", "code")).to eq("catalog_unavailable")
      assert_api_conform(status: 503)
    end

    expect(CatalogChangeEvent.count).to eq(0)
    expect(Service.find_by(slug: "encanador")).to be_nil
    expect(Neighborhood.find_by(code: "santo-antonio")).to be_nil
  end

  private

  def valid_service_params
    {
      name: "Encanador",
      slug: "encanador",
      category_slug: installations.slug,
      description: "Instalações hidráulicas."
    }
  end

  def mutation_requests(session:)
    [
      {name: "service-create", method: :post, path: "/api/v1/admin/catalog/services", params: valid_service_params, session:},
      {name: "service-update", method: :patch, path: "/api/v1/admin/catalog/services/#{electrician.id}", params: {name: "Eletricista residencial"}, session:},
      {name: "service-order", method: :put, path: "/api/v1/admin/catalog/services/order", params: {ids: [inactive_service.id.to_s, electrician.id.to_s]}, session:},
      {name: "neighborhood-create", method: :post, path: "/api/v1/admin/catalog/neighborhoods", params: {name: "Santo Antônio", code: "santo-antonio", state_code: "SC", city: "Joinville"}, session:},
      {name: "neighborhood-update", method: :patch, path: "/api/v1/admin/catalog/neighborhoods/#{america.code}", params: {name: "América"}, session:},
      {name: "neighborhood-order", method: :put, path: "/api/v1/admin/catalog/neighborhoods/order", params: {codes: [inactive_neighborhood.code, america.code]}, session:}
    ]
  end

  def private_requests(session:)
    [{name: "list", method: :get, path: "/api/v1/admin/catalog", params: {}, session:}] + mutation_requests(session:)
  end

  def perform_private_request(name:, method:, path:, params:, session:, request_id:)
    if method == :get
      get_admin_catalog(session_token: session&.fetch(:token, nil), request_id:)
    else
      mutate(method, path, params:, session:, request_id:)
    end
  end

  def issue_session(account, request_id:)
    _application_session, token = ApplicationSession.issue!(user_account: account)
    get "/api/v1/session", headers: session_headers(token:, request_id:)
    {token:}
  end

  def get_admin_catalog(session_token:, request_id:)
    get "/api/v1/admin/catalog", headers: session_headers(token: session_token, request_id:)
  end

  def mutate(method, path, params:, session:, request_id:, origin: ENV.fetch("WEB_ORIGIN"))
    headers = session_headers(token: session&.fetch(:token, nil), request_id:)
    headers["Origin"] = origin if origin
    public_send(method, path, params:, headers:, as: :json)
  end

  def session_headers(token:, request_id:)
    headers = {"X-Request-Id" => request_id}
    headers["Cookie"] = "#{ApplicationSession::COOKIE_NAME}=#{token}" if token
    headers
  end

  def create_admin
    UserAccount.create!(
      email: "admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end

  def create_category(name:, slug:, icon:, order:)
    ServiceCategory.create!(name:, slug:, icon:, is_active: true, sort_order: order)
  end

  def create_service(category:, name:, slug:, order:, active: true)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-zap",
      description: "Descrição pública.",
      aliases: [],
      is_active: active,
      sort_order: order
    )
  end

  def create_neighborhood(code:, name:, order:, active: true)
    Neighborhood.create!(
      code:,
      name:,
      state_code: "SC",
      city_code: "Joinville",
      is_active: active,
      sort_order: order
    )
  end
end
