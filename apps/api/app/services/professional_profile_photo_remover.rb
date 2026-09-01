# frozen_string_literal: true

class ProfessionalProfilePhotoRemover
  def call(profile:, now: Time.current)
    profile.with_lock do
      photo = profile.profile_photo
      profile.update!(profile_photo: nil)
      photo.update!(deleted_at: now) if photo && photo.deleted_at.nil?
    end
    profile
  end
end
