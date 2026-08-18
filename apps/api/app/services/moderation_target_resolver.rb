# frozen_string_literal: true

class ModerationTargetResolver
  MODELS = {
    "profile_revision" => ProfessionalProfileRevision,
    "profile_photo" => ProfessionalProfilePhoto,
    "portfolio_item" => PortfolioItem,
    "verification_request" => VerificationRequest,
    "professional_relationship" => ProfessionalRelationship
  }.freeze

  def call(target_type:, target_id:)
    model = MODELS.fetch(target_type.to_s) { raise ActiveRecord::RecordNotFound, "moderation target" }
    model.find(target_id)
  end
end
