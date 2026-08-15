# frozen_string_literal: true

class ApplicationSession < ApplicationRecord
  COOKIE_NAME = "__Host-berufe_session"
  TOKEN_BYTES = 32
  AUTHENTICATION_METHOD = "sms_otp"
  SESSION_DURATIONS = {
    "professional" => {idle: 7.days, absolute: 30.days},
    "admin" => {idle: 30.minutes, absolute: 12.hours}
  }.freeze

  belongs_to :user_account

  validates :authentication_method, inclusion: {in: [AUTHENTICATION_METHOD]}
  validates :token_digest, :csrf_token_digest, format: {with: /\A[0-9a-f]{64}\z/}
  validates :authenticated_at, :last_active_at, :idle_expires_at, :absolute_expires_at, presence: true

  def self.issue!(user_account:, now: Time.current, mfa_authenticated_at: nil)
    session_token = SecureRandom.urlsafe_base64(TOKEN_BYTES, false)
    csrf_token = SecureRandom.urlsafe_base64(TOKEN_BYTES, false)
    durations = SESSION_DURATIONS.fetch(user_account.role)
    session = create!(
      user_account:,
      authentication_method: AUTHENTICATION_METHOD,
      token_digest: digest_token(session_token),
      csrf_token_digest: SessionSecurityDigest.call(purpose: "csrf_token", value: csrf_token),
      authenticated_at: now,
      mfa_authenticated_at:,
      last_active_at: now,
      idle_expires_at: now + durations.fetch(:idle),
      absolute_expires_at: now + durations.fetch(:absolute)
    )

    [session, session_token]
  end

  def self.digest_token(token)
    SessionSecurityDigest.call(purpose: "session_token", value: token)
  end

  def active?(now: Time.current)
    revoked_at.nil? && now < idle_expires_at && now < absolute_expires_at
  end

  def record_activity!(now: Time.current, write_interval: Rails.configuration.x.berufe.session_activity_write_interval_seconds)
    return false unless active?(now:)
    return false if now < last_active_at + write_interval.seconds

    durations = SESSION_DURATIONS.fetch(user_account.role)
    update!(
      last_active_at: now,
      idle_expires_at: [now + durations.fetch(:idle), absolute_expires_at].min
    )
    true
  end
end
