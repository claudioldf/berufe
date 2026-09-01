# frozen_string_literal: true

class ProfessionalServiceJobCompleter
  class Unavailable < StandardError; end

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize
      @field_errors = {request_recommendation: ["deve ser verdadeiro ou falso"]}
      super("request_recommendation must be a boolean")
    end
  end

  Result = Data.define(:service_job, :share_url, :whatsapp_url)

  def initialize(
    recommendation_request_creator: CustomerRecommendationRequestCreator.new,
    recommendation_requester: ProfessionalServiceJobRecommendationRequester.new,
    delivery_job: CustomerRecommendationRequestDeliveryJob
  )
    @recommendation_request_creator = recommendation_request_creator
    @recommendation_requester = recommendation_requester
    @delivery_job = delivery_job
  end

  def call(service_job:, request_recommendation:, now: Time.current)
    unless request_recommendation == true || request_recommendation == false
      raise Invalid
    end

    recommendation_request = nil
    service_job.with_lock do
      raise Unavailable if service_job.completed? || service_job.cancelled?

      quote = service_job.quote
      quote.lock!
      raise Unavailable unless quote.approved?

      service_job.update!(status: "completed", completed_at: now)
      quote.update!(status: "completed")
      if request_recommendation
        recommendation_request = @recommendation_request_creator.call(service_job:, now:)
      end
    end

    share_url = nil
    whatsapp_url = nil
    if recommendation_request&.email_channel?
      @delivery_job.perform_later(recommendation_request.id)
    elsif recommendation_request&.whatsapp_channel?
      handoff = @recommendation_requester.call(service_job:, now:)
      share_url = handoff.share_url
      whatsapp_url = handoff.whatsapp_url
    end

    Result.new(service_job: service_job.reload, share_url:, whatsapp_url:)
  end
end
