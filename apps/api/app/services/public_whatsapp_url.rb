# frozen_string_literal: true

require "uri"

class PublicWhatsappUrl
  class InvalidContact < StandardError; end

  HOST = "wa.me"
  SERVICE_MESSAGE = "Olá! Vi seu perfil na Berufe para %{service}."
  GENERIC_MESSAGE = "Olá! Vi seu perfil na Berufe."

  def self.call(phone_e164:, service_name:)
    raise InvalidContact unless phone_e164.to_s.match?(UserAccount::BRAZILIAN_MOBILE_PATTERN)

    URI::HTTPS.build(
      host: HOST,
      path: "/#{phone_e164.delete_prefix("+")}",
      query: URI.encode_www_form(
        text: service_name.present? ? format(SERVICE_MESSAGE, service: service_name) : GENERIC_MESSAGE
      )
    ).to_s
  end
end
