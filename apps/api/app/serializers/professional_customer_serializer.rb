# frozen_string_literal: true

class ProfessionalCustomerSerializer
  NOT_PROVIDED = Object.new.freeze

  def initialize(customer, quote_count: NOT_PROVIDED, last_quote_at: NOT_PROVIDED)
    @customer = customer
    @quote_count = quote_count
    @last_quote_at = last_quote_at
  end

  def as_json(*)
    {
      id: customer.id,
      name: customer.name,
      whatsapp_e164: customer.whatsapp_e164,
      email: customer.email,
      email_verified: customer.email_verified_at.present?,
      quote_count: quote_count,
      last_quote_at: last_quote_at
    }
  end

  private

  attr_reader :customer

  def quote_count
    return customer.quotes.count if @quote_count.equal?(NOT_PROVIDED)

    @quote_count.to_i
  end

  def last_quote_at
    return customer.quotes.maximum(:updated_at) if @last_quote_at.equal?(NOT_PROVIDED)

    @last_quote_at
  end
end
