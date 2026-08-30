# frozen_string_literal: true

class ProfessionalNotificationCursor
  PURPOSE = "professional-notification-cursor"
  UUID_PATTERN = PublicInteractionToken::UUID_PATTERN
  Context = Data.define(:occurred_at, :id)

  def initialize(verifier: Rails.application.message_verifier(PURPOSE))
    @verifier = verifier
  end

  def issue(notification)
    verifier.generate(
      {"occurred_at" => notification.occurred_at.iso8601(6), "id" => notification.id},
      purpose: PURPOSE
    )
  end

  def verify(cursor)
    payload = verifier.verified(cursor.to_s, purpose: PURPOSE)
    return unless valid_payload?(payload)

    Context.new(
      occurred_at: Time.iso8601(payload.fetch("occurred_at")),
      id: payload.fetch("id")
    )
  rescue ArgumentError
    nil
  end

  private

  attr_reader :verifier

  def valid_payload?(payload)
    payload.is_a?(Hash) &&
      payload.keys.sort == %w[id occurred_at] &&
      payload["id"].to_s.match?(UUID_PATTERN) &&
      payload["occurred_at"].is_a?(String)
  end
end
