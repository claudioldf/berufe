# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalCustomerIndexQuery do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999982601", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Clientes") }

  it "searches normalized contact fields, aggregates quotes, and paginates deterministically" do
    alvaro = create_customer("Álvaro Lima", "+5547999982602", "alvaro@example.com")
    bianca = create_customer("Bianca Souza", "+5547999982603", "bianca@example.com")
    create_quote(alvaro, number: 1)
    latest = create_quote(alvaro, number: 2)

    result = described_class.new.call(scope: profile.customers, search: "alvaro", page: 1, per_page: 20)

    expect(result.customers.map(&:id)).to eq([alvaro.id])
    expect(result.customers.sole[:quote_count].to_i).to eq(2)
    expect(result.customers.sole[:last_quote_at].to_i).to eq(latest.updated_at.to_i)
    expect(result.meta).to eq(page: 1, per_page: 20, total_count: 1, total_pages: 1)

    phone_result = described_class.new.call(scope: profile.customers, search: "9982603")
    expect(phone_result.customers.map(&:id)).to eq([bianca.id])

    ordered = described_class.new.call(scope: profile.customers)
    expect(ordered.customers.map(&:id)).to eq([alvaro.id, bianca.id])
  end

  it "validates pagination and search bounds" do
    expect do
      described_class.new.call(scope: profile.customers, search: "x" * 101, page: 0, per_page: 101)
    end.to raise_error(described_class::Invalid) do |error|
      expect(error.field_errors.keys).to contain_exactly(:search, :page, :per_page)
    end
  end

  private

  def create_customer(name, phone, email)
    profile.customers.create!(name:, whatsapp_e164: phone, email:)
  end

  def create_quote(customer, number:)
    ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: customer.id,
          name: customer.name,
          whatsapp_e164: customer.whatsapp_e164,
          email: customer.email
        },
        service_description: "Serviço #{number}",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 100}]
      }
    )
  end
end
