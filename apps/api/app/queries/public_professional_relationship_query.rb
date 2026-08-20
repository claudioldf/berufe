# frozen_string_literal: true

class PublicProfessionalRelationshipQuery
  def self.call
    ProfessionalRelationship
      .active
      .where(status: "accepted")
      .where(party_is_public_sql("initiator_professional_id"))
      .where(party_is_public_sql("recipient_professional_id"))
  end

  def self.for_professional(professional_id)
    call.where(
      "professional_relationships.initiator_professional_id = :id OR " \
        "professional_relationships.recipient_professional_id = :id",
      id: professional_id
    )
  end

  # Correlates on a quoted Arel column rather than interpolated SQL, so the
  # party column can never carry anything but a real relationship foreign key.
  def self.party_is_public_sql(foreign_key)
    party_column = ProfessionalRelationship.arel_table[foreign_key]
    eligible = ProfessionalProfile.publicly_eligible
      .where(ProfessionalProfile.arel_table[:id].eq(party_column))
      .select("1")
    Arel::Nodes::Exists.new(eligible.arel)
  end
  private_class_method :party_is_public_sql
end
