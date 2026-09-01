# frozen_string_literal: true

class ProfessionalProfilePhotoImageUrl
  def self.call(photo, environment: ENV)
    PublicMediaUrl.call(
      rails_path: "/api/v1/professional/profile-photos/#{photo.id}/image",
      environment:
    )
  end
end
