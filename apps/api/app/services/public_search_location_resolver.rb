# frozen_string_literal: true

class PublicSearchLocationResolver
  Result = Data.define(:location, :source)

  def initialize(
    ip_location_service: IpLocationService.new,
    supported_locations: SupportedSearchLocations.new
  )
    @ip_location_service = ip_location_service
    @supported_locations = supported_locations
  end

  def call(ip_address:)
    detected = ip_location_service.call(ip_address)
    location = if detected&.country_code == "BR"
      supported_locations.find(state_code: detected.state_code, city: detected.city)
    end

    Result.new(
      location: location || SupportedSearchLocations::FALLBACK,
      source: location ? "ip" : "fallback"
    )
  end

  private

  attr_reader :ip_location_service, :supported_locations
end
