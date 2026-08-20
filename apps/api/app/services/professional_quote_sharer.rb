# frozen_string_literal: true

class ProfessionalQuoteSharer
  class Unavailable < StandardError; end
  class InvalidMethod < StandardError; end

  METHODS = %w[copy whatsapp].freeze
  Result = Data.define(:quote, :share_url, :whatsapp_url)

  def call(quote:, method:, now: Time.current)
    raise InvalidMethod unless method.to_s.in?(METHODS)

    token = nil
    quote.with_lock do
      raise Unavailable unless publicly_eligible?(quote.professional_id)

      token = quote.draft? ? issue_first_token!(quote, now) : active_token(quote)
      raise Unavailable unless token

      ProfessionalDailyMetric.increment_quote_shares!(
        professional_id: quote.professional_id,
        occurred_at: now
      )
    end

    share_url = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/orcamento/#{token}"
    Result.new(
      quote: quote.reload,
      share_url:,
      whatsapp_url: whatsapp_url(share_url:, quote_number: quote.quote_number)
    )
  end

  private

  def issue_first_token!(quote, now)
    token = QuoteShareToken.issue
    quote.update!(
      status: "shared",
      share_token_hash: QuoteShareToken.digest(token),
      share_token_ciphertext: QuoteShareToken.encrypt(token),
      shared_at: now
    )
    token
  end

  # S051: re-sharing reuses the link the customer may already hold.
  def active_token(quote)
    QuoteShareToken.decrypt(quote.share_token_ciphertext)
  end

  def publicly_eligible?(profile_id)
    ProfessionalProfile.publicly_eligible.exists?(id: profile_id)
  end

  def whatsapp_url(share_url:, quote_number:)
    message = "Olá! Segue o orçamento ##{quote_number} pela Berufe: #{share_url}"
    "https://wa.me/?#{URI.encode_www_form(text: message)}"
  end
end
