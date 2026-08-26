# frozen_string_literal: true

class PublicSearchEventDeduplicator
  WINDOW = 1.day
  MAXIMUM_CLAIM_ATTEMPTS = 2

  def initialize(claims: PublicSearchEventDeduplication)
    @claims = claims
  end

  def reuse_or_claim!(event:, subject:, query:, result_count:, now: Time.current)
    key = {
      subject_digest: digest("subject", subject),
      query_digest: digest("query", query),
      result_count:
    }
    attempts = 0

    begin
      attempts += 1
      claim_event(event:, key:, now:)
    rescue ActiveRecord::RecordNotUnique
      retry if attempts < MAXIMUM_CLAIM_ATTEMPTS

      raise
    end
  end

  private

  attr_reader :claims

  def claim_event(event:, key:, now:)
    claims.transaction(requires_new: true) do
      claim = claims.lock.find_by(key)
      if claim&.expires_at&.after?(now)
        retained_event = claim.search_event
        event.destroy! unless retained_event.id == event.id
        next retained_event
      end

      expires_at = now + WINDOW
      if claim
        claim.update!(search_event: event, expires_at:)
      else
        claims.create!(**key, search_event: event, expires_at:)
      end
      event
    end
  end

  def digest(scope, value)
    SessionSecurityDigest.call(
      purpose: "public_search_event_deduplication_#{scope}",
      value: value.to_s
    )
  end
end
