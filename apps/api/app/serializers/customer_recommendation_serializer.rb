# frozen_string_literal: true

class CustomerRecommendationSerializer
  def initialize(recommendation)
    @recommendation = recommendation
  end

  def as_json(*)
    {
      id: recommendation.id,
      display_name: recommendation.display_name,
      recommendation_text: recommendation.recommendation_text,
      submitted_at: recommendation.submitted_at.iso8601,
      verification_label: "Link enviado por e-mail"
    }
  end

  private

  attr_reader :recommendation
end
