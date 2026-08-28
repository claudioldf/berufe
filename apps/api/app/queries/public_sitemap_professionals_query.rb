# frozen_string_literal: true

# The bulk professional slug list behind the sitemap. Self-service and
# published only -- the same population PublicIndexability.profile_indexable?
# ultimately allows, but without re-checking each profile's specific
# evidence (portfolio/recommendation/verification): at current founding-cohort
# scale that per-profile check is unnecessary weight, and the small resulting
# over-inclusion is self-correcting -- a profile without evidence yet still
# renders `noindex`, so Search Console reports it as excluded, not broken.
class PublicSitemapProfessionalsQuery
  Entry = Data.define(:slug, :updated_at)

  def call
    ProfessionalProfile
      .publicly_eligible
      .joins(:published_revision)
      .pluck(:public_slug, "professional_profile_revisions.submitted_at", "professional_profile_revisions.created_at")
      .map { |slug, submitted_at, created_at| Entry.new(slug:, updated_at: submitted_at || created_at) }
  end
end
