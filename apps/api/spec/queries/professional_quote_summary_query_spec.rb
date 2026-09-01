# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalQuoteSummaryQuery do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999993101", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:scope) { Quote.where(professional: profile) }
  let(:now) { Time.zone.parse("2026-09-01 02:30:00 UTC") }

  it "summarizes the current owner pipeline independently from unrelated quotes" do
    create_quote(number: 1, total: 100, status: "shared")
    create_quote(number: 2, total: 250.50, status: "shared")
    create_quote(number: 3, total: 175, status: "change_requested")
    create_quote(number: 4, total: 400, status: "approved", decided_at: Time.zone.parse("2026-08-01 03:00:00 UTC"))
    create_quote(number: 5, total: 600, status: "approved", decided_at: Time.zone.parse("2026-09-01 02:29:59 UTC"))
    create_quote(number: 6, total: 900, status: "approved", decided_at: Time.zone.parse("2026-08-01 02:59:59 UTC"))
    create_quote(number: 7, total: 50, status: "draft")
    create_quote(number: 8, total: 700, status: "completed", decided_at: Time.zone.parse("2026-08-10 12:00:00 UTC"))
    create_quote(number: 9, total: 800, status: "cancelled", decided_at: Time.zone.parse("2026-08-20 12:00:00 UTC"))
    create_other_professional_quote(total: 1200, status: "shared")

    result = described_class.new.call(scope:, now:)

    expect(result).to have_attributes(
      awaiting_response_count: 2,
      awaiting_response_total_amount: BigDecimal("350.50"),
      changes_requested_count: 1,
      approved_this_month_count: 4,
      approved_this_month_total_amount: BigDecimal("2500.00")
    )
  end

  it "returns zero counts and amounts for an empty scope" do
    result = described_class.new.call(scope:, now:)

    expect(result).to have_attributes(
      awaiting_response_count: 0,
      awaiting_response_total_amount: BigDecimal(0),
      changes_requested_count: 0,
      approved_this_month_count: 0,
      approved_this_month_total_amount: BigDecimal(0)
    )
  end

  private

  def create_quote(number:, total:, status:, decided_at: nil, owner: profile, phone_suffix: number)
    customer = owner.customers.create!(
      name: "Cliente #{number}",
      whatsapp_e164: "+554799999#{phone_suffix.to_i.to_s.rjust(4, "0")}"
    )
    quote = owner.quotes.create!(
      customer:,
      quote_number: number,
      customer_name: customer.name,
      customer_phone_e164: customer.whatsapp_e164,
      service_description: "Serviço #{number}",
      status: "draft",
      discount_amount: 0,
      quote_items: [
        QuoteItem.new(
          description: "Serviço",
          quantity: 1,
          unit: "serviço",
          unit_price: total,
          sort_order: 0
        )
      ]
    )
    return quote if status == "draft"

    quote.update_columns(
      status:,
      share_token_hash: Digest::SHA256.hexdigest("summary-#{owner.id}-#{number}"),
      share_token_ciphertext: "test-token",
      shared_at: now - 1.day,
      customer_decided_at: decided_at,
      updated_at: now
    )
    quote
  end

  def create_other_professional_quote(total:, status:)
    other_account = UserAccount.create!(
      phone_e164: "+5547999993102",
      role: "professional",
      status: "active"
    )
    other_profile = ProfessionalProfile.create!(user_account: other_account, display_name: "Outra profissional")
    create_quote(number: 1, total:, status:, owner: other_profile, phone_suffix: 99)
  end
end
