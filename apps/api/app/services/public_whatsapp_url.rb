# frozen_string_literal: true

require "uri"

class PublicWhatsappUrl
  class InvalidContact < StandardError; end

  HOST = "wa.me"
  MESSAGE = "Olá! Vi seu perfil na Berufe para %{service}."

  def self.call(phone_e164:, service_name:)
    raise InvalidContact unless phone_e164.to_s.match?(UserAccount::BRAZILIAN_MOBILE_PATTERN)

    URI::HTTPS.build(
      host: HOST,
      path: "/#{phone_e164.delete_prefix("+")}",
      query: URI.encode_www_form(text: format(MESSAGE, service: service_name))
    ).to_s
  end
end
