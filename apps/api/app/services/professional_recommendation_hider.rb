# frozen_string_literal: true

# Self-serve, unmoderated hiding (S069) — the professional base cannot be
# reviewed at growth scale, so there is no admin queue here. What keeps this
# honest is disclosure, not review: PublicProfessionalProfileSerializer
# always reports how many recommendations a profile has hidden.
class ProfessionalRecommendationHider
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid recommendation hide reason")
    end
  end

  def call(recommendation:, reason:, now: Time.current)
    normalized_reason = reason.to_s.squish.presence
    if normalized_reason && normalized_reason.length > 700
      raise Invalid.new(reason: ["deve ter no máximo 700 caracteres"])
    end

    recommendation.update!(hidden_by_professional_at: now, hidden_reason: normalized_reason)
    recommendation
  end
end
