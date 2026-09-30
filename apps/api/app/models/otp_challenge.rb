# frozen_string_literal: true

class OtpChallenge < ApplicationRecord
  TOKEN_BYTES = 32
  CHANNELS = %w[email sms].freeze

  validates :public_token_digest, presence: true, uniqueness: true
  validates :channel, inclusion: {in: CHANNELS}
  validates :expires_at, presence: true
  validates :attempt_count, numericality: {only_integer: true, in: 0..5}
  validates :infobip_challenge_id_ciphertext, :phone_e164_ciphertext, presence: true, if: :sms?
  validates :email_ciphertext, :email_code_digest, presence: true, if: :email?
  validates :email_code_digest, format: {with: /\A[0-9a-f]{64}\z/}, allow_nil: true

  def self.issue!(phone_e164:, provider_reference:, expires_at:)
    public_token = SecureRandom.urlsafe_base64(TOKEN_BYTES, false)
    challenge = create!(
      public_token_digest: OtpSecurityDigest.call(purpose: "challenge_token", value: public_token),
      channel: "sms",
      phone_e164_ciphertext: encrypt(phone_e164, purpose: "phone_e164"),
      infobip_challenge_id_ciphertext: encrypt(provider_reference, purpose: "provider_reference"),
      expires_at:
    )

    [challenge, public_token]
  end

  def self.issue_email!(email:, code:, expires_at:)
    public_token = SecureRandom.urlsafe_base64(TOKEN_BYTES, false)
    challenge = create!(
      public_token_digest: OtpSecurityDigest.call(purpose: "challenge_token", value: public_token),
      channel: "email",
      email_ciphertext: encrypt(email, purpose: "email"),
      email_code_digest: email_code_digest(public_token:, code:),
      expires_at:
    )

    [challenge, public_token]
  end

  def sms?
    channel == "sms"
  end

  def email?
    channel == "email"
  end

  def phone_e164
    self.class.decrypt(phone_e164_ciphertext, purpose: "phone_e164")
  end

  def provider_reference
    self.class.decrypt(infobip_challenge_id_ciphertext, purpose: "provider_reference")
  end

  def email
    self.class.decrypt(email_ciphertext, purpose: "email")
  end

  def valid_email_code?(public_token:, code:)
    return false unless email?

    ActiveSupport::SecurityUtils.secure_compare(
      email_code_digest,
      self.class.email_code_digest(public_token:, code:)
    )
  end

  class << self
    def decrypt(value, purpose:)
      encryptor.decrypt_and_verify(value, purpose: encryption_purpose(purpose))
    end

    def email_code_digest(public_token:, code:)
      OtpSecurityDigest.call(
        purpose: "email_otp_code",
        value: "#{public_token}\0#{code}"
      )
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
