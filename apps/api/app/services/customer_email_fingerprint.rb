# frozen_string_literal: true

require "openssl"

class CustomerEmailFingerprint
  def self.call(email)
    normalized = email.to_s.strip.downcase
    OpenSSL::HMAC.hexdigest("SHA256", digest_key, normalized)
  end

  def self.digest_key
    @digest_key ||= Rails.application.key_generator.generate_key("berufe.customer_email_fingerprint", 32)
  end
  private_class_method :digest_key
end
