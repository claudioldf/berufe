# frozen_string_literal: true

class CustomerRecommendationPublicationWithdrawer
  class NotFound < StandardError; end

  def call(profile_slug:, email:, now: Time.current)
    fingerprint = CustomerEmailFingerprint.call(email.to_s.strip.downcase)
    recommendation = CustomerRecommendation
      .publication_authorized
      .joins(service_job: {quote: :professional})
      .find_by(
        email_fingerprint: fingerprint,
        professional_profiles: {public_slug: profile_slug.to_s.strip.downcase}
      )
    raise NotFound unless recommendation

    recommendation.with_lock do
      recommendation.update!(publication_withdrawn_at: now) unless recommendation.publication_withdrawn_at
    end
    recommendation
  end
end
