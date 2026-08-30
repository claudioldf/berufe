# frozen_string_literal: true

class ProfessionalServiceJobCompleter
  class Unavailable < StandardError; end

  def call(service_job:, now: Time.current)
    service_job.with_lock do
      raise Unavailable if service_job.completed? || service_job.cancelled?

      service_job.update!(
        status: "completed",
        completed_at: now,
        completion_confirmed_by: "professional"
      )
    end
    service_job.reload
  end
end
