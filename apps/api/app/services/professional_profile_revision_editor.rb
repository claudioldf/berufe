# frozen_string_literal: true

class ProfessionalProfileRevisionEditor
  def call(profile:)
    revision = profile.working_revision
    if revision&.editable? && revision != profile.published_revision
      if revision.status == "rejected" && profile.published_revision
        revision.update!(
          status: "pending_review",
          submitted_at: Time.current,
          reviewed_at: nil,
          rejection_reason: nil
        )
      end
      return revision
    end
    return revision if revision&.status == "draft" && profile.published_revision.nil?

    source = profile.published_revision || revision
    raise ActiveRecord::RecordNotFound, "professional profile revision" unless source

    next_revision = clone_revision(profile:, source:)
    profile.update!(working_revision: next_revision)
    next_revision
  end

  private

  def clone_revision(profile:, source:)
    revision = profile.revisions.create!(
      version: profile.revisions.maximum(:version).to_i + 1,
      status: profile.published_revision ? "pending_review" : "draft",
      display_name: source.display_name,
      headline: source.headline,
      bio: source.bio,
      years_experience: source.years_experience,
      whatsapp_e164: source.whatsapp_e164,
      instagram_url: source.instagram_url,
      youtube_url: source.youtube_url,
      submitted_at: profile.published_revision ? Time.current : nil
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
