# frozen_string_literal: true

class PublicProfessionalSearchSerializer
  def initialize(result)
    @result = result
  end

  def as_json(*)
    {
      query: {
        normalizedTerm: result.normalized_term,
        service: result.service && PublicServiceSuggestionSerializer.new(result.service).as_json,
        neighborhood: result.neighborhood && {
          code: result.neighborhood.code,
          name: result.neighborhood.name
        }
      },
      professionals: result.professionals.map do |profile|
        PublicProfessionalCardSerializer.new(profile, matching_service: result.service).as_json
      end,
      relatedServices: result.related_services.map do |service|
        PublicServiceSuggestionSerializer.new(service).as_json
      end
    }
  end

  private

  attr_reader :result
end
