# frozen_string_literal: true

class ProfessionalOtpVerifier
  class Invalid < StandardError; end

  Result = Data.define(:session, :session_token)
  CODE_PATTERN = /\A\d{6}\z/
  MAXIMUM_ATTEMPTS = 5

  def initialize(sms_otp_client: SmsOtpClient.build)
    @sms_otp_client = sms_otp_client
  end

  def call(challenge_token:, code:, now: Time.current)
    raise Invalid unless CODE_PATTERN.match?(code.to_s)

    token_digest = OtpSecurityDigest.call(purpose: "challenge_token", value: challenge_token.to_s)
    result = OtpChallenge.transaction do
      challenge = OtpChallenge.lock.find_by(public_token_digest: token_digest)
      next unless challenge_usable?(challenge, now:)

      unless verified?(challenge:, challenge_token: challenge_token.to_s, code: code.to_s)
        record_failed_attempt!(challenge, now:)
        next
      end

      account, authentication_method = resolve_account!(challenge, now:)
      unless account
        challenge.update!(consumed_at: now)
        next
      end
      session, session_token = ApplicationSession.issue!(
        user_account: account,
        authentication_method:,
        now:
      )
      challenge.update!(consumed_at: now)

      Result.new(session:, session_token:)
    end

    result || raise(Invalid)
  end

  private

  def challenge_usable?(challenge, now:)
    challenge && challenge.consumed_at.nil? && challenge.attempt_count < MAXIMUM_ATTEMPTS && now < challenge.expires_at
  end

  def verified?(challenge:, challenge_token:, code:)
    if challenge.sms?
      @sms_otp_client.verify_challenge(reference: challenge.provider_reference, code:).verified
    else
      challenge.valid_email_code?(public_token: challenge_token, code:)
    end
  end

  def record_failed_attempt!(challenge, now:)
    attempts = challenge.attempt_count + 1
    challenge.update!(
      attempt_count: attempts,
      consumed_at: (now if attempts >= MAXIMUM_ATTEMPTS)
    )
  end

  def resolve_account!(challenge, now:)
    if challenge.sms?
      [resolve_phone_account!(challenge.phone_e164, now:), "sms_otp"]
    else
      [resolve_email_account!(challenge.email, now:), "email_otp"]
    end
  end

  def resolve_phone_account!(phone_e164, now:)
    UserAccount.insert_all(
      [{
        phone_e164:,
        role: "professional",
        status: "active",
        phone_verified_at: now,
        created_at: now,
        updated_at: now
      }],
      unique_by: :index_user_accounts_on_phone_e164
    )
    account = UserAccount.lock.find_by!(phone_e164:)
    raise Invalid unless account.professional?

    account.update!(
      phone_verified_at: account.phone_verified_at || now,
      last_login_at: now,
      login_count: account.login_count + 1
    )
    account
  end

  def resolve_email_account!(email, now:)
    UserAccount.insert_all(
      [{
        email:,
        role: "professional",
        status: "active",
        email_verified_at: now,
        created_at: now,
        updated_at: now
      }],
      unique_by: :index_user_accounts_on_email
    )
    account = UserAccount.lock.find_by!(email:)
    return unless account.professional?

    account.update!(
      email_verified_at: account.email_verified_at || now,
      last_login_at: now,
      login_count: account.login_count + 1
    )
    account
  end
end
