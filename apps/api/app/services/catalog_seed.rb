# frozen_string_literal: true

require "json"

class CatalogSeed
  WHOLE_CITY_SENTINEL = "all"

  def self.default_path
    configured_path = ENV["CATALOG_SEED_PATH"].presence
    return Pathname(configured_path) if configured_path

    [Pathname("/catalog-data/catalogs.json"), Rails.root.join("../web/data/catalogs.json")].find(&:file?) ||
      raise(Errno::ENOENT, "apps/web/data/catalogs.json")
  end

  def initialize(path: self.class.default_path)
    @path = Pathname(path)
  end

  def call
    catalog = JSON.parse(path.read)

    ActiveRecord::Base.transaction do
      categories_by_slug = seed_categories(catalog.fetch("categories"))
      seed_services(catalog.fetch("services"), categories_by_slug)
      seed_neighborhoods(catalog.fetch("neighborhoods"))
    end
  end

  private

  attr_reader :path

  def seed_categories(categories)
    categories.each_with_index.to_h do |attributes, sort_order|
      slug = attributes.fetch("id")
      category = ServiceCategory.find_or_initialize_by(slug:)
      if category.new_record?
        category.assign_attributes(
          name: attributes.fetch("name"),
          icon: attributes.fetch("icon"),
          is_active: true,
          sort_order:
        )
        category.save!
      end
      [slug, category]
    end
  end

  def seed_services(services, categories_by_slug)
    services.each_with_index do |attributes, sort_order|
      service = Service.find_or_initialize_by(slug: attributes.fetch("slug"))
      next unless service.new_record?

      service.assign_attributes(
        category: categories_by_slug.fetch(attributes.fetch("category")),
        name: attributes.fetch("name"),
        icon: attributes.fetch("icon"),
        description: attributes.fetch("description"),
        aliases: attributes.fetch("aliases"),
        is_active: true,
        sort_order:
      )
      service.save!
    end
  end

  def seed_neighborhoods(neighborhoods)
    neighborhoods.reject { |attributes| attributes.fetch("code") == WHOLE_CITY_SENTINEL }.each_with_index do |attributes, sort_order|
      neighborhood = Neighborhood.find_or_initialize_by(code: attributes.fetch("code"))
      next unless neighborhood.new_record?

      neighborhood.assign_attributes(
        name: attributes.fetch("name"),
        state_code: attributes.fetch("stateCode"),
        city_code: attributes.fetch("city"),
        is_active: true,
        sort_order:
      )
      neighborhood.save!
    end
  end
end
