# frozen_string_literal: true

class AdminPasswordAuthenticator
  class Invalid < StandardError; end

  Result = Data.define(:session, :session_token)
  DUMMY_PASSWORD_DIGEST = BCrypt::Password.create(SecureRandom.base64(32)).to_s.freeze

  def initialize(rate_limiter: AdminLoginRateLimiter.new)
    @rate_limiter = rate_limiter
  end

  def call(email:, password:, ip_address:, now: Time.current)
    normalized_email = AdminEmail.normalize(email)
    throttle_subject = normalized_email || email.to_s.strip.downcase
    @rate_limiter.check!(email: throttle_subject, ip_address:, now:)

    UserAccount.transaction do
      account = UserAccount.lock.find_by(email: normalized_email, role: "admin")
      password_matches = password_matches?(account, password)
      raise Invalid unless account&.active? && password_matches

      account.update!(last_login_at: now, login_count: account.login_count + 1)
      session, session_token = ApplicationSession.issue!(user_account: account, now:)
      @rate_limiter.clear_email!(email: throttle_subject, now:)
      Result.new(session:, session_token:)
    end
  rescue Invalid
    @rate_limiter.register_failure!(email: throttle_subject, ip_address:, now:)
    raise
  end

  private

  def password_matches?(account, password)
    digest = account&.password_digest || DUMMY_PASSWORD_DIGEST
    BCrypt::Password.new(digest).is_password?(password.to_s)
  rescue BCrypt::Errors::InvalidHash
    false
  end
end
