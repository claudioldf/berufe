# frozen_string_literal: true

class PublicServiceResolver
  Result = Data.define(:service, :normalized_term, :active_services)

  def call(term)
    normalized_term = PublicSearchText.normalize(term)
    active_services = Service.publicly_active.includes(:category).ordered.to_a
    service = active_services.find do |candidate|
      searchable_values(candidate).include?(normalized_term)
    end

    Result.new(service:, normalized_term:, active_services:)
  end

  private

  def searchable_values(service)
    [service.slug, service.name, *service.aliases].map { |value| PublicSearchText.normalize(value) }
  end
end
