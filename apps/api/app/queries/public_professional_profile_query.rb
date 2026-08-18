# frozen_string_literal: true

class PublicProfessionalProfileQuery
  def call(slug:)
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
      .find_by!(public_slug: slug)
  end
end
