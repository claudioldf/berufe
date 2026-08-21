# frozen_string_literal: true

class PhoneOtpVerifier
  class Invalid < StandardError; end

  Result = Data.define(:session, :session_token)
  CODE_PATTERN = /\A\d{6}\z/

  def initialize(otp_client: SmsOtpClient.build)
    @otp_client = otp_client
  end

  def call(challenge_token:, code:, now: Time.current)
    raise Invalid unless CODE_PATTERN.match?(code.to_s)

    token_digest = OtpSecurityDigest.call(purpose: "challenge_token", value: challenge_token.to_s)
    OtpChallenge.transaction do
      challenge = OtpChallenge.lock.find_by(public_token_digest: token_digest)
      raise Invalid unless challenge_usable?(challenge, now:)

      verification = @otp_client.verify_challenge(reference: challenge.provider_reference, code: code.to_s)
      raise Invalid unless verification.verified

      phone_e164 = challenge.phone_e164
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
      account = UserAccount.find_by!(phone_e164:)
      raise Invalid unless account.professional?

      account.update!(
        phone_verified_at: account.phone_verified_at || now,
        last_login_at: now
      )
      session, session_token = ApplicationSession.issue!(user_account: account, now:)
      challenge.update!(consumed_at: now)

      Result.new(session:, session_token:)
    end
  end

  private

  def challenge_usable?(challenge, now:)
    challenge && challenge.consumed_at.nil? && now < challenge.expires_at
  end
end
