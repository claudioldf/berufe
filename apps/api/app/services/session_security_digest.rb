# frozen_string_literal: true

require "openssl"

class SessionSecurityDigest
  def self.call(purpose:, value:)
    OpenSSL::HMAC.hexdigest("SHA256", key, "#{purpose}\0#{value}")
  end

  def self.key
    @key ||= Rails.application.key_generator.generate_key("berufe.application_session_digest", 32)
  end
  private_class_method :key
end
