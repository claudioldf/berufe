# frozen_string_literal: true

class SharedQuoteSerializer
  def initialize(quote:, professional:)
    @quote = quote
    @professional = professional
  end

  def as_json(*)
    {
      quote: {
        quote_number: quote.quote_number,
        customer_name: quote.customer_name,
        service_description: quote.service_description,
        valid_until: quote.valid_until&.iso8601,
        notes: quote.notes,
        subtotal_amount: money(quote.subtotal_amount),
        discount_amount: money(quote.discount_amount),
        total_amount: money(quote.total_amount),
        items: quote.quote_items.map do |item|
          {
            description: item.description,
            quantity: decimal(item.quantity),
            unit: item.unit,
            unit_price: money(item.unit_price),
            line_total: money(item.line_total),
            sort_order: item.sort_order
          }
        end
      },
      professional: {
        display_name: professional.published_revision.display_name,
        photo_url: public_photo_url,
        primary_service: primary_service&.name,
        identity_verified: PublicVerificationSerializer.new(professional).as_json[:identity].present?
      }
    }
  end

  private

  attr_reader :quote, :professional

  def primary_service
    selections = professional.published_revision.professional_profile_services
    (selections.find(&:is_primary?) || selections.first)&.service
  end

  def public_photo_url
    photo = professional.published_photo
    return unless photo&.approved? && photo.public_key.present?

    PublicProfilePhotoImageUrl.call(photo)
  end

  def money(value)
    format("%.2f", value)
  end

  def decimal(value)
    value.to_d.to_s("F").sub(/\.?0+\z/, "")
  end
end
