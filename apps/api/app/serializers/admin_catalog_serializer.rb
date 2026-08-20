# frozen_string_literal: true

class AdminCatalogSerializer
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
      name: category.name
    }
  end

  def serialize_service(service)
    {
      id: service.id,
      name: service.name,
      slug: service.slug,
      category_slug: service.category.slug,
      description: service.description,
      is_active: service.is_active,
      sort_order: service.sort_order
    }
  end

  def serialize_neighborhood(neighborhood)
    {
      code: neighborhood.code,
      name: neighborhood.name,
      state_code: neighborhood.state_code,
      city: neighborhood.city_code,
      is_active: neighborhood.is_active,
      sort_order: neighborhood.sort_order
    }
  end
end
