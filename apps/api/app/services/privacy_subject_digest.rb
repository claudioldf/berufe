# frozen_string_literal: true

require "openssl"

class PrivacySubjectDigest
  def self.call(value)
    OpenSSL::HMAC.hexdigest("SHA256", key, value.to_s)
  end

  def self.key
    @key ||= Rails.application.key_generator.generate_key("berufe.privacy_subject_digest", 32)
  end
  private_class_method :key
end
