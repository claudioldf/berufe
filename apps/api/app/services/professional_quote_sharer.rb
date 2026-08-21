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

      token = quote.draft? ? issue_first_token!(quote, now) : reactivate_token!(quote, now)
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
      whatsapp_url: whatsapp_url(
        share_url:,
        quote_number: quote.quote_number,
        phone_e164: quote.customer_phone_e164
      )
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
  def reactivate_token!(quote, now)
    return if quote.approved?

    token = QuoteShareToken.decrypt(quote.share_token_ciphertext)
    return unless token

    if quote.change_requested? || quote.declined?
      quote.update!(
        status: "shared",
        customer_decided_at: nil,
        customer_decision_message: nil,
        terms_accepted_at: nil,
        shared_at: now
      )
    end
    token
  end

  def publicly_eligible?(profile_id)
    ProfessionalProfile.publicly_eligible.exists?(id: profile_id)
  end

  def whatsapp_url(share_url:, quote_number:, phone_e164:)
    message = "Olá! Segue o orçamento ##{quote_number} pela Berufe: #{share_url}"
    phone = phone_e164.delete_prefix("+")
    "https://wa.me/#{phone}?#{URI.encode_www_form(text: message)}"
  end
end
