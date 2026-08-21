# frozen_string_literal: true

class CustomerRecommendationResolver
  class NotFound < StandardError; end

  def call(token:, now: Time.current)
    raise NotFound unless CustomerRecommendationToken.valid?(token)

    request = CustomerRecommendationRequest
      .includes(service_job: {quote: %i[customer professional]})
      .find_by(token_hash: CustomerRecommendationToken.digest(token))
    raise NotFound unless request&.sent_at?

    unless request.open_at?(now)
      request.update_columns(status: "expired", updated_at: now) if request.status == "open" && request.expires_at <= now
      raise NotFound
    end
    raise NotFound unless request.service_job.completed?

    request
  end
end
