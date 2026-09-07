# frozen_string_literal: true

class ProfessionalServiceJobCanceller
  class Unavailable < StandardError; end

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid service job cancellation")
    end
  end

  def call(service_job:, reason:, acknowledge_open_adjustments: false, now: Time.current)
    normalized_reason = reason.to_s.squish.presence
    if normalized_reason&.length.to_i > 700
      raise Invalid.new(reason: ["deve ter no máximo 700 caracteres"])
    end

    service_job.with_lock do
      raise Unavailable if service_job.completed? || service_job.cancelled?

      if service_job.unresolved_adjustments? && acknowledge_open_adjustments != true
        raise Invalid.new(
          acknowledge_open_adjustments: ["confirme que os ajustes pendentes continuarão separados do total combinado"]
        )
      end

      quote = service_job.quote
      quote.lock!
      raise Unavailable unless quote.approved?

      service_job.update!(
        status: "cancelled",
        cancellation_reason: normalized_reason,
        cancelled_at: now
      )
      quote.update!(status: "cancelled")
    end
    service_job.reload
  end
end
