# frozen_string_literal: true

class ProfessionalQuoteSharer
  class Unavailable < StandardError; end
  class InvalidMethod < StandardError; end

  METHODS = %w[copy whatsapp].freeze
  Result = Data.define(:quote, :share_url, :whatsapp_url)

  def call(quote:, method:, now: Time.current)
    raise InvalidMethod unless method.to_s.in?(METHODS)

    token = QuoteShareToken.issue(quote.id)
    token_digest = QuoteShareToken.digest(token)
    share_url = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/orcamento/#{token}"

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

      ProfessionalDailyMetric.increment_quote_shares!(
        professional_id: quote.professional_id,
        occurred_at: now
      )
    end

    Result.new(
      quote: quote.reload,
      share_url:,
      whatsapp_url: whatsapp_url(share_url:, quote_number: quote.quote_number)
    )
  end

  private

  def publicly_eligible?(profile_id)
    ProfessionalProfile.publicly_eligible.exists?(id: profile_id)
  end

  def whatsapp_url(share_url:, quote_number:)
    message = "Olá! Segue o orçamento ##{quote_number} pela Berufe: #{share_url}"
    "https://wa.me/?#{URI.encode_www_form(text: message)}"
  end
end
