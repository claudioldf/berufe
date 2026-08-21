# frozen_string_literal: true

class ProfessionalQuoteSerializer
  def initialize(quote)
    @quote = quote
  end

  def as_json(*)
    {
      id: quote.id,
      quote_number: quote.quote_number,
      revision: quote.lock_version,
      customer: {
        id: quote.customer_id,
        name: quote.customer_name,
        whatsapp_e164: quote.customer_phone_e164,
        email: quote.customer_email
      },
      customer_name: quote.customer_name,
      customer_phone_e164: quote.customer_phone_e164,
      customer_email: quote.customer_email,
      service_description: quote.service_description,
      service_address: quote.service_address,
      scheduled_on: quote.scheduled_on&.iso8601,
      valid_until: quote.valid_until&.iso8601,
      notes: quote.notes,
      status: quote.status,
      subtotal_amount: money(quote.subtotal_amount),
      discount_amount: money(quote.discount_amount),
      total_amount: money(quote.total_amount),
      shared_at: quote.shared_at&.iso8601,
      customer_decided_at: quote.customer_decided_at&.iso8601,
      customer_decision_message: quote.customer_decision_message,
      change_requests: quote.quote_change_requests.map do |request|
        {
          id: request.id,
          revision: request.requested_revision,
          message: request.message,
          requested_at: request.requested_at.iso8601
        }
      end,
      service_job: serialized_service_job,
      created_at: quote.created_at.iso8601,
      updated_at: quote.updated_at.iso8601,
      items: quote.quote_items.map do |item|
        {
          id: item.id,
          description: item.description,
          quantity: decimal(item.quantity),
          unit: item.unit,
          unit_price: money(item.unit_price),
          line_total: money(item.line_total),
          sort_order: item.sort_order
        }
      end
    }
  end

  private

  attr_reader :quote

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
      id: job.id,
      status: job.status,
      completion_requested_at: job.completion_requested_at&.iso8601,
      completion_issue_message: job.completion_issue_message,
      completed_at: job.completed_at&.iso8601,
      cancelled_at: job.cancelled_at&.iso8601,
      recommendation_request_status: job.customer_recommendation_request&.status
    }
  end
end
