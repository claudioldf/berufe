# frozen_string_literal: true

class ProfessionalRecommendationSerializer
  def initialize(recommendation)
    @recommendation = recommendation
  end

  def as_json(*)
    quote = recommendation.service_job.quote
    {
      id: recommendation.id,
      display_name: recommendation.display_name,
      recommendation_text: recommendation.recommendation_text,
      delivery_channel: recommendation.delivery_channel,
      submitted_at: recommendation.submitted_at.iso8601,
      customer_name: quote.customer_name,
      service_description: quote.service_description,
      hidden_at: recommendation.hidden_by_professional_at&.iso8601,
      hidden_reason: recommendation.hidden_reason
    }
  end

  private

  attr_reader :recommendation
end
