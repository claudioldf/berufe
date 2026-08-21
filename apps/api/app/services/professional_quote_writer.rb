# frozen_string_literal: true

class ProfessionalQuoteWriter
  class Locked < StandardError; end
  class Stale < StandardError; end

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional quote")
    end
  end

  QUOTE_FIELDS = %i[
    service_description service_address scheduled_on discount_amount valid_until notes
  ].freeze
  ITEM_FIELDS = %i[description quantity unit unit_price].freeze

  def call(profile:, attributes:, quote: nil)
    created = quote.nil?
    expected_version = attributes[:revision]

    ApplicationRecord.transaction do
      if created
        profile.lock!
        quote = profile.quotes.new(quote_number: next_quote_number(profile))
      else
        raise ActiveRecord::RecordNotFound unless quote.professional_id == profile.id

        quote.lock!
        raise Locked if quote.approved?
        raise Stale if expected_version.nil? || expected_version.to_i != quote.lock_version

        quote.quote_items.destroy_all
      end

      customer = resolve_customer!(profile:, attributes: attributes.fetch(:customer, {}))
      quote.assign_attributes(attributes.slice(*QUOTE_FIELDS))
      quote.assign_attributes(
        customer:,
        customer_name: customer.name,
        customer_phone_e164: customer.whatsapp_e164,
        customer_email: customer.email
      )
      Array(attributes[:items]).each_with_index do |item_attributes, sort_order|
        quote.quote_items.build(
          item_attributes.to_h.symbolize_keys.slice(*ITEM_FIELDS).merge(sort_order:)
        )
      end
      quote.save!
      if created
        ProfessionalDailyActivity.increment!(
          professional_id: profile.id,
          counter: :quotes_created
        )
      end
    end

    quote.reload
  rescue ActiveRecord::RecordInvalid => error
    errors = error.record.errors.to_hash(true)
    errors = errors.transform_keys { |key| "customer.#{key}" } if error.record.is_a?(Customer)
    raise Invalid.new(errors)
  end

  private

  def next_quote_number(profile)
    profile.quotes.maximum(:quote_number).to_i + 1
  end

  def resolve_customer!(profile:, attributes:)
    customer_attributes = attributes.to_h.symbolize_keys.slice(:name, :whatsapp_e164, :email)
    customer = if attributes[:id].present?
      profile.customers.lock.find(attributes[:id])
    else
      profile.customers.new
    end

    previous_email = customer.email
    customer.assign_attributes(customer_attributes)
    normalized_email = customer.email.to_s.strip.downcase.presence
    customer.email_verified_at = nil if customer.persisted? && normalized_email != previous_email
    customer.save!
    customer
  end
end
