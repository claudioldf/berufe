# frozen_string_literal: true

class ProfessionalQuoteSharer
  class Unavailable < StandardError; end

  Result = Data.define(:quote, :share_url)

  def call(quote:, now: Time.current)
    token = QuoteShareToken.issue(quote.id)
    token_digest = QuoteShareToken.digest(token)

    quote.with_lock do
      raise Unavailable unless publicly_eligible?(quote.professional_id)

      if quote.draft?
        quote.update!(
          status: "shared",
          share_token_hash: token_digest,
          shared_at: now
        )
      elsif quote.share_token_hash != token_digest
        raise Unavailable
      end
    end

    Result.new(
      quote: quote.reload,
      share_url: "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/orcamento/#{token}"
    )
  end

  private

  def publicly_eligible?(profile_id)
    ProfessionalProfile.publicly_eligible.exists?(id: profile_id)
  end
end
