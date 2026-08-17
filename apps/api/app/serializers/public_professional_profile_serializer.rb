# frozen_string_literal: true

class PublicProfessionalProfileSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    return nil unless profile.profile_status == "published" && profile.user_account.active?

    revision = profile.published_revision
    return nil unless revision&.status == "approved"

    {
      id: profile.id,
      public_slug: profile.public_slug,
      display_name: revision.display_name,
      headline: revision.headline,
      bio: revision.bio,
      years_experience: revision.years_experience,
      whatsapp: revision.whatsapp_e164,
      instagram: revision.instagram_url,
      youtube: revision.youtube_url,
      verification: PublicVerificationSerializer.new(profile).as_json,
      services: revision.professional_profile_services.includes(:service).map do |selection|
        {
          id: selection.service_id,
          name: selection.service.name,
          is_primary: selection.is_primary,
          note: selection.note
        }
      end,
      coverage: {
        all_joinville: revision.professional_profile_service_areas.any? { |area| area.neighborhood_code.nil? },
        neighborhood_codes: revision.professional_profile_service_areas.filter_map(&:neighborhood_code)
      }
    }
  end

  private

  attr_reader :profile
end
