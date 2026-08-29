# frozen_string_literal: true

class PublicServiceCoverageSerializer
  def initialize(entry)
    @entry = entry
  end

  def as_json(*)
    {
      service: PublicServiceSuggestionSerializer.new(entry.service).as_json,
      location: entry.location.to_h,
      professional_count: entry.professional_count,
      indexable: PublicIndexability.listing_indexable?(entry.professional_count)
    }
  end

  private

  attr_reader :entry
end
