# frozen_string_literal: true

class ProfessionalRelationshipResponder
  RESPONSES = %w[accepted declined].freeze

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional relationship response")
    end
  end

  class Conflict < StandardError; end

  def initialize(notifier: ProfessionalNotificationCreator.new)
    @notifier = notifier
  end

  def call(relationship:, recipient:, response:, now: Time.current)
    normalized_response = response.to_s
    unless normalized_response.in?(RESPONSES)
      raise Invalid.new(response: ["confirme ou recuse a solicitação"])
    end

    ProfessionalRelationship.transaction do
      relationship.lock!
      raise ActiveRecord::RecordNotFound if relationship.deleted_at?
      raise ActiveRecord::RecordNotFound unless relationship.recipient_professional_id == recipient.id
      raise Conflict unless relationship.status == "pending"

      relationship.update!(status: normalized_response, responded_at: now)
      ProfessionalDailyActivity.increment!(
        professional_id: recipient.id,
        counter: :relationship_interactions,
        occurred_at: now
      )
      @notifier.call(
        recipient: relationship.initiator_professional.user_account,
        notification_type: "relationship_request_#{normalized_response}",
        idempotency_key: "relationship:#{relationship.id}:#{normalized_response}",
        occurred_at: now
      )
      relationship
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end
end
