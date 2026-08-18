# frozen_string_literal: true

class ProfessionalProfileActivitySnapshot
  IDENTITY_FIELDS = %i[
    display_name headline bio years_experience whatsapp_e164 instagram_url youtube_url
  ].freeze

  def self.call(profile)
    revision = profile.working_revision
    {
      identity: IDENTITY_FIELDS.index_with { |field| revision.public_send(field) },
      services: revision.professional_profile_services
        .order(:service_id)
        .pluck(:service_id, :is_primary, :note),
      coverage: revision.professional_profile_service_areas
        .order(Arel.sql("neighborhood_code ASC NULLS FIRST"))
        .pluck(:city_code, :neighborhood_code)
    }
  end
end
