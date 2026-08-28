# frozen_string_literal: true

class PublicCatalogSerializer
  def initialize(categories:, services:)
    @categories = categories
    @services = services
  end

  def as_json(*)
    {
      categories: @categories.map { |category| serialize_category(category) },
      services: @services.map { |service| serialize_service(service) },
      cities: AvailableSearchLocations.new.all.map(&:to_h)
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
      category_slug: service.category.slug,
      icon: service.icon,
      description: service.description,
      aliases: service.aliases
    }
  end
end
