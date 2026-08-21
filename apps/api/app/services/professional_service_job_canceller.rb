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

  def call(service_job:, reason:, now: Time.current)
    normalized_reason = reason.to_s.squish.presence
    if normalized_reason&.length.to_i > 700
      raise Invalid.new(reason: ["deve ter no máximo 700 caracteres"])
    end

    service_job.with_lock do
      raise Unavailable if service_job.completed? || service_job.cancelled?

      service_job.update!(
        status: "cancelled",
        cancellation_reason: normalized_reason,
        cancelled_at: now
      )
    end
    service_job.reload
  end
end
