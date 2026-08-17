# frozen_string_literal: true

class ProfessionalWorkspaceSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    {
      profile: {
        id: profile.id,
        profile_status: profile.profile_status,
        identity: {
          display_name: profile.display_name,
          headline: profile.headline.to_s,
          bio: profile.bio.to_s,
          years_experience: profile.years_experience,
          whatsapp: profile.whatsapp_e164 || profile.user_account.phone_e164,
          instagram: profile.instagram_url,
          youtube: profile.youtube_url
        }
      }
    }
  end

  private

  attr_reader :profile
end
