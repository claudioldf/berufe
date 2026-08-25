# frozen_string_literal: true

class PublicSearchRateLimiter
  WINDOW = 1.hour
  LIMIT = 40

  class RateLimited < StandardError
    attr_reader :retry_after

    def initialize(retry_after:)
      @retry_after = retry_after
      super("Public search is rate limited")
    end
  end

  def check_and_increment!(ip_address:, now: Time.current)
    attributes = {
      subject_digest: SessionSecurityDigest.call(
        purpose: "public_expression_search_ip",
        value: ip_address.to_s
      ),
      window_started_at: window_started_at(now)
    }

    PublicSearchRateLimitCounter.transaction(requires_new: true) do
      PublicSearchRateLimitCounter.insert_all(
        [attributes.merge(request_count: 0, created_at: now, updated_at: now)],
        unique_by: :idx_public_search_rate_limits_subject_window
      )
      counter = PublicSearchRateLimitCounter.lock.find_by!(attributes)
      raise_rate_limited(now:) if counter.request_count >= LIMIT

      counter.increment!(:request_count, touch: :updated_at)
    end
  end

  private

  def window_started_at(now)
    Time.zone.at((now.to_i / WINDOW.to_i) * WINDOW.to_i)
  end

  def raise_rate_limited(now:)
    retry_after = (window_started_at(now) + WINDOW - now).ceil.clamp(1, WINDOW.to_i)
    raise RateLimited.new(retry_after:)
  end
end
