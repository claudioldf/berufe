# frozen_string_literal: true

class ProfessionalRecommendationUnhider
  def call(recommendation:)
    recommendation.update!(hidden_by_professional_at: nil, hidden_reason: nil)
    recommendation
  end
end
