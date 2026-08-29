# frozen_string_literal: true

class PublicProfessionalListingSerializer
  def initialize(result, service:, location:)
    @result = result
    @service = service
    @location = location
  end

  def as_json(*)
    {
      service: PublicServiceSuggestionSerializer.new(service).as_json,
      location: location.to_h,
      professionals: result.professionals.map do |profile|
        PublicProfessionalCardSerializer.new(profile, matching_service: service).as_json
      end,
      related_services: result.related_services.map do |suggestion|
        PublicServiceSuggestionSerializer.new(suggestion).as_json
      end,
      meta: {
        page: result.page,
        per_page: result.per_page,
        total_count: result.total_count,
        total_pages: result.total_pages
      },
      indexable: PublicIndexability.listing_indexable?(result.total_count)
    }
  end

  private

  attr_reader :result, :service, :location
end
