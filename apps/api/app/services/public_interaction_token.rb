# frozen_string_literal: true

class PublicInteractionToken
  TTL = 10.minutes
  PURPOSE = "public-search-interaction"
  UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

  Context = Data.define(:search_event_id, :service_ids) do
    def service_id
      service_ids.first
    end
  end

  def initialize(verifier: Rails.application.message_verifier(PURPOSE))
    @verifier = verifier
  end

  def issue(search_event_id:, service_id: nil, service_ids: nil)
    normalized_service_ids = Array(service_ids || service_id).compact.map(&:to_s).uniq
    verifier.generate(
      {"search_event_id" => search_event_id, "service_ids" => normalized_service_ids},
      expires_in: TTL,
      purpose: PURPOSE
    )
  end

  def verify(token)
    payload = verifier.verified(token.to_s, purpose: PURPOSE)
    return unless valid_payload?(payload)

    Context.new(
      search_event_id: payload.fetch("search_event_id"),
      service_ids: Array(payload["service_ids"] || payload["service_id"]).compact
    )
  end

  private

  attr_reader :verifier

  def valid_payload?(payload)
    return false unless payload.is_a?(Hash)
    return false unless [%w[search_event_id service_id], %w[search_event_id service_ids]].include?(payload.keys.sort)
    return false unless payload["search_event_id"].to_s.match?(UUID_PATTERN)

    Array(payload["service_ids"] || payload["service_id"]).compact.all? do |service_id|
      service_id.to_s.match?(UUID_PATTERN)
    end
  end
end
