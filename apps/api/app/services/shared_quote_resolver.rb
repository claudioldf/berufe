# frozen_string_literal: true

class SharedQuoteResolver
  class NotFound < StandardError; end

  Result = Data.define(:quote, :professional)

  def call(token:)
    raise NotFound unless QuoteShareToken.valid?(token)

    # The digest is a keyed HMAC of a 256-bit random token, so matching it is
    # the whole authentication. A revoked quote has no digest left to match.
    quote = Quote
      .includes(:quote_items, service_job: :customer_recommendation_request)
      .where.not(status: %w[draft saved])
      .find_by(share_token_hash: QuoteShareToken.digest(token))
    raise NotFound unless quote

    professional = ProfessionalProfile
      .publicly_eligible
      .includes(
        :profile_photo,
        :verification_requests,
        published_revision: {professional_profile_services: :service}
      )
      .find_by(id: quote.professional_id)
    raise NotFound unless professional

    Result.new(quote:, professional:)
  end
end
