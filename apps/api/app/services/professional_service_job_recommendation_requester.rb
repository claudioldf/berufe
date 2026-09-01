# frozen_string_literal: true

# The WhatsApp delivery channel for a recommendation request whose quote has
# no customer email (S068). Mirrors the shape of the removed completion
# requester, but — unlike the one-shot email job — this is reusable: the
# bearer token is never nulled for the WhatsApp channel, so the professional
# can reopen the same link more than once.
class ProfessionalServiceJobRecommendationRequester
  class Unavailable < StandardError; end

  Result = Data.define(:service_job, :share_url, :whatsapp_url)

  def call(service_job:, now: Time.current)
    request = service_job.customer_recommendation_request
    raise Unavailable unless service_job.completed? && request&.whatsapp_channel?

    token = CustomerRecommendationToken.decrypt(request.token_ciphertext)
    raise Unavailable unless token

    request.update!(sent_at: request.sent_at || now)

    quote = service_job.quote
    share_url = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/recomendacao/#{token}"
    message = "Olá, #{quote.customer_name}! Poderia contar como foi o serviço #{quote.service_description.downcase}? #{share_url}"
    phone = quote.customer_phone_e164.delete_prefix("+")
    Result.new(
      service_job: service_job.reload,
      share_url:,
      whatsapp_url: "https://wa.me/#{phone}?#{URI.encode_www_form(text: message)}"
    )
  end
end
