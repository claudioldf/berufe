# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteMaterial, type: :model do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997451", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "carries no price and defaults to no requirement while the owning quote is a draft" do
    quote = ProfessionalQuoteWriter.new.call(profile:, attributes: {discount_amount: 0, items: []})

    material = quote.quote_materials.create!(description: "  Tinta  ", quantity: 2, unit: "  lata  ", sort_order: 0)

    expect(material).to have_attributes(description: "Tinta", unit: "lata")
    expect(material).not_to respond_to(:unit_price)
    expect(material).not_to respond_to(:line_total)
  end

  it "requires description, a positive quantity, and a unit once the quote is no longer a draft" do
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        status: "saved",
        customer: {id: nil, name: "Ana Paula", whatsapp_e164: "+5547999912051", email: nil},
        service_description: "Pintura completa",
        valid_until: "2026-01-01",
        discount_amount: 0,
        items: [{description: "Pintura", quantity: 1, unit: "serviço", unit_price: 100}]
      }
    )

    material = quote.quote_materials.build(description: "", quantity: 0, unit: "", sort_order: 0)

    expect(material).to be_invalid
    expect(material.errors.attribute_names).to contain_exactly(:description, :quantity, :unit)
  end

  it "rejects a duplicate sort order within the same quote" do
    quote = ProfessionalQuoteWriter.new.call(profile:, attributes: {discount_amount: 0, items: []})
    quote.quote_materials.create!(description: "Tinta", quantity: 2, unit: "lata", sort_order: 0)

    duplicate = quote.quote_materials.build(description: "Lixa", quantity: 5, unit: "folha", sort_order: 0)

    expect(duplicate).to be_invalid
    expect(duplicate.errors[:sort_order]).to be_present
  end
end
