# frozen_string_literal: true

class PublicInteractionToken
  TTL = 10.minutes
  PURPOSE = "public-search-interaction"
  UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

  Context = Data.define(:search_event_id, :service_id)

  def initialize(verifier: Rails.application.message_verifier(PURPOSE))
    @verifier = verifier
  end

  def issue(search_event_id:, service_id:)
    verifier.generate(
      {"search_event_id" => search_event_id, "service_id" => service_id},
      expires_in: TTL,
      purpose: PURPOSE
    )
  end

  def verify(token)
    payload = verifier.verified(token.to_s, purpose: PURPOSE)
    return unless valid_payload?(payload)

    Context.new(
      search_event_id: payload.fetch("search_event_id"),
      service_id: payload.fetch("service_id")
    )
  end

  private

  attr_reader :verifier

  def valid_payload?(payload)
    return false unless payload.is_a?(Hash) && payload.keys.sort == %w[search_event_id service_id]
    return false unless payload["search_event_id"].to_s.match?(UUID_PATTERN)

    payload["service_id"].nil? || payload["service_id"].to_s.match?(UUID_PATTERN)
  end
end
