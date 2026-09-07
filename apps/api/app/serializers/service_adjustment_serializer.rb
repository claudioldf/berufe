# frozen_string_literal: true

class ServiceAdjustmentSerializer
  def initialize(adjustment, customer_facing: false)
    @adjustment = adjustment
    @customer_facing = customer_facing
  end

  def as_json(*)
    {
      id: adjustment.id,
      adjustment_number: adjustment.adjustment_number,
      revision: adjustment.lock_version,
      status: adjustment.status,
      title: adjustment.title,
      description: adjustment.description,
      schedule_impact: adjustment.schedule_impact,
      incurred_on: adjustment.incurred_on&.iso8601,
      total_amount: money(adjustment.total_amount),
      shared_at: adjustment.shared_at&.iso8601,
      customer_decided_at: adjustment.customer_decided_at&.iso8601,
      customer_decision_message: adjustment.customer_decision_message,
      terms_accepted_at: adjustment.terms_accepted_at&.iso8601,
      accepted_revision: adjustment.accepted_revision,
      items: adjustment.service_adjustment_items.map { |item| serialized_item(item) },
      change_requests: adjustment.service_adjustment_change_requests.map do |request|
        {
          requested_revision: request.requested_revision,
          message: request.message,
          requested_at: request.requested_at.iso8601
        }
      end
    }.tap do |serialized|
      next if customer_facing

      serialized[:accepted_customer] = if adjustment.accepted_revision
        {
          name: adjustment.accepted_customer_name,
          phone_e164: adjustment.accepted_customer_phone_e164,
          email: adjustment.accepted_customer_email
        }
      end
    end
  end

  private

  attr_reader :adjustment, :customer_facing

  def serialized_item(item)
    {
      id: item.id,
      kind: item.kind,
      description: item.description,
      quantity: decimal(item.quantity),
      unit: item.unit,
      unit_price: money(item.unit_price),
      line_total: money(item.line_total),
      sort_order: item.sort_order,
      receipt: serialized_receipt(item.service_adjustment_receipt)
    }
  end

  def serialized_receipt(receipt)
    return unless receipt

    {id: receipt.id, content_type: receipt.content_type}.tap do |serialized|
      serialized[:media_upload_id] = receipt.media_upload_id unless customer_facing
    end
  end

  def money(value)
    format("%.2f", value)
  end

  def decimal(value)
    value.to_d.to_s("F").sub(/\.?0+\z/, "")
  end
end
