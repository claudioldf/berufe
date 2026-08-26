# frozen_string_literal: true

require "uri"

class PublicWhatsappUrl
  class InvalidContact < StandardError; end

  HOST = "wa.me"

  def self.call(phone_e164:, message:)
    raise InvalidContact unless phone_e164.to_s.match?(UserAccount::BRAZILIAN_MOBILE_PATTERN)

    URI::HTTPS.build(
      host: HOST,
      path: "/#{phone_e164.delete_prefix("+")}",
      query: URI.encode_www_form(text: message.to_s)
    ).to_s
  end
end
