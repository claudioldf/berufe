# frozen_string_literal: true

class ProfessionalRelationshipCandidateSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    revision = profile.published_revision
    {
      id: profile.id,
      public_slug: profile.public_slug,
      display_name: revision.display_name,
      profile_type: revision.profile_type,
      photo_url: profile.published_photo && PublicProfilePhotoImageUrl.call(profile.published_photo)
    }
  end

  private

  attr_reader :profile
end
