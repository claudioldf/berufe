# frozen_string_literal: true

class AdminCatalogSerializer
  def initialize(categories:, services:)
    @categories = categories
    @services = services
  end

  def as_json(*)
    {
      categories: @categories.map { |category| serialize_category(category) },
      services: @services.map { |service| serialize_service(service) }
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
end
