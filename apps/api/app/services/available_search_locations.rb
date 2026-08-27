# frozen_string_literal: true

class AvailableSearchLocations
  def initialize(supported_locations: SupportedSearchLocations.new)
    @supported_locations = supported_locations
  end

  def all
    available_city_codes = ProfessionalProfile
      .publicly_searchable
      .joins(published_revision: :professional_profile_service_areas)
      .distinct
      .pluck("professional_profile_service_areas.city_code")

    supported_locations.all.select do |location|
      available_city_codes.include?(location.city)
    end
  end

  private

  attr_reader :supported_locations
end
