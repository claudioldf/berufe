# frozen_string_literal: true

class ProfessionalCustomerUpdater
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional customer")
    end
  end

  FIELDS = %i[name whatsapp_e164 email].freeze

  def call(customer:, attributes:)
    ApplicationRecord.transaction do
      customer.lock!
      previous_email = customer.email
      customer.assign_attributes(attributes.to_h.symbolize_keys.slice(*FIELDS))
      normalized_email = customer.email.to_s.strip.downcase.presence
      customer.email_verified_at = nil if normalized_email != previous_email
      customer.save!
    end

    customer.reload
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end
end
