# frozen_string_literal: true

class ProfessionalQuoteWriter
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional quote")
    end
  end

  QUOTE_FIELDS = %i[
    customer_name service_description discount_amount valid_until notes
  ].freeze
  ITEM_FIELDS = %i[description quantity unit unit_price].freeze

  def call(profile:, attributes:, quote: nil)
    created = quote.nil?

    ApplicationRecord.transaction do
      if created
        profile.lock!
        quote = profile.quotes.new(quote_number: next_quote_number(profile))
      else
        raise ActiveRecord::RecordNotFound unless quote.professional_id == profile.id

        quote.lock!
        quote.quote_items.destroy_all
      end

      quote.assign_attributes(attributes.slice(*QUOTE_FIELDS))
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
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def next_quote_number(profile)
    profile.quotes.maximum(:quote_number).to_i + 1
  end
end
