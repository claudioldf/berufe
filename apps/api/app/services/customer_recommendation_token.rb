# frozen_string_literal: true

require "openssl"

class CustomerRecommendationToken
  PREFIX = "br_"
  TOKEN_BYTES = 32
  ENCODED_BYTES_LENGTH = 43
  PATTERN = /\A#{PREFIX}[A-Za-z0-9_-]{#{ENCODED_BYTES_LENGTH}}\z/
  ENCRYPTION_PURPOSE = "berufe.customer_recommendation.token"

  def self.issue
    "#{PREFIX}#{SecureRandom.urlsafe_base64(TOKEN_BYTES, false)}"
  end

  def self.digest(token)
    OpenSSL::HMAC.hexdigest("SHA256", digest_key, token.to_s)
  end

  def self.valid?(token)
    PATTERN.match?(token.to_s)
  end

  def self.encrypt(token)
    encryptor.encrypt_and_sign(token, purpose: ENCRYPTION_PURPOSE)
  end

  def self.decrypt(ciphertext)
    return if ciphertext.blank?

    encryptor.decrypt_and_verify(ciphertext, purpose: ENCRYPTION_PURPOSE)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def self.digest_key
    @digest_key ||= Rails.application.key_generator.generate_key("berufe.customer_recommendation_digest", 32)
  end
  private_class_method :digest_key

  def self.encryptor
    @encryptor ||= ActiveSupport::MessageEncryptor.new(
      Rails.application.key_generator.generate_key(
        "berufe.customer_recommendation.encryption",
        ActiveSupport::MessageEncryptor.key_len
      )
    )
  end
  private_class_method :encryptor
end
