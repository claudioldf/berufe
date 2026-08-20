# frozen_string_literal: true

class ProfessionalRelationshipRequester
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional relationship")
    end
  end

  class Duplicate < StandardError; end
  class Ineligible < StandardError; end

  def call(initiator:, recipient_professional_id:, relationship_type:, context_note:, now: Time.current)
    ProfessionalRelationship.transaction do
      initiator.lock!
      ensure_eligible_initiator!(initiator)
      recipient = ProfessionalProfile.publicly_eligible.find(recipient_professional_id)
      ensure_distinct_profiles!(initiator, recipient)
      ensure_not_duplicate!(initiator, recipient, relationship_type)

      relationship = ProfessionalRelationship.create!(
        initiator_professional: initiator,
        recipient_professional: recipient,
        relationship_type:,
        context_note:,
        status: "pending"
      )
      ProfessionalDailyActivity.increment!(
        professional_id: initiator.id,
        counter: :relationship_interactions,
        occurred_at: now
      )
      relationship
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  rescue ActiveRecord::RecordNotUnique
    raise Duplicate
  end

  private

  def ensure_eligible_initiator!(initiator)
    return if initiator.user_account.active? && initiator.verification_requests.identity.exists?(status: "approved")

    raise Ineligible
  end

  def ensure_distinct_profiles!(initiator, recipient)
    return unless initiator.id == recipient.id

    raise Invalid.new(recipient_professional_id: ["não pode ser o próprio perfil"])
  end

  def ensure_not_duplicate!(initiator, recipient, relationship_type)
    return unless ProfessionalRelationship.exists?(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type:
    )

    raise Duplicate
  end
end
