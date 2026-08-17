# frozen_string_literal: true

class AdminLoginRateLimiter
  WINDOW = 15.minutes
  LIMITS = {"email" => 5, "ip" => 30}.freeze

  class RateLimited < StandardError
    attr_reader :retry_after

    def initialize(retry_after:)
      @retry_after = retry_after
      super("Administrator login is rate limited")
    end
  end

  def check!(email:, ip_address:, now: Time.current)
    subjects(email:, ip_address:).each do |scope, subject|
      counter = current_counter(scope:, subject:, now:)
      raise_rate_limited(now:) if counter&.attempt_count.to_i >= LIMITS.fetch(scope)
    end
  end

  def register_failure!(email:, ip_address:, now: Time.current)
    subjects(email:, ip_address:).each do |scope, subject|
      increment!(scope:, subject:, now:)
    end

    check!(email:, ip_address:, now:)
  end

  def clear_email!(email:, now: Time.current)
    AdminLoginAttemptCounter.where(
      scope: "email",
      subject_digest: digest(scope: "email", subject: email),
      window_started_at: window_started_at(now)
    ).delete_all
  end

  private

  def subjects(email:, ip_address:)
    {
      "email" => email.to_s,
      "ip" => ip_address.to_s
    }
  end

  def current_counter(scope:, subject:, now:)
    AdminLoginAttemptCounter.find_by(
      scope:,
      subject_digest: digest(scope:, subject:),
      window_started_at: window_started_at(now)
    )
  end

  def increment!(scope:, subject:, now:)
    attributes = {
      scope:,
      subject_digest: digest(scope:, subject:),
      window_started_at: window_started_at(now)
    }

    AdminLoginAttemptCounter.transaction(requires_new: true) do
      AdminLoginAttemptCounter.insert_all(
        [attributes.merge(attempt_count: 0, created_at: now, updated_at: now)],
        unique_by: :index_admin_login_attempts_on_subject_and_window
      )
      counter = AdminLoginAttemptCounter.lock.find_by!(attributes)
      counter.increment!(:attempt_count, touch: :updated_at)
    end
  end

  def digest(scope:, subject:)
    SessionSecurityDigest.call(purpose: "admin_login_#{scope}", value: subject)
  end

  def window_started_at(now)
    Time.zone.at((now.to_i / WINDOW.to_i) * WINDOW.to_i)
  end

  def raise_rate_limited(now:)
    retry_after = (window_started_at(now) + WINDOW - now).ceil.clamp(1, WINDOW.to_i)
    raise RateLimited.new(retry_after:)
  end
end
