# frozen_string_literal: true

class FeaturedPublicProfessionalsQuery
  LIMIT = 3

  def call
    ProfessionalProfile
      .publicly_eligible
      .includes(
        :published_photo,
        :verification_requests,
        portfolio_items: :service,
        published_revision: {
          professional_profile_services: :service,
          professional_profile_service_areas: :neighborhood
        }
      )
      .order(Arel.sql("professional_profile_revisions.reviewed_at DESC NULLS LAST"), id: :asc)
      .limit(LIMIT)
  end
end
