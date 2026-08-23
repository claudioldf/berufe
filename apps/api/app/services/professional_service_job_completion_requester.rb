# frozen_string_literal: true

class ProfessionalServiceJobCompletionRequester
  class Unavailable < StandardError; end

  Result = Data.define(:service_job, :whatsapp_url, :share_url)

  def call(service_job:, now: Time.current)
    service_job.with_lock do
      raise Unavailable unless service_job.approved? || service_job.completion_issue?

      service_job.update!(
        status: "completion_requested",
        completion_requested_at: now,
        completion_issue_at: nil,
        completion_issue_message: nil
      )
    end

    quote = service_job.quote
    token = QuoteShareToken.decrypt(quote.share_token_ciphertext)
    raise Unavailable unless token

    share_url = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/orcamento/#{token}"
    message = "Olá, #{quote.customer_name}! O trabalho combinado no orçamento ##{quote.quote_number} foi concluído. Confirme a conclusão por aqui: #{share_url}"
    phone = quote.customer_phone_e164.delete_prefix("+")
    Result.new(
      service_job: service_job.reload,
      share_url:,
      whatsapp_url: "https://wa.me/#{phone}?#{URI.encode_www_form(text: message)}"
    )
  end
end
