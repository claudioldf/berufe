# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalQuoteWriter do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997411", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "assigns the next owner number and calculates ordered decimal totals on the server" do
    quote = described_class.new.call(
      profile:,
      attributes: valid_attributes.merge(subtotal_amount: 999_999, total_amount: 1)
    )

    expect(quote).to have_attributes(
      quote_number: 1,
      customer_name: "Ana Paula",
      service_description: "Iluminação da cozinha",
      subtotal_amount: BigDecimal("13.33"),
      discount_amount: BigDecimal("1.33"),
      total_amount: BigDecimal("12.00"),
      status: "draft"
    )
    expect(quote.quote_items.pluck(:sort_order, :line_total)).to eq([
      [0, BigDecimal("3.33")],
      [1, BigDecimal("10.00")]
    ])
    expect(ProfessionalDailyActivity.sole).to have_attributes(
      professional: profile,
      quotes_created: 1
    )
    expect(profile.reload.last_quote_pricing_mode).to eq("itemized")

    second = described_class.new.call(profile:, attributes: valid_attributes)
    expect(second.quote_number).to eq(2)
    expect(ProfessionalDailyActivity.sole.quotes_created).to eq(2)
  end

  it "rolls back invalid creates and updates with their item replacement" do
    expect do
      described_class.new.call(
        profile:,
        attributes: valid_attributes.merge(status: "saved", discount_amount: 14)
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors).to include(:discount_amount)
    }
    expect(profile.quotes.reload).to be_empty
    expect(ProfessionalDailyActivity.where(professional: profile)).to be_empty

    quote = described_class.new.call(profile:, attributes: valid_attributes)
    original_item_ids = quote.quote_items.ids
    expect do
      described_class.new.call(
        profile:,
        quote:,
        attributes: valid_attributes.merge(
          status: "saved",
          revision: quote.lock_version,
          items: []
        )
      )
    end.to raise_error(described_class::Invalid)
    expect(quote.reload.quote_items.ids).to eq(original_item_ids)
  end

  it "persists an unshared quote as saved without creating share state" do
    quote = described_class.new.call(
      profile:,
      attributes: valid_attributes.merge(status: "saved")
    )

    expect(quote).to have_attributes(
      status: "saved",
      share_token_hash: nil,
      share_token_ciphertext: nil,
      shared_at: nil
    )
  end

  it "keeps the fixed customer price independent and persists customer-supplied materials" do
    quote = described_class.new.call(
      profile:,
      attributes: valid_attributes.merge(
        pricing_mode: "fixed_price",
        fixed_price_amount: 2000,
        discount_amount: 0,
        items: [
          {description: "Mão de obra", quantity: 1, unit: "serviço", unit_price: 1500},
          {description: "Deslocamento", quantity: 1, unit: "serviço", unit_price: 200}
        ],
        customer_supplied_materials: [
          {description: "  Tinta acrílica branca 18 L  ", quantity: 2, unit: "  lata  "},
          {description: "Lixa para parede", quantity: 10, unit: "folha"}
        ]
      )
    )

    expect(quote).to have_attributes(
      pricing_mode: "fixed_price",
      subtotal_amount: BigDecimal("1700.00"),
      fixed_price_amount: BigDecimal("2000.00"),
      discount_amount: BigDecimal("0.00"),
      total_amount: BigDecimal("2000.00")
    )
    expect(quote.quote_materials.pluck(:description, :quantity, :unit, :sort_order)).to eq([
      ["Tinta acrílica branca 18 L", BigDecimal(2), "lata", 0],
      ["Lixa para parede", BigDecimal(10), "folha", 1]
    ])
    expect(profile.reload.last_quote_pricing_mode).to eq("fixed_price")
  end

  it "rejects fractional customer-supplied material quantities" do
    expect do
      described_class.new.call(
        profile:,
        attributes: valid_attributes.merge(
          status: "saved",
          customer_supplied_materials: [
            {description: "Lata de tinta acrílica branca 18 L", quantity: 1.5, unit: "unidade"}
          ]
        )
      )
    end.to raise_error(described_class::Invalid)
  end

  it "persists partial drafts without creating an invalid customer" do
    quote = described_class.new.call(
      profile:,
      attributes: {
        status: "draft",
        customer: {id: nil, name: "", whatsapp_e164: "", email: nil},
        service_description: "",
        discount_amount: 0,
        items: [{description: "", quantity: 0, unit: "serviço", unit_price: 0}]
      }
    )

    expect(quote).to have_attributes(
      status: "draft",
      customer: nil,
      customer_name: "",
      customer_phone_e164: nil,
      service_description: ""
    )
    expect(quote.quote_items.sole).to have_attributes(
      description: "",
      quantity: 0,
      line_total: 0
    )
    expect(profile.customers).to be_empty
  end

  it "keeps shared lifecycle state and token stable while replacing live content" do
    quote = described_class.new.call(profile:, attributes: valid_attributes)
    shared_at = 2.minutes.ago.change(usec: 0)
    token = QuoteShareToken.issue
    token_hash = QuoteShareToken.digest(token)
    quote.update!(
      status: "shared",
      share_token_hash: token_hash,
      share_token_ciphertext: QuoteShareToken.encrypt(token),
      shared_at:
    )

    updated = described_class.new.call(
      profile:,
      quote:,
      attributes: valid_attributes.merge(
        revision: quote.lock_version,
        customer: valid_attributes[:customer].merge(name: "Cliente atualizado"),
        items: [
          {description: "Serviço atualizado", quantity: "2", unit: "hora", unit_price: "25.00"}
        ]
      )
    )

    expect(updated).to have_attributes(
      status: "shared",
      share_token_hash: token_hash,
      shared_at:,
      customer_name: "Cliente atualizado",
      total_amount: BigDecimal("48.67")
    )
    expect(updated.quote_items.sole.description).to eq("Serviço atualizado")
  end

  private

  def valid_attributes
    {
      customer: {
        id: nil,
        name: "  Ana Paula  ",
        whatsapp_e164: "(47) 99991-2011",
        email: "ana.cliente@example.com"
      },
      pricing_mode: "itemized",
      fixed_price_amount: 0,
      service_description: "  Iluminação da cozinha  ",
      valid_until: Date.new(2026, 8, 30),
      discount_amount: "1.33",
      notes: "  Materiais definidos com a cliente.  ",
      items: [
        {description: "Circuito", quantity: "0.333", unit: "serviço", unit_price: "10.01"},
        {description: "Pontos", quantity: "2", unit: "ponto", unit_price: "5.00"}
      ],
      customer_supplied_materials: []
    }
  end
end
