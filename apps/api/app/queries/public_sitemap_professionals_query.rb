# frozen_string_literal: true

# The bulk professional slug list behind the sitemap. Sitemap membership must
# match the canonical profile's own indexability decision exactly: publishing a
# `noindex` URL in the sitemap sends conflicting signals to crawlers.
class PublicSitemapProfessionalsQuery
  Entry = Data.define(:slug, :updated_at)

  def call
    ProfessionalProfile
      .publicly_eligible
      .includes(
        :profile_photo,
        :verification_requests,
        portfolio_items: :service,
        published_revision: {
          professional_profile_services: :service,
          professional_profile_service_areas: :neighborhood
        }
      )
      .order(:public_slug)
      .filter_map do |profile|
        payload = PublicProfessionalProfileSerializer.new(profile).as_json
        next unless payload&.fetch(:indexable)

        Entry.new(slug: profile.public_slug, updated_at: profile.published_revision.updated_at)
      end
  end
end
