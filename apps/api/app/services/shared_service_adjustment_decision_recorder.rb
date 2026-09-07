# frozen_string_literal: true

class SharedServiceAdjustmentDecisionRecorder
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid shared service adjustment decision")
    end
  end

  class Stale < StandardError; end
  class Unavailable < StandardError; end

  DECISIONS = {
    "approve" => "approved",
    "request_change" => "change_requested",
    "decline" => "declined"
  }.freeze

  def initialize(notifier: ProfessionalNotificationCreator.new)
    @notifier = notifier
  end

  def call(token:, adjustment_id:, decision:, revision:, terms_accepted:, message:, now: Time.current)
    resolved = SharedQuoteResolver.new.call(token:)
    service_job = resolved.quote.service_job
    raise SharedQuoteResolver::NotFound unless service_job

    adjustment = service_job.service_adjustments.find_by(id: adjustment_id)
    raise SharedQuoteResolver::NotFound unless adjustment

    target_status = DECISIONS[decision.to_s]
    raise Invalid.new(decision: ["não é válida"]) unless target_status

    service_job.with_lock do
      adjustment.lock!
      service_job.service_adjustments.reload
      next if adjustment.status == target_status

      raise Unavailable unless adjustment.awaiting_response?
      raise Stale if revision.nil? || revision.to_i != adjustment.lock_version
      validate_decision!(decision: decision.to_s, terms_accepted:, message:)
      validate_agreed_total!(service_job:, adjustment:) if target_status == "approved"

      if target_status == "change_requested"
        adjustment.service_adjustment_change_requests.create!(
          requested_revision: revision.to_i,
          message:,
          requested_at: now
        )
      end

      quote = service_job.quote
      approved = target_status == "approved"
      adjustment.update!(
        status: target_status,
        customer_decided_at: now,
        customer_decision_message: message.to_s.squish.presence,
        terms_accepted_at: approved ? now : nil,
        accepted_revision: approved ? revision.to_i : nil,
        accepted_customer_name: approved ? quote.customer_name : nil,
        accepted_customer_phone_e164: approved ? quote.customer_phone_e164 : nil,
        accepted_customer_email: approved ? quote.customer_email : nil
      )
      @notifier.call(
        recipient: service_job.professional.user_account,
        notification_type: {
          "change_requested" => "service_adjustment_change_requested",
          "approved" => "service_adjustment_approved",
          "declined" => "service_adjustment_declined"
        }.fetch(target_status),
        route_params: {service_job_id: service_job.id},
        idempotency_key: "service-adjustment:#{adjustment.id}:revision:#{revision.to_i}:#{target_status}",
        occurred_at: now
      )
    end

    SharedQuoteResolver.new.call(token:)
  end

  private

  def validate_decision!(decision:, terms_accepted:, message:)
    errors = {}
    errors[:terms_accepted] = ["deve ser aceito para aprovar"] if decision == "approve" && terms_accepted != true
    if decision == "request_change" && message.to_s.squish.blank?
      errors[:message] = ["explique o que precisa ser alterado"]
    elsif message.to_s.squish.length > 700
      errors[:message] = ["deve ter no máximo 700 caracteres"]
    end
    raise Invalid.new(errors) if errors.any?
  end

  def validate_agreed_total!(service_job:, adjustment:)
    agreed_total = service_job.quote.total_amount +
      service_job.service_adjustments.select(&:approved?).sum(&:total_amount) +
      adjustment.total_amount
    return unless agreed_total.negative?

    raise Invalid.new(base: ["o total combinado do serviço não pode ficar negativo"])
  end
end
