# frozen_string_literal: true

class PublicProfileInteractionToken
  TTL = 10.minutes
  PURPOSE = "public-profile-interaction"
  UUID_PATTERN = PublicInteractionToken::UUID_PATTERN

  Context = Data.define(
    :interaction_id,
    :professional_id,
    :service_id,
    :search_event_id
  )

  def initialize(verifier: Rails.application.message_verifier(PURPOSE))
    @verifier = verifier
  end

  def issue(professional_id:, service_id:, search_event_id: nil, interaction_id: SecureRandom.uuid)
    verifier.generate(
      {
        "interaction_id" => interaction_id,
        "professional_id" => professional_id,
        "service_id" => service_id,
        "search_event_id" => search_event_id
      },
      expires_in: TTL,
      purpose: PURPOSE
    )
  end

  def verify(token)
    payload = verifier.verified(token.to_s, purpose: PURPOSE)
    return unless valid_payload?(payload)

    Context.new(
      interaction_id: payload.fetch("interaction_id"),
      professional_id: payload.fetch("professional_id"),
      service_id: payload.fetch("service_id"),
      search_event_id: payload.fetch("search_event_id")
    )
  end

  private

  attr_reader :verifier

  def valid_payload?(payload)
    return false unless payload.is_a?(Hash)
    return false unless payload.keys.sort == %w[interaction_id professional_id search_event_id service_id]
    return false unless payload["interaction_id"].to_s.match?(UUID_PATTERN)
    return false unless payload["professional_id"].to_s.match?(UUID_PATTERN)
    return false unless payload["service_id"].nil? || payload["service_id"].to_s.match?(UUID_PATTERN)

    payload["search_event_id"].nil? || payload["search_event_id"].to_s.match?(UUID_PATTERN)
  end
end
