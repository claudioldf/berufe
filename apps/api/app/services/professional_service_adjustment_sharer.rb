# frozen_string_literal: true

class ProfessionalServiceAdjustmentSharer
  class Unavailable < StandardError; end
  class InvalidMethod < StandardError; end

  METHODS = %w[copy whatsapp].freeze
  Result = Data.define(:adjustment, :share_url, :whatsapp_url)

  def call(adjustment:, method:, now: Time.current)
    raise InvalidMethod unless method.to_s.in?(METHODS)

    token = nil
    service_job = adjustment.service_job
    ApplicationRecord.transaction do
      service_job.lock!
      adjustment.lock!
      raise Unavailable unless adjustment.editable?
      raise Unavailable unless ProfessionalProfile.publicly_eligible.exists?(id: service_job.professional.id)

      quote = service_job.quote
      token = QuoteShareToken.decrypt(quote.share_token_ciphertext)
      raise Unavailable unless token

      if adjustment.awaiting_response?
        adjustment.update_columns(shared_at: now, updated_at: now)
      else
        adjustment.update!(
          status: "awaiting_response",
          shared_at: now,
          customer_decided_at: nil,
          customer_decision_message: nil,
          terms_accepted_at: nil,
          accepted_revision: nil,
          accepted_customer_name: nil,
          accepted_customer_phone_e164: nil,
          accepted_customer_email: nil
        )
      end
    end

    share_url = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/orcamento/#{token}#ajuste-#{adjustment.id}"
    message = "Olá! Enviei o ajuste ##{adjustment.adjustment_number} do serviço para sua análise: #{share_url}"
    phone = adjustment.service_job.quote.customer_phone_e164.delete_prefix("+")
    Result.new(
      adjustment: adjustment.reload,
      share_url:,
      whatsapp_url: "https://wa.me/#{phone}?#{URI.encode_www_form(text: message)}"
    )
  end
end
