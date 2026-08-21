# frozen_string_literal: true

class SharedQuoteDecisionRecorder
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid shared quote decision")
    end
  end

  class Stale < StandardError; end
  class Expired < StandardError; end
  class Unavailable < StandardError; end

  DECISIONS = {
    "approve" => "approved",
    "request_change" => "change_requested",
    "decline" => "declined"
  }.freeze

  def call(token:, decision:, revision:, terms_accepted:, message:, now: Time.current)
    result = SharedQuoteResolver.new.call(token:)
    quote = result.quote
    target_status = DECISIONS[decision.to_s]
    raise Invalid.new(decision: ["não é válida"]) unless target_status

    service_job = nil
    quote.with_lock do
      if quote.status == target_status
        service_job = quote.service_job
        next
      end

      raise Unavailable unless quote.shared?
      raise Stale if revision.nil? || revision.to_i != quote.lock_version
      validate_decision!(
        quote:,
        decision: decision.to_s,
        terms_accepted:,
        message:,
        now:
      )

      if target_status == "change_requested"
        quote.quote_change_requests.create!(
          requested_revision: revision.to_i,
          message:,
          requested_at: now
        )
      end

      quote.update!(
        status: target_status,
        customer_decided_at: now,
        customer_decision_message: message.to_s.squish.presence,
        terms_accepted_at: (decision.to_s == "approve") ? now : nil
      )
      service_job = ServiceJob.create!(quote:, status: "approved") if target_status == "approved"
    end

    SharedQuoteResolver::Result.new(quote: quote.reload, professional: result.professional).then do |resolved|
      {resolved:, service_job: service_job || quote.service_job}
    end
  end

  private

  def validate_decision!(quote:, decision:, terms_accepted:, message:, now:)
    field_errors = {}
    if decision == "approve" && terms_accepted != true
      field_errors[:terms_accepted] = ["deve ser aceito para aprovar"]
    end
    if decision == "request_change" && message.to_s.squish.blank?
      field_errors[:message] = ["explique o que precisa ser alterado"]
    elsif message.to_s.squish.length > 700
      field_errors[:message] = ["deve ter no máximo 700 caracteres"]
    end
    raise Invalid.new(field_errors) if field_errors.any?

    product_date = now.in_time_zone(ProfessionalDailyActivity::PRODUCT_TIME_ZONE).to_date
    raise Expired if decision == "approve" && quote.valid_until && quote.valid_until < product_date
  end
end
