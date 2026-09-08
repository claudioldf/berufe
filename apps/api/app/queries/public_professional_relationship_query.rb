# frozen_string_literal: true

class PublicProfessionalRelationshipQuery
  def self.call
    ProfessionalRelationship
      .active
      .where(status: "accepted")
      .where(party_is_discoverable_sql("initiator_professional_id"))
      .where(party_is_discoverable_sql("recipient_professional_id"))
  end

  def self.for_professional(professional_id)
    relationships = ProfessionalRelationship.arel_table
    initiator_relationship = relationships[:initiator_professional_id]
      .eq(professional_id)
      .and(party_is_discoverable_sql("recipient_professional_id"))
    recipient_relationship = relationships[:recipient_professional_id]
      .eq(professional_id)
      .and(party_is_discoverable_sql("initiator_professional_id"))

    ProfessionalRelationship
      .active
      .where(status: "accepted")
      .where(initiator_relationship.or(recipient_relationship))
  end

  # Correlates on a quoted Arel column rather than interpolated SQL, so the
  # party column can never carry anything but a real relationship foreign key.
  def self.party_is_discoverable_sql(foreign_key)
    party_column = ProfessionalRelationship.arel_table[foreign_key]
    discoverable = ProfessionalProfile.publicly_searchable
      .where(ProfessionalProfile.arel_table[:id].eq(party_column))
      .select("1")
    Arel::Nodes::Exists.new(discoverable.arel)
  end
  private_class_method :party_is_discoverable_sql
end
