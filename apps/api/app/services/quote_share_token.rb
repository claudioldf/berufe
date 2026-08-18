# frozen_string_literal: true

require "base64"
require "openssl"

class QuoteShareToken
  PREFIX = "bq_"
  ENCODED_BYTES_LENGTH = 43
  PATTERN = /\A#{PREFIX}[A-Za-z0-9_-]{#{ENCODED_BYTES_LENGTH}}\z/

  def self.issue(quote_id)
    digest = OpenSSL::HMAC.digest(
      "SHA256",
      signing_key,
      "quote_share_v1\0#{quote_id}"
    )
    "#{PREFIX}#{Base64.urlsafe_encode64(digest, padding: false)}"
  end

  def self.digest(token)
    OpenSSL::HMAC.hexdigest("SHA256", digest_key, token.to_s)
  end

  def self.valid?(token)
    PATTERN.match?(token.to_s)
  end

  def self.matches?(quote_id:, token:)
    return false unless valid?(token)

    ActiveSupport::SecurityUtils.secure_compare(issue(quote_id), token)
  end

  def self.signing_key
    @signing_key ||= Rails.application.key_generator.generate_key("berufe.quote_share_signing", 32)
  end
  private_class_method :signing_key

  def self.digest_key
    @digest_key ||= Rails.application.key_generator.generate_key("berufe.quote_share_digest", 32)
  end
  private_class_method :digest_key
end
