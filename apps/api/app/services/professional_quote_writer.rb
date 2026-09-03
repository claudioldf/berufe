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
    service_description service_address scheduled_on pricing_mode lump_sum_amount
    discount_amount items_visible_to_customer valid_until notes
  ].freeze
  WRITABLE_STATUSES = %w[draft saved].freeze
  ITEM_FIELDS = %i[description quantity unit unit_price].freeze
  MATERIAL_FIELDS = %i[description quantity unit].freeze

  def call(profile:, attributes:, quote: nil)
    created = quote.nil?
    expected_version = attributes[:revision]
    requested_status = attributes[:status].to_s.presence
    if requested_status && !requested_status.in?(WRITABLE_STATUSES)
      raise Invalid.new(status: ["não é válido"])
    end

    ApplicationRecord.transaction do
      if created
        profile.lock!
        quote = profile.quotes.new(quote_number: next_quote_number(profile))
      else
        raise ActiveRecord::RecordNotFound unless quote.professional_id == profile.id

        quote.lock!
        raise Locked if quote.locked_for_editing?
        raise Stale if expected_version.nil? || expected_version.to_i != quote.lock_version

        quote.quote_items.destroy_all
        quote.quote_materials.destroy_all
      end

      if created || quote.draft? || quote.saved?
        quote.status = requested_status if requested_status
      end
      quote.assign_attributes(attributes.slice(*QUOTE_FIELDS))
      if quote.draft? && !complete_customer_attributes?(attributes.fetch(:customer, {}))
        assign_draft_customer!(quote:, profile:, attributes: attributes.fetch(:customer, {}))
      else
        customer = resolve_customer!(profile:, attributes: attributes.fetch(:customer, {}))
        quote.assign_attributes(
          customer:,
          customer_name: customer.name,
          customer_phone_e164: customer.whatsapp_e164,
          customer_email: customer.email
        )
      end
      Array(attributes[:items]).each_with_index do |item_attributes, sort_order|
        quote.quote_items.build(
          item_attributes.to_h.symbolize_keys.slice(*ITEM_FIELDS).merge(sort_order:)
        )
      end
      Array(attributes[:materials]).each_with_index do |material_attributes, sort_order|
        quote.quote_materials.build(
          material_attributes.to_h.symbolize_keys.slice(*MATERIAL_FIELDS).merge(sort_order:)
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

  def assign_draft_customer!(quote:, profile:, attributes:)
    customer_attributes = attributes.to_h.symbolize_keys
    customer = if customer_attributes[:id].present?
      profile.customers.find(customer_attributes[:id])
    end
    quote.assign_attributes(
      customer:,
      customer_name: customer_attributes[:name].to_s,
      customer_phone_e164: customer_attributes[:whatsapp_e164].to_s,
      customer_email: customer_attributes[:email].to_s.presence
    )
  end

  def complete_customer_attributes?(attributes)
    customer_attributes = attributes.to_h.symbolize_keys
    return false if customer_attributes[:name].blank?
    return false if customer_attributes[:whatsapp_e164].blank?
    return false unless customer_attributes[:email].blank? ||
      URI::MailTo::EMAIL_REGEXP.match?(customer_attributes[:email].to_s)

    BrazilianPhoneNumber.normalize(customer_attributes[:whatsapp_e164])
    true
  rescue BrazilianPhoneNumber::Invalid
    false
  end
end
