# frozen_string_literal: true

class ProfessionalCustomerCandidateSerializer
  def initialize(customer)
    @customer = customer
  end

  def as_json(*)
    {
      id: customer.id,
      name: customer.name,
      whatsapp_e164: customer.whatsapp_e164,
      email: customer.email,
      email_verified: customer.email_verified_at.present?
    }
  end

  private

  attr_reader :customer
end
