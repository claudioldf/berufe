# frozen_string_literal: true

class ProfessionalWorkspaceSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    {
      profile: {
        id: profile.id,
        public_slug: profile.public_slug,
        profile_status: profile.profile_status,
        revision_status: profile.working_revision.status,
        has_published_revision: profile.published_revision.present?,
        identity: {
          display_name: profile.display_name,
          headline: profile.headline.to_s,
          bio: profile.bio.to_s,
          years_experience: profile.years_experience,
          whatsapp: profile.whatsapp_e164 || profile.user_account.phone_e164,
          instagram: profile.instagram_url,
          youtube: profile.youtube_url
        },
        services: serialized_services,
        coverage: serialized_coverage
      }
    }
  end

  private

  attr_reader :profile

  def serialized_services
    profile.working_revision.professional_profile_services.includes(:service).map do |selection|
      {
        id: selection.service_id,
        name: selection.service.name,
        is_primary: selection.is_primary,
        note: selection.note
      }
    end
  end

  def serialized_coverage
    areas = profile.working_revision.professional_profile_service_areas.includes(:neighborhood)
    {
      all_joinville: areas.any? { |area| area.neighborhood_code.nil? },
      neighborhoods: areas.filter_map do |area|
        next unless area.neighborhood

        {code: area.neighborhood.code, name: area.neighborhood.name}
      end
    }
  end
end
