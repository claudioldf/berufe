# frozen_string_literal: true

class PublicProfessionalSearchSerializer
  def initialize(result, interaction: nil)
    @result = result
    @interaction = interaction
  end

  def as_json(*)
    {
      query: {
        normalized_term: result.normalized_term,
        professional_name: result.professional_name,
        service: result.service && PublicServiceSuggestionSerializer.new(result.service).as_json,
        neighborhood: result.neighborhood && {
          code: result.neighborhood.code,
          name: result.neighborhood.name
        }
      },
      professionals: result.professionals.map do |profile|
        PublicProfessionalCardSerializer.new(profile, matching_service: result.service).as_json
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
      interaction: interaction && {
        search_event_id: interaction.search_event_id,
        token: interaction.token
      }
    }
  end

  private

  attr_reader :interaction, :result
end
