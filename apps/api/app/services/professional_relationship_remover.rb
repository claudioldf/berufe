# frozen_string_literal: true

class ProfessionalRelationshipRemover
  class NotRemovable < StandardError; end

  def call(relationship:, professional:, now: Time.current)
    ProfessionalRelationship.transaction do
      relationship.lock!
      raise NotRemovable if relationship.deleted_at?
      raise NotRemovable unless removable_by?(relationship, professional)

      relationship.update!(deleted_at: now)
      ProfessionalDailyActivity.increment!(
        professional_id: professional.id,
        counter: :relationship_interactions,
        occurred_at: now
      )
      relationship
    end
  end

  private

  def removable_by?(relationship, professional)
    return true if relationship.status == "accepted"

    relationship.status == "pending" &&
      relationship.initiator_professional_id == professional.id
  end
end
