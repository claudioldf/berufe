# frozen_string_literal: true

class PublicProfessionalSearchSerializer
  def initialize(result, interaction: nil)
    @result = result
    @interaction = interaction
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
      end,
      interaction: interaction && {
        searchEventId: interaction.search_event_id,
        token: interaction.token
      }
    }
  end

  private

  attr_reader :interaction, :result
end
