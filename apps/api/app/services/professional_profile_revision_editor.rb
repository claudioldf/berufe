# frozen_string_literal: true

class ProfessionalProfileRevisionEditor
  # Self-service profile data is no longer moderated. The working revision is
  # updated in place and, once published, is immediately the public revision.
  def call(profile:)
    profile.working_revision || raise(ActiveRecord::RecordNotFound, "professional profile revision")
  end

  def synchronize_public_revision!(profile:)
    revision = call(profile:)
    return revision unless profile.profile_status == "published"
    return revision if revision.self_service? && profile.published_revision&.external?

    profile.update!(published_revision: revision)
    revision
  end
end
