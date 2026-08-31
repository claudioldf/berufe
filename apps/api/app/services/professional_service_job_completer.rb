# frozen_string_literal: true

class ProfessionalServiceJobCompleter
  class Unavailable < StandardError; end

  def initialize(recommendation_request_creator: CustomerRecommendationRequestCreator.new)
    @recommendation_request_creator = recommendation_request_creator
  end

  def call(service_job:, now: Time.current)
    service_job.with_lock do
      raise Unavailable if service_job.completed? || service_job.cancelled?

      service_job.update!(status: "completed", completed_at: now)
      @recommendation_request_creator.call(service_job:, now:)
    end
    service_job.reload
  end
end
