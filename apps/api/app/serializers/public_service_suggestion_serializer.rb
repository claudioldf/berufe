# frozen_string_literal: true

class PublicServiceSuggestionSerializer
  def initialize(service)
    @service = service
  end

  def as_json(*)
    {
      id: service.id,
      name: service.name,
      slug: service.slug,
      icon: service.icon,
      description: service.description
    }
  end

  private

  attr_reader :service
end
