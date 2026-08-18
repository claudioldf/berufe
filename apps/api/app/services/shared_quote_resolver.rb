# frozen_string_literal: true

class SharedQuoteResolver
  class NotFound < StandardError; end

  Result = Data.define(:quote, :professional)

  def call(token:)
    raise NotFound unless QuoteShareToken.valid?(token)

    quote = Quote
      .includes(:quote_items)
      .find_by(status: "shared", share_token_hash: QuoteShareToken.digest(token))
    raise NotFound unless quote && QuoteShareToken.matches?(quote_id: quote.id, token:)

    professional = ProfessionalProfile
      .publicly_eligible
      .includes(
        :published_photo,
        :verification_requests,
        published_revision: {professional_profile_services: :service}
      )
      .find_by(id: quote.professional_id)
    raise NotFound unless professional

    Result.new(quote:, professional:)
  end
end
