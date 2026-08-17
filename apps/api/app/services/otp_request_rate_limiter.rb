# frozen_string_literal: true

class OtpRequestRateLimiter
  class RateLimited < StandardError
    attr_reader :reason, :retry_after

    def initialize(reason:, retry_after:)
      @reason = reason
      @retry_after = retry_after
      super("Phone OTP request rate limited")
    end
  end

  def initialize(settings: Rails.configuration.x.berufe.otp)
    @settings = settings
  end

  def record!(phone_e164:, ip_address:, now: Time.current)
    window_started_at = now.utc.beginning_of_day
    expires_at = window_started_at + 1.day
    digests = {
      "ip" => OtpSecurityDigest.call(purpose: "request_ip", value: ip_address),
      "phone" => OtpSecurityDigest.call(purpose: "request_phone", value: phone_e164)
    }

    OtpRequestCounter.transaction do
      create_missing_counters!(digests:, window_started_at:, expires_at:, now:)
      counters = locked_counters(digests:, window_started_at:)
      enforce_daily_limits!(counters:, expires_at:, now:)
      enforce_cooldown!(counters.fetch("phone"), now:)
      counters.each_value do |counter|
        counter.update!(request_count: counter.request_count + 1, last_requested_at: now)
      end
    end
  end

  private

  def create_missing_counters!(digests:, window_started_at:, expires_at:, now:)
    rows = digests.map do |scope_kind, subject_digest|
      {
        scope_kind:,
        subject_digest:,
        window_started_at:,
        expires_at:,
        request_count: 0,
        created_at: now,
        updated_at: now
      }
    end
    OtpRequestCounter.insert_all(rows, unique_by: "index_otp_counters_on_scope_subject_and_window")
  end

  def locked_counters(digests:, window_started_at:)
    OtpRequestCounter
      .where(scope_kind: digests.keys, subject_digest: digests.values, window_started_at:)
      .order(:scope_kind)
      .lock
      .index_by(&:scope_kind)
      .tap do |counters|
        raise ActiveRecord::RecordNotFound unless counters.keys.sort == digests.keys.sort
      end
  end

  def enforce_daily_limits!(counters:, expires_at:, now:)
    limits = {
      "phone" => @settings.daily_phone_limit,
      "ip" => @settings.daily_ip_limit
    }
    limited_scope = limits.find { |scope_kind, limit| counters.fetch(scope_kind).request_count >= limit }&.first
    return unless limited_scope

    raise RateLimited.new(
      reason: "daily_#{limited_scope}",
      retry_after: seconds_until(expires_at, now:)
    )
  end

  def enforce_cooldown!(phone_counter, now:)
    return unless phone_counter.last_requested_at

    available_at = phone_counter.last_requested_at + @settings.resend_cooldown_seconds.seconds
    return if available_at <= now

    raise RateLimited.new(reason: "cooldown", retry_after: seconds_until(available_at, now:))
  end

  def seconds_until(timestamp, now:)
    [(timestamp - now).ceil, 1].max
  end
end
