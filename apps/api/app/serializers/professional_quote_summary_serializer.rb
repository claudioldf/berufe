# frozen_string_literal: true

class ProfessionalQuoteSummarySerializer
  def initialize(quote)
    @quote = quote
  end

  def as_json(*)
    {
      id: quote.id,
      quote_number: quote.quote_number,
      revision: quote.lock_version,
      customer_name: quote.customer_name,
      service_description: quote.service_description,
      total_amount: format("%.2f", quote.total_amount),
      status: quote.status,
      service_job_status: quote.service_job&.status,
      created_at: quote.created_at.iso8601
    }
  end

  private

  attr_reader :quote
end
