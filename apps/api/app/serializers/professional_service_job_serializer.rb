# frozen_string_literal: true

class ProfessionalServiceJobSerializer
  def initialize(service_job)
    @service_job = service_job
  end

  def as_json(*)
    quote = service_job.quote
    {
      id: service_job.id,
      status: service_job.status,
      quote: {
        id: quote.id,
        quote_number: quote.quote_number,
        customer_name: quote.customer_name,
        customer_phone_e164: quote.customer_phone_e164,
        customer_email: quote.customer_email,
        service_description: quote.service_description,
        service_address: quote.service_address,
        scheduled_on: quote.scheduled_on&.iso8601,
        total_amount: format("%.2f", quote.total_amount)
      },
      completion_requested_at: service_job.completion_requested_at&.iso8601,
      completion_issue_at: service_job.completion_issue_at&.iso8601,
      completion_issue_message: service_job.completion_issue_message,
      completed_at: service_job.completed_at&.iso8601,
      cancelled_at: service_job.cancelled_at&.iso8601,
      cancellation_reason: service_job.cancellation_reason,
      recommendation_request_status: service_job.customer_recommendation_request&.status,
      created_at: service_job.created_at.iso8601,
      updated_at: service_job.updated_at.iso8601
    }
  end

  private

  attr_reader :service_job
end
