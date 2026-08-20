# frozen_string_literal: true

class PublicProfilePhotoImageUrl
  def self.call(photo, environment: ENV)
    PublicMediaUrl.call(
      rails_path: "/api/v1/public/profile-photos/#{photo.id}/image",
      environment:
    )
  end
end
