# frozen_string_literal: true

# The service x city professional-count matrix behind the service and city
# hub pages, the footer link mesh, and the sitemap. Counts every profile
# that has the service associated (primary or secondary) -- the same
# criterion PublicProfessionalSearch#call_with_filters uses -- so a hub
# page's count never disagrees with what the linked listing page actually
# shows.
class PublicServiceCoverageQuery
  Entry = Data.define(:service, :location, :professional_count)

  def call(service_id: nil, city_code: nil)
    services_by_id = Service.publicly_active.includes(:category).index_by(&:id)
    locations_by_code = SupportedSearchLocations.new.all.index_by(&:city_code)

    scope = ProfessionalProfile
      .publicly_searchable
      .joins(published_revision: :professional_profile_services)
    scope = scope.where(professional_profile_services: {service_id:}) if service_id
    scope = scope.where(professional_profile_revisions: {coverage_city_code: city_code}) if city_code

    counts = scope
      .group("professional_profile_services.service_id", "professional_profile_revisions.coverage_city_code")
      .count("professional_profiles.id")

    counts.filter_map do |(counted_service_id, counted_city_code), professional_count|
      service = services_by_id[counted_service_id]
      location = locations_by_code[counted_city_code]
      next unless service && location

      Entry.new(service:, location:, professional_count:)
    end.sort_by { |entry| [entry.location.city, entry.service.name] }
  end
end
