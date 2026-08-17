# frozen_string_literal: true

class ProfessionalRegistrationSerializer
  def initialize(professional_profile)
    @professional_profile = professional_profile
  end

  def as_json(*)
    {
      status: "completed",
      profile: {
        id: @professional_profile.id,
        display_name: @professional_profile.display_name,
        profile_status: @professional_profile.profile_status
      }
    }
  end
end
