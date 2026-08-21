# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional customers", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999982801", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Clientes") }
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end

  it "lists and searches only the current professional's customers with quote summaries" do
    marina = create_customer("Marina Cliente", "+5547999982802", "marina@example.com")
    bianca = create_customer("Bianca Cliente", "+5547999982803", nil)
    quote = create_quote(marina)
    other_profile = create_other_profile
    other_profile.customers.create!(
      name: "Marina de Outro",
      whatsapp_e164: "+5547999982804",
      email: "outra@example.com"
    )

    get "/api/v1/professional/customers",
      params: {search: "marina", page: 1, per_page: 20},
      headers: session_headers(request_id: "customers-list")

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to eq("no-store")
    expect(response.parsed_body.dig("data", "customers")).to contain_exactly(
      include(
        "id" => marina.id,
        "name" => "Marina Cliente",
        "whatsapp_e164" => "+5547999982802",
        "email" => "marina@example.com",
        "email_verified" => false,
        "quote_count" => 1,
        "last_quote_at" => quote.updated_at.iso8601(3)
      )
    )
    expect(response.parsed_body.dig("data", "meta")).to eq(
      "page" => 1,
      "per_page" => 20,
      "total_count" => 1,
      "total_pages" => 1
    )
    expect(response.body).not_to include(other_profile.customers.sole.id, bianca.id)
    assert_api_conform(status: 200)

    get "/api/v1/professional/customers",
      params: {search: "9982803"},
      headers: session_headers(request_id: "customers-phone-search")
    expect(response.parsed_body.dig("data", "customers").pluck("id")).to eq([bianca.id])
    assert_api_conform(status: 200)

    query = instance_double(ProfessionalCustomerIndexQuery)
    allow(ProfessionalCustomerIndexQuery).to receive(:new).and_return(query)
    allow(query).to receive(:call).and_raise(
      ProfessionalCustomerIndexQuery::Invalid.new(search: ["use uma busca válida"])
    )
    get "/api/v1/professional/customers",
      params: {search: "Marina", page: 1, per_page: 20},
      headers: session_headers(request_id: "customers-invalid-response")
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)
  end

  it "shows and updates a customer without changing historical quote snapshots" do
    customer = create_customer(
      "Marina Cliente",
      "+5547999982810",
      "marina@example.com",
      email_verified_at: 1.day.ago
    )
    quote = create_quote(customer)

    get "/api/v1/professional/customers/#{customer.id}",
      headers: session_headers(request_id: "customers-show")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "customer")).to include(
      "id" => customer.id,
      "quote_count" => 1,
      "email_verified" => true
    )
    assert_api_conform(status: 200)

    patch "/api/v1/professional/customers/#{customer.id}",
      params: {
        customer: {
          name: "Marina Atualizada",
          whatsapp_e164: "+5547999982811",
          email: "nova@example.com"
        }
      },
      headers: session_headers(request_id: "customers-update", origin: true),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "customer")).to include(
      "name" => "Marina Atualizada",
      "whatsapp_e164" => "+5547999982811",
      "email" => "nova@example.com",
      "email_verified" => false
    )
    expect(quote.reload).to have_attributes(
      customer_name: "Marina Cliente",
      customer_phone_e164: "+5547999982810",
      customer_email: "marina@example.com"
    )
    assert_api_conform(status: 200)
  end

  it "rejects invalid updates and never exposes another professional's customer" do
    customer = create_customer("Cliente", "+5547999982820", nil)
    other = create_other_profile.customers.create!(
      name: "Outro Cliente",
      whatsapp_e164: "+5547999982821"
    )

    patch "/api/v1/professional/customers/#{customer.id}",
      params: {customer: {name: "", whatsapp_e164: "123", email: "invalido"}},
      headers: session_headers(request_id: "customers-invalid", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to include(
      "name",
      "whatsapp_e164",
      "email"
    )

    updater = instance_double(ProfessionalCustomerUpdater)
    allow(ProfessionalCustomerUpdater).to receive(:new).and_return(updater)
    allow(updater).to receive(:call).and_raise(
      ProfessionalCustomerUpdater::Invalid.new(name: ["não pode ficar em branco"])
    )
    patch "/api/v1/professional/customers/#{customer.id}",
      params: {
        customer: {
          name: "Cliente",
          whatsapp_e164: "+5547999982820",
          email: nil
        }
      },
      headers: session_headers(request_id: "customers-invalid-response", origin: true),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    get "/api/v1/professional/customers/#{other.id}",
      headers: session_headers(request_id: "customers-other")
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    patch "/api/v1/professional/customers/#{other.id}",
      params: {
        customer: {
          name: "Outro Cliente",
          whatsapp_e164: "+5547999982821",
          email: nil
        }
      },
      headers: session_headers(request_id: "customers-other-update", origin: true),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  it "requires authentication and an exact mutation origin" do
    customer = create_customer("Cliente", "+5547999982830", nil)

    get "/api/v1/professional/customers", headers: {"X-Request-Id" => "customers-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    get "/api/v1/professional/customers/#{customer.id}",
      headers: {"X-Request-Id" => "customer-show-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/customers/#{customer.id}",
      params: {
        customer: {
          name: customer.name,
          whatsapp_e164: customer.whatsapp_e164,
          email: customer.email
        }
      },
      headers: {
        "X-Request-Id" => "customer-update-anonymous",
        "Origin" => ENV.fetch("WEB_ORIGIN")
      },
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/customers/#{customer.id}",
      params: {customer: {name: customer.name}},
      headers: session_headers(request_id: "customers-origin", origin: "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    unregistered = UserAccount.create!(
      phone_e164: "+5547999982831",
      role: "professional",
      status: "active"
    )
    unregistered_token = ApplicationSession.issue!(user_account: unregistered).last
    get "/api/v1/professional/customers",
      headers: session_headers(
        request_id: "customers-without-profile",
        token: unregistered_token
      )
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def create_customer(name, phone, email, email_verified_at: nil)
    profile.customers.create!(
      name:,
      whatsapp_e164: phone,
      email:,
      email_verified_at:
    )
  end

  def create_quote(customer)
    ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: customer.id,
          name: customer.name,
          whatsapp_e164: customer.whatsapp_e164,
          email: customer.email
        },
        service_description: "Serviço residencial",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 100}]
      }
    )
  end

  def create_other_profile
    other_account = UserAccount.create!(
      phone_e164: "+5547999982899",
      role: "professional",
      status: "active"
    )
    ProfessionalProfile.create!(user_account: other_account, display_name: "Outro Profissional")
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
