# frozen_string_literal: true

class ProfessionalRelationshipSerializer
  def initialize(relationship)
    @relationship = relationship
  end

  def as_json(*)
    {
      id: relationship.id,
      relationship_type: relationship.relationship_type,
      context_note: relationship.context_note,
      status: relationship.status,
      created_at: relationship.created_at,
      responded_at: relationship.responded_at,
      initiator: profile_summary(relationship.initiator_professional),
      recipient: profile_summary(relationship.recipient_professional)
    }
  end

  private

  attr_reader :relationship

  def profile_summary(profile)
    display_revision = profile.published_revision || profile.working_revision
    {
      id: profile.id,
      public_slug: profile.public_slug,
      display_name: display_revision.display_name
    }
  end
end
