# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Administrator service catalog management", type: :request, openapi: true do
  let!(:installations) do
    ServiceCategory.create!(
      name: "Instalações",
      slug: "instalacoes",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) { create_service(name: "Eletricista", slug: "eletricista", order: 0) }
  let!(:painter) { create_service(name: "Pintor", slug: "pintor", order: 1) }
  let(:admin) do
    UserAccount.create!(
      email: "admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:session) do
    _application_session, token = ApplicationSession.issue!(user_account: admin)
    {token:}
  end

  it "lists, creates, updates, reorders, and audits services" do
    get_admin_catalog(request_id: "catalog-list")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "services").pluck("slug")).to eq(%w[eletricista pintor])
    expect(response.parsed_body.dig("data")).not_to have_key("neighborhoods")
    assert_api_conform(status: 200)

    mutate :post, "/api/v1/admin/catalog/services",
      params: valid_service_params,
      request_id: "catalog-service-create"
    expect(response).to have_http_status(:created)
    plumber = Service.find_by!(slug: "encanador")
    assert_api_conform(status: 201)

    mutate :patch, "/api/v1/admin/catalog/services/#{plumber.id}",
      params: {name: "Encanador residencial", is_active: false},
      request_id: "catalog-service-update"
    expect(response).to have_http_status(:ok)
    expect(plumber.reload).to have_attributes(name: "Encanador residencial", is_active: false)
    assert_api_conform(status: 200)

    order = [plumber.id, painter.id, electrician.id].map(&:to_s)
    mutate :put, "/api/v1/admin/catalog/services/order",
      params: {ids: order},
      request_id: "catalog-services-reorder"
    expect(response).to have_http_status(:ok)
    expect(Service.ordered.pluck(:id).map(&:to_s)).to eq(order)
    expect(CatalogChangeEvent.order(:created_at, :id).pluck(:action)).to eq(%w[created updated reordered])
    assert_api_conform(status: 200)
  end

  it "rejects anonymous callers" do
    get "/api/v1/admin/catalog", headers: {"X-Request-Id" => "catalog-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    anonymous_mutate :post, "/api/v1/admin/catalog/services",
      params: valid_service_params,
      request_id: "catalog-service-create-anonymous"
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    anonymous_mutate :patch, "/api/v1/admin/catalog/services/#{electrician.id}",
      params: {name: "Eletricista residencial"},
      request_id: "catalog-service-update-anonymous"
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    anonymous_mutate :put, "/api/v1/admin/catalog/services/order",
      params: {ids: [electrician.id, painter.id].map(&:to_s)},
      request_id: "catalog-services-reorder-anonymous"
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)
  end

  it "rejects untrusted mutation origins" do
    mutate :post, "/api/v1/admin/catalog/services",
      params: valid_service_params,
      request_id: "catalog-origin-denied",
      origin: "https://untrusted.example"
    expect(response).to have_http_status(:forbidden)
    expect(Service.find_by(slug: "encanador")).to be_nil
    assert_api_conform(status: 403)

    mutate :patch, "/api/v1/admin/catalog/services/#{electrician.id}",
      params: {name: "Eletricista residencial"},
      request_id: "catalog-service-update-origin-denied",
      origin: "https://untrusted.example"
    expect(response).to have_http_status(:forbidden)
    expect(electrician.reload.name).to eq("Eletricista")
    assert_api_conform(status: 403)

    mutate :put, "/api/v1/admin/catalog/services/order",
      params: {ids: [painter.id, electrician.id].map(&:to_s)},
      request_id: "catalog-services-reorder-origin-denied",
      origin: "https://untrusted.example"
    expect(response).to have_http_status(:forbidden)
    expect(Service.ordered).to eq([electrician, painter])
    assert_api_conform(status: 403)
  end

  it "returns safe not-found, conflict, and validation envelopes" do
    mutate :patch, "/api/v1/admin/catalog/services/00000000-0000-4000-8000-000000000001",
      params: {name: "Ausente"},
      request_id: "catalog-missing"
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    mutate :post, "/api/v1/admin/catalog/services",
      params: valid_service_params.merge(category_slug: "categoria-ausente"),
      request_id: "catalog-category-missing"
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    mutate :post, "/api/v1/admin/catalog/services",
      params: valid_service_params.merge(slug: electrician.slug),
      request_id: "catalog-conflict"
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    mutate :put, "/api/v1/admin/catalog/services/order",
      params: {ids: [electrician.id.to_s]},
      request_id: "catalog-order-conflict"
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    mutate :post, "/api/v1/admin/catalog/services",
      params: valid_service_params.merge(description: " "),
      request_id: "catalog-invalid"
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to include("description")
    assert_api_conform(status: 422)

    mutate :patch, "/api/v1/admin/catalog/services/#{electrician.id}",
      params: {description: " "},
      request_id: "catalog-update-invalid"
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to include("description")
    assert_api_conform(status: 422)
  end

  it "returns a safe unavailable response" do
    allow(CatalogManagement).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)

    get_admin_catalog(request_id: "catalog-unavailable")
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("catalog_unavailable")
    assert_api_conform(status: 503)

    mutate :post, "/api/v1/admin/catalog/services",
      params: valid_service_params,
      request_id: "catalog-service-create-unavailable"
    expect(response).to have_http_status(:service_unavailable)
    assert_api_conform(status: 503)

    mutate :patch, "/api/v1/admin/catalog/services/#{electrician.id}",
      params: {name: "Eletricista residencial"},
      request_id: "catalog-service-update-unavailable"
    expect(response).to have_http_status(:service_unavailable)
    assert_api_conform(status: 503)

    mutate :put, "/api/v1/admin/catalog/services/order",
      params: {ids: [electrician.id, painter.id].map(&:to_s)},
      request_id: "catalog-services-reorder-unavailable"
    expect(response).to have_http_status(:service_unavailable)
    assert_api_conform(status: 503)
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

  def get_admin_catalog(request_id:)
    get "/api/v1/admin/catalog", headers: session_headers(request_id:)
  end

  def mutate(method, path, params:, request_id:, origin: ENV.fetch("WEB_ORIGIN"))
    headers = session_headers(request_id:)
    headers["Origin"] = origin if origin
    public_send(method, path, params:, headers:, as: :json)
  end

  def anonymous_mutate(method, path, params:, request_id:)
    public_send(
      method,
      path,
      params:,
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id},
      as: :json
    )
  end

  def session_headers(request_id:)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{session.fetch(:token)}"
    }
  end

  def create_service(name:, slug:, order:)
    Service.create!(
      category: installations,
      name:,
      slug:,
      icon: "i-lucide-zap",
      description: "Descrição pública.",
      aliases: [],
      is_active: true,
      sort_order: order
    )
  end
end
