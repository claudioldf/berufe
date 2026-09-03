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
        revision: quote.lock_version,
        status: quote.status,
        customer_name: quote.customer_name,
        service_description: quote.service_description,
        service_address: quote.service_address,
        scheduled_on: quote.scheduled_on&.iso8601,
        valid_until: quote.valid_until&.iso8601,
        notes: quote.notes,
        pricing_mode: quote.pricing_mode,
        items_visible_to_customer: quote.items_visible_to_customer,
        subtotal_amount: money(quote.subtotal_amount),
        discount_amount: money(quote.discount_amount),
        total_amount: money(quote.total_amount),
        customer_decision_message: quote.customer_decision_message,
        service_job: serialized_service_job,
        items: serialized_items,
        materials: quote.quote_materials.map do |material|
          {
            description: material.description,
            quantity: decimal(material.quantity),
            unit: material.unit,
            sort_order: material.sort_order
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
    photo = professional.profile_photo
    return unless photo && photo.deleted_at.nil?

    PublicProfilePhotoImageUrl.call(photo)
  end

  def money(value)
    format("%.2f", value)
  end

  def decimal(value)
    value.to_d.to_s("F").sub(/\.?0+\z/, "")
  end

  def serialized_service_job
    job = quote.service_job
    return unless job

    {
      status: job.status,
      completed_at: job.completed_at&.iso8601
    }
  end

  # In `itemized` mode the items are the customer-facing content. In
  # `lump_sum` mode they are the professional's private calculation and are
  # sent to the customer only as a priceless scope list, and only when the
  # owner opted in — never with a unit price or line total.
  def serialized_items
    return quote.quote_items.map { |item| priced_item(item) } if quote.itemized?
    return [] unless quote.items_visible_to_customer

    quote.quote_items.map { |item| scoped_item(item) }
  end

  def priced_item(item)
    {
      description: item.description,
      quantity: decimal(item.quantity),
      unit: item.unit,
      unit_price: money(item.unit_price),
      line_total: money(item.line_total),
      sort_order: item.sort_order
    }
  end

  def scoped_item(item)
    {
      description: item.description,
      quantity: decimal(item.quantity),
      unit: item.unit,
      unit_price: nil,
      line_total: nil,
      sort_order: item.sort_order
    }
  end
end
