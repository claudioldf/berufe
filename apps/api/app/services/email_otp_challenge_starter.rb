# frozen_string_literal: true

class EmailOtpChallengeStarter
  Result = Data.define(:challenge_token, :expires_in, :resend_available_in)

  def initialize(
    delivery: EmailOtpDelivery.new,
    rate_limiter: OtpRequestRateLimiter.new,
    settings: Rails.configuration.x.berufe.otp,
    code_generator: nil
  )
    @delivery = delivery
    @rate_limiter = rate_limiter
    @settings = settings
    @code_generator = code_generator || method(:generate_code)
  end

  def call(email:, ip_address:, now: Time.current)
    normalized_email = ProfessionalEmail.normalize(email)
    @rate_limiter.record!(
      identifier: normalized_email,
      identifier_type: "email",
      ip_address:,
      now:
    )
    code = @code_generator.call
    challenge, challenge_token = OtpChallenge.issue_email!(
      email: normalized_email,
      code:,
      expires_at: now + @settings.challenge_ttl_seconds.seconds
    )
    @delivery.call(
      email: normalized_email,
      code:,
      expires_in: @settings.challenge_ttl_seconds
    )

    Result.new(
      challenge_token:,
      expires_in: @settings.challenge_ttl_seconds,
      resend_available_in: @settings.resend_cooldown_seconds
    )
  rescue EmailOtp::DeliveryRejected, EmailOtp::ProviderUnavailable
    challenge&.delete
    raise
  end

  private

  def generate_code
    @settings.fake_email_code || format("%06d", SecureRandom.random_number(1_000_000))
  end
end
