# frozen_string_literal: true

class PublicProfessionalSearchSerializer
  def initialize(result, interaction: nil)
    @result = result
    @interaction = interaction
  end

  def as_json(*)
    {
      professionals: result.professionals.map do |profile|
        PublicProfessionalCardSerializer.new(
          profile,
          matching_service: result.matching_service_for(profile)
        ).as_json
      end,
      related_services: result.related_services.map do |service|
        PublicServiceSuggestionSerializer.new(service).as_json
      end,
      meta: {
        page: result.page,
        per_page: result.per_page,
        total_count: result.total_count,
        total_pages: result.total_pages
      },
      interpretation:,
      interaction: interaction && {
        search_event_id: interaction.search_event_id,
        token: interaction.token
      }
    }
  end

  private

  attr_reader :interaction, :result

  def interpretation
    neighborhood_codes = result.criteria.locations.filter_map(&:neighborhood_code)
    neighborhoods_by_code = Neighborhood.where(code: neighborhood_codes).index_by(&:code)

    {
      services: result.services.map do |service|
        PublicServiceSuggestionSerializer.new(service).as_json
      end,
      locations: result.criteria.locations.map do |location|
        neighborhood = neighborhoods_by_code[location.neighborhood_code]
        {
          state_code: location.state_code,
          city: location.city,
          neighborhood: neighborhood && {code: neighborhood.code, name: neighborhood.name}
        }
      end,
      normalized_request: result.criteria.normalized_request
    }
  end
end
