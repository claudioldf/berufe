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
      customer_feedback_message: service_job.customer_feedback_message,
      completed_at: service_job.completed_at&.iso8601,
      cancelled_at: service_job.cancelled_at&.iso8601,
      cancellation_reason: service_job.cancellation_reason,
      recommendation: serialized_recommendation,
      created_at: service_job.created_at.iso8601,
      updated_at: service_job.updated_at.iso8601
    }
  end

  private

  attr_reader :service_job

  def serialized_recommendation
    request = service_job.customer_recommendation_request
    return unless request

    {
      status: request.status,
      delivery_channel: request.delivery_channel,
      sent_at: request.sent_at&.iso8601
    }
  end
end
