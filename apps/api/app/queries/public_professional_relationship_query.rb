# frozen_string_literal: true

class PublicProfessionalRelationshipQuery
  PUBLIC_ACTIONS = %w[approved restored].freeze

  def self.call
    ProfessionalRelationship
      .where(status: "accepted")
      .where(latest_action_sql, PUBLIC_ACTIONS)
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

  def self.latest_action_sql
    <<~SQL.squish
      (
        SELECT moderation_actions.action
        FROM moderation_actions
        WHERE moderation_actions.target_type = 'professional_relationship'
          AND moderation_actions.target_id = professional_relationships.id
        ORDER BY moderation_actions.created_at DESC, moderation_actions.id DESC
        LIMIT 1
      ) IN (?)
    SQL
  end
  private_class_method :latest_action_sql

  def self.party_is_public_sql(foreign_key)
    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM professional_profiles public_party_profiles
        INNER JOIN user_accounts public_party_accounts
          ON public_party_accounts.id = public_party_profiles.user_account_id
        INNER JOIN professional_profile_revisions public_party_revisions
          ON public_party_revisions.id = public_party_profiles.published_revision_id
        WHERE public_party_profiles.id = professional_relationships.#{foreign_key}
          AND public_party_profiles.profile_status = 'published'
          AND public_party_accounts.status = 'active'
          AND public_party_revisions.status = 'approved'
      )
    SQL
  end
  private_class_method :party_is_public_sql
end
