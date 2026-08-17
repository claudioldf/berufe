# frozen_string_literal: true

class PublicCatalogSerializer
  def initialize(categories:, services:, neighborhoods:)
    @categories = categories
    @services = services
    @neighborhoods = neighborhoods
  end

  def as_json(*)
    {
      categories: @categories.map { |category| serialize_category(category) },
      services: @services.map { |service| serialize_service(service) },
      neighborhoods: @neighborhoods.map { |neighborhood| serialize_neighborhood(neighborhood) }
    }
  end

  private

  def serialize_category(category)
    {
      id: category.id,
      slug: category.slug,
      name: category.name,
      icon: category.icon
    }
  end

  def serialize_service(service)
    {
      id: service.id,
      name: service.name,
      slug: service.slug,
      categorySlug: service.category.slug,
      icon: service.icon,
      description: service.description,
      aliases: service.aliases
    }
  end

  def serialize_neighborhood(neighborhood)
    {
      code: neighborhood.code,
      name: neighborhood.name,
      stateCode: neighborhood.state_code,
      city: neighborhood.city_code
    }
  end
end
