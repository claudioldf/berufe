# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicSearchLocationResolver do
  let(:ip_location_service) { instance_double(IpLocationService) }
  let(:supported_locations) { SupportedSearchLocations.new }

  it "uses a supported Brazilian IP-derived city" do
    allow(ip_location_service).to receive(:call).and_return(
      IpLocationService::Location.new(city: "joinville", state_code: "sc", country_code: "BR")
    )

    result = described_class.new(ip_location_service:, supported_locations:).call(ip_address: "8.8.8.8")

    expect(result.source).to eq("ip")
    expect(result.location).to eq(SupportedSearchLocations::FALLBACK)
  end

  it "silently falls back to Joinville for unsupported, foreign, and unavailable detections" do
    [
      IpLocationService::Location.new(city: "Curitiba", state_code: "PR", country_code: "BR"),
      IpLocationService::Location.new(city: "Lisboa", state_code: "11", country_code: "PT"),
      nil
    ].each do |detected|
      allow(ip_location_service).to receive(:call).and_return(detected)

      result = described_class.new(ip_location_service:, supported_locations:).call(ip_address: "8.8.8.8")

      expect(result).to have_attributes(source: "fallback", location: SupportedSearchLocations::FALLBACK)
    end
  end
end
