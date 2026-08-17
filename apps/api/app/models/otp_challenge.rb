# frozen_string_literal: true

class OtpChallenge < ApplicationRecord
  TOKEN_BYTES = 32

  validates :public_token_digest, presence: true, uniqueness: true
  validates :infobip_challenge_id_ciphertext, :phone_e164_ciphertext, :expires_at, presence: true

  def self.issue!(phone_e164:, provider_reference:, expires_at:)
    public_token = SecureRandom.urlsafe_base64(TOKEN_BYTES, false)
    challenge = create!(
      public_token_digest: OtpSecurityDigest.call(purpose: "challenge_token", value: public_token),
      phone_e164_ciphertext: encrypt(phone_e164, purpose: "phone_e164"),
      infobip_challenge_id_ciphertext: encrypt(provider_reference, purpose: "provider_reference"),
      expires_at:
    )

    [challenge, public_token]
  end

  def phone_e164
    self.class.decrypt(phone_e164_ciphertext, purpose: "phone_e164")
  end

  def provider_reference
    self.class.decrypt(infobip_challenge_id_ciphertext, purpose: "provider_reference")
  end

  class << self
    def decrypt(value, purpose:)
      encryptor.decrypt_and_verify(value, purpose: encryption_purpose(purpose))
    end

    private

    def encrypt(value, purpose:)
      encryptor.encrypt_and_sign(value, purpose: encryption_purpose(purpose))
    end

    def encryptor
      @encryptor ||= ActiveSupport::MessageEncryptor.new(
        Rails.application.key_generator.generate_key("berufe.otp_challenge.encryption", ActiveSupport::MessageEncryptor.key_len)
      )
    end

    def encryption_purpose(purpose)
      "berufe.otp_challenge.#{purpose}"
    end
  end
end
