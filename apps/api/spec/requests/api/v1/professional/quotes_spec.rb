# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional quotes", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997431", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "creates, lists, reads, and updates only server-calculated ordered content" do
    post "/api/v1/professional/quotes",
      params: quote_body,
      headers: session_headers(request_id: "quote-create", origin: true),
      as: :json

    expect(response).to have_http_status(:created)
    quote = Quote.sole
    expect(response.headers.fetch("Location")).to end_with(quote.id)
    expect(response.parsed_body.dig("data", "quote")).to include(
      "id" => quote.id,
      "quote_number" => 1,
      "customer_name" => "Ana Paula",
      "service_description" => "Iluminação da cozinha",
      "subtotal_amount" => "840.00",
      "discount_amount" => "40.00",
      "total_amount" => "800.00",
      "status" => "draft",
      "shared_at" => nil
    )
    expect(response.parsed_body.dig("data", "quote", "items").pluck("description", "sort_order")).to eq([
      ["Instalação", 0],
      ["Revisão", 1]
    ])
    expect(ProfessionalDailyActivity.sole.quotes_created).to eq(1)
    assert_api_conform(status: 201)

    get "/api/v1/professional/quotes",
      headers: session_headers(request_id: "quote-list")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "quotes").pluck("id")).to eq([quote.id])
    expect(response.parsed_body.dig("data", "meta")).to eq(
      "page" => 1,
      "per_page" => 20,
      "total_count" => 1,
      "total_pages" => 1
    )
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    assert_api_conform(status: 200)

    get "/api/v1/professional/quotes/#{quote.id}",
      headers: session_headers(request_id: "quote-show")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "quote", "id")).to eq(quote.id)
    assert_api_conform(status: 200)

    patch "/api/v1/professional/quotes/#{quote.id}",
      params: quote_body(
        customer_name: "Cliente atualizado",
        revision: quote.lock_version,
        discount_amount: 0,
        items: [{description: "Diagnóstico", quantity: 2, unit: "hora", unit_price: 75}]
      ),
      headers: session_headers(request_id: "quote-update", origin: true),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "quote")).to include(
      "quote_number" => 1,
      "customer_name" => "Cliente atualizado",
      "subtotal_amount" => "150.00",
      "discount_amount" => "0.00",
      "total_amount" => "150.00",
      "status" => "draft"
    )
    expect(quote.reload.quote_items.sole).to have_attributes(
      description: "Diagnóstico",
      sort_order: 0
    )
    expect(ProfessionalDailyActivity.sole.quotes_created).to eq(1)
    assert_api_conform(status: 200)
  end

  it "filters, sorts, and paginates the owner-scoped quote index in the database" do
    low = create_quote(
      customer: {name: "Álvaro Lima"},
      service_description: "Pintura interna",
      scheduled_on: "2026-09-01",
      discount_amount: 0,
      items: [{description: "Pintura", quantity: 1, unit: "serviço", unit_price: 100}]
    )
    middle = create_quote(
      customer: {name: "José Silva"},
      service_description: "Instalação hidráulica",
      scheduled_on: "2026-09-02",
      discount_amount: 0,
      items: [{description: "Instalação", quantity: 1, unit: "serviço", unit_price: 200}]
    )
    high = create_quote(
      customer: {name: "Maria Souza"},
      service_description: "Revisão elétrica",
      scheduled_on: "2026-09-01",
      discount_amount: 0,
      items: [{description: "Revisão", quantity: 1, unit: "serviço", unit_price: 300}]
    )

    get "/api/v1/professional/quotes",
      params: {search: "jose", status: "draft", scheduled_on: "2026-09-02"},
      headers: session_headers(request_id: "quote-list-filtered")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "quotes").pluck("id")).to eq([middle.id])
    expect(response.parsed_body.dig("data", "meta", "total_count")).to eq(1)
    assert_api_conform(status: 200)

    get "/api/v1/professional/quotes",
      params: {sort: "total", direction: "desc", page: 2, per_page: 1},
      headers: session_headers(request_id: "quote-list-paginated")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "quotes").pluck("id")).to eq([middle.id])
    expect(response.parsed_body.dig("data", "meta")).to eq(
      "page" => 2,
      "per_page" => 1,
      "total_count" => 3,
      "total_pages" => 3
    )
    expect(response.parsed_body.dig("data", "quotes").pluck("id")).not_to include(low.id, high.id)
    assert_api_conform(status: 200)
  end

  it "rejects invalid quote index filters" do
    get "/api/v1/professional/quotes",
      params: {
        search: "x" * 101,
        status: "waiting",
        scheduled_on: "not-a-date",
        sort: "secret",
        direction: "sideways",
        page: 0,
        per_page: 101
      },
      headers: session_headers(request_id: "quote-list-invalid")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors").keys).to contain_exactly(
      "search",
      "status",
      "scheduled_on",
      "sort",
      "direction",
      "page",
      "per_page"
    )

    # The contract rejects those malformed query values before validating the
    # response, so exercise the documented 422 body with a valid request.
    query = instance_double(ProfessionalQuoteIndexQuery)
    allow(ProfessionalQuoteIndexQuery).to receive(:new).and_return(query)
    allow(query).to receive(:call).and_raise(
      ProfessionalQuoteIndexQuery::Invalid.new(sort: ["use uma coluna de ordenação válida"])
    )
    get "/api/v1/professional/quotes",
      params: {sort: "updated", direction: "desc", page: 1, per_page: 20},
      headers: session_headers(request_id: "quote-list-invalid-response")

    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)
  end

  it "keeps a shared quote's lifecycle stable while owner edits become live" do
    quote = create_quote
    token = QuoteShareToken.issue
    token_hash = QuoteShareToken.digest(token)
    shared_at = 1.hour.ago.change(usec: 0)
    quote.update!(
      status: "shared",
      share_token_hash: token_hash,
      share_token_ciphertext: QuoteShareToken.encrypt(token),
      shared_at:
    )

    patch "/api/v1/professional/quotes/#{quote.id}",
      params: quote_body(customer_name: "Conteúdo mais recente", revision: quote.lock_version),
      headers: session_headers(request_id: "quote-shared-update", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(quote.reload).to have_attributes(
      status: "shared",
      share_token_hash: token_hash,
      shared_at:,
      customer_name: "Conteúdo mais recente"
    )
    expect(response.parsed_body.dig("data", "quote")).to include(
      "status" => "shared",
      "shared_at" => shared_at.iso8601,
      "customer_name" => "Conteúdo mais recente"
    )
    assert_api_conform(status: 200)
  end

  it "rejects invalid creates and updates without consuming numbers or content" do
    post "/api/v1/professional/quotes",
      params: quote_body(discount_amount: 1_000),
      headers: session_headers(request_id: "quote-create-invalid", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors", "discount_amount")).to be_present
    expect(Quote.count).to eq(0)
    assert_api_conform(status: 422)

    quote = create_quote
    item_ids = quote.quote_items.ids
    patch "/api/v1/professional/quotes/#{quote.id}",
      params: quote_body(
        revision: quote.lock_version,
        discount_amount: 1_000,
        items: [{description: "Substituição", quantity: 1, unit: "hora", unit_price: 20}]
      ),
      headers: session_headers(request_id: "quote-update-invalid", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(quote.reload.quote_items.ids).to eq(item_ids)
    assert_api_conform(status: 422)

    created = create_quote
    expect(created.quote_number).to eq(2)
  end

  it "isolates quote reads and recent dashboard rows by owner" do
    own = create_quote
    other_account = UserAccount.create!(
      phone_e164: "+5547999997432",
      role: "professional",
      status: "active"
    )
    other_profile = ProfessionalProfile.create!(user_account: other_account, display_name: "Beto Lima")
    other_quote = ProfessionalQuoteWriter.new.call(profile: other_profile, attributes: quote_attributes)

    get "/api/v1/professional/quotes/#{other_quote.id}",
      headers: session_headers(request_id: "quote-other-show")
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    patch "/api/v1/professional/quotes/#{other_quote.id}",
      params: quote_body,
      headers: session_headers(request_id: "quote-other-update", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    5.times do |index|
      ProfessionalQuoteWriter.new.call(
        profile:,
        attributes: quote_attributes.merge(
          customer: quote_attributes[:customer].merge(name: "Cliente #{index}")
        )
      )
    end
    get "/api/v1/professional/workspace",
      headers: session_headers(request_id: "quote-dashboard-recent")
    recent = response.parsed_body.dig("data", "dashboard", "recent_quotes")
    expect(recent.length).to eq(5)
    expect(recent.pluck("id")).to eq(profile.quotes.newest_first.limit(5).ids)
    expect(recent.pluck("id")).not_to include(other_quote.id, own.id)
    assert_api_conform(status: 200)
  end

  it "enforces sessions, exact mutation origins, and completed registration" do
    quote = create_quote

    get "/api/v1/professional/quotes", headers: {"X-Request-Id" => "quote-list-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    get "/api/v1/professional/quotes/#{quote.id}", headers: {"X-Request-Id" => "quote-show-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/quotes",
      params: quote_body,
      headers: {"X-Request-Id" => "quote-create-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/quotes/#{quote.id}",
      params: quote_body,
      headers: {"X-Request-Id" => "quote-update-anonymous", "Origin" => ENV.fetch("WEB_ORIGIN")},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/quotes",
      params: quote_body,
      headers: session_headers(request_id: "quote-create-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    patch "/api/v1/professional/quotes/#{quote.id}",
      params: quote_body,
      headers: session_headers(request_id: "quote-update-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    unregistered = UserAccount.create!(
      phone_e164: "+5547999997433",
      role: "professional",
      status: "active"
    )
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    get "/api/v1/professional/quotes",
      headers: session_headers(
        request_id: "quote-list-unregistered",
        token: unregistered_token
      )
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/quotes",
      params: quote_body,
      headers: session_headers(
        request_id: "quote-create-unregistered",
        origin: true,
        token: unregistered_token
      ),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def create_quote(**overrides)
    ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: quote_attributes.deep_merge(overrides)
    )
  end

  def quote_body(**overrides)
    customer_name = overrides.delete(:customer_name)
    attributes = quote_attributes.merge(overrides)
    customer = attributes[:customer].merge(name: customer_name || attributes.dig(:customer, :name))
    {
      quote: {
        **attributes.slice(:revision),
        customer:,
        service_description: attributes[:service_description],
        service_address: attributes[:service_address],
        scheduled_on: attributes[:scheduled_on],
        discount_amount: attributes[:discount_amount],
        valid_until: attributes[:valid_until],
        notes: attributes[:notes],
        items: attributes[:items]
      }
    }
  end

  def quote_attributes
    {
      customer: {
        id: nil,
        name: "Ana Paula",
        whatsapp_e164: "+5547999912031",
        email: "ana.paula@example.com"
      },
      service_description: "Iluminação da cozinha",
      service_address: "Rua das Flores, 100",
      scheduled_on: "2026-08-27",
      discount_amount: 40,
      valid_until: "2026-08-30",
      notes: "Materiais definidos com a cliente.",
      items: [
        {description: "Instalação", quantity: 4, unit: "ponto", unit_price: 200},
        {description: "Revisão", quantity: 1, unit: "serviço", unit_price: 40}
      ]
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
