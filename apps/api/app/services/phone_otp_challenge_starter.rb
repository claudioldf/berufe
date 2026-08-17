# frozen_string_literal: true

class PhoneOtpChallengeStarter
  Result = Data.define(:challenge_token, :expires_in, :resend_available_in)

  def initialize(
    otp_client: SmsOtpClient.build,
    rate_limiter: OtpRequestRateLimiter.new,
    settings: Rails.configuration.x.berufe.otp
  )
    @otp_client = otp_client
    @rate_limiter = rate_limiter
    @settings = settings
  end

  def call(phone:, ip_address:, now: Time.current)
    phone_e164 = BrazilianPhoneNumber.normalize(phone)
    @rate_limiter.record!(phone_e164:, ip_address:, now:)
    provider_challenge = @otp_client.start_challenge(phone: phone_e164)
    raise SmsOtp::DeliveryRejected unless provider_challenge.status == "accepted"
    raise SmsOtp::ProviderUnavailable if provider_challenge.reference.to_s.empty?

    expires_at = now + @settings.challenge_ttl_seconds.seconds
    _challenge, challenge_token = OtpChallenge.issue!(
      phone_e164:,
      provider_reference: provider_challenge.reference,
      expires_at:
    )

    Result.new(
      challenge_token:,
      expires_in: @settings.challenge_ttl_seconds,
      resend_available_in: @settings.resend_cooldown_seconds
    )
  end
end
