# frozen_string_literal: true

class ProfessionalProfileRevisionEditor
  # Draft onboarding edits stay on the initial revision. Once published, every
  # save receives a new revision so an admin can never approve stale content.
  def call(profile:)
    revision = profile.working_revision
    return revision if revision&.status == "draft"

    source = revision&.rejected? ? revision : (profile.published_revision || revision)
    raise ActiveRecord::RecordNotFound, "professional profile revision" unless source

    @source_revision = source
    @source_was_pending = source.pending_review?
    source.update!(status: "superseded", reviewed_at: Time.current) if @source_was_pending
    next_revision = clone_revision(profile:, source:)
    profile.update!(working_revision: next_revision)
    next_revision
  end

  # The changed revision is both public and pending review. The approved
  # pointer remains untouched as the deterministic rejection fallback.
  def synchronize_review_state!(profile:)
    revision = profile.working_revision
    return revision unless revision && profile.profile_status == "published"
    return revision if revision.self_service? && profile.published_revision&.external?

    source = @source_revision || profile.published_revision
    if source && !source.rejected? && revision != source && revision.material_snapshot == source.material_snapshot
      profile.update!(working_revision: source)
      revision.destroy!
      source.update!(status: "pending_review", reviewed_at: nil) if @source_was_pending
      return source
    end

    now = Time.current
    previous_live = profile.published_revision
    if previous_live&.pending_review? && previous_live != revision
      previous_live.update!(status: "superseded", reviewed_at: now)
    end
    revision.update!(
      status: "pending_review",
      submitted_at: now,
      reviewed_at: nil,
      rejection_reason: nil
    )
    profile.update!(published_revision: revision, working_revision: revision)
    revision
  end

  private

  def clone_revision(profile:, source:)
    revision = profile.revisions.create!(
      version: profile.revisions.maximum(:version).to_i + 1,
      status: "draft",
      profile_type: source.profile_type,
      display_name: source.display_name,
      headline: source.headline,
      bio: source.bio,
      years_experience: source.years_experience,
      whatsapp_e164: source.whatsapp_e164,
      instagram_url: source.instagram_url,
      youtube_url: source.youtube_url
    )
    source.professional_profile_services.find_each do |selection|
      revision.professional_profile_services.create!(
        service_id: selection.service_id,
        is_primary: selection.is_primary,
        note: selection.note
      )
    end
    source.professional_profile_service_areas.find_each do |area|
      revision.professional_profile_service_areas.create!(
        city_code: area.city_code,
        neighborhood_code: area.neighborhood_code
      )
    end
    revision
  end
end
