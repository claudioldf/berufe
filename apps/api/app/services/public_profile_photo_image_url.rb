# frozen_string_literal: true

class PublicProfilePhotoImageUrl
  def self.call(photo, environment: ENV)
    base_url = environment.fetch("API_PUBLIC_URL").delete_suffix("/")
    "#{base_url}/api/v1/public/profile-photos/#{photo.id}/image"
  end
end
