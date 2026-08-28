# frozen_string_literal: true

class AvailableSearchLocations
  def initialize(supported_locations: SupportedSearchLocations.new)
    @supported_locations = supported_locations
  end

  def all
    available_city_codes = ProfessionalProfile
      .publicly_searchable
      .joins(:published_revision)
      .distinct
      .pluck("professional_profile_revisions.coverage_city_code")

    supported_locations.all.select do |location|
      available_city_codes.include?(location.city_code)
    end
  end

  private

  attr_reader :supported_locations
end
