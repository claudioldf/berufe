# frozen_string_literal: true

class ProfessionalQuoteSerializer
  def initialize(quote)
    @quote = quote
  end

  def as_json(*)
    {
      id: quote.id,
      quote_number: quote.quote_number,
      customer_name: quote.customer_name,
      service_description: quote.service_description,
      valid_until: quote.valid_until&.iso8601,
      notes: quote.notes,
      status: quote.status,
      subtotal_amount: money(quote.subtotal_amount),
      discount_amount: money(quote.discount_amount),
      total_amount: money(quote.total_amount),
      shared_at: quote.shared_at&.iso8601,
      created_at: quote.created_at.iso8601,
      updated_at: quote.updated_at.iso8601,
      items: quote.quote_items.map do |item|
        {
          id: item.id,
          description: item.description,
          quantity: decimal(item.quantity),
          unit: item.unit,
          unit_price: money(item.unit_price),
          line_total: money(item.line_total),
          sort_order: item.sort_order
        }
      end
    }
  end

  private

  attr_reader :quote

  def money(value)
    format("%.2f", value)
  end

  def decimal(value)
    value.to_d.to_s("F").sub(/\.?0+\z/, "")
  end
end
