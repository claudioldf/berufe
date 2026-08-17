# frozen_string_literal: true

class CatalogManagement
  class Conflict < StandardError; end

  def initialize(context: Current.admin_action_context)
    @context = context
  end

  def create_service(attributes)
    Service.transaction do
      lock_catalog!
      category = ServiceCategory.find_by!(slug: attributes.fetch(:category_slug))
      service = Service.create!(
        category:,
        name: attributes.fetch(:name).to_s.squish,
        slug: attributes.fetch(:slug).to_s.strip.downcase,
        icon: category.icon,
        description: attributes.fetch(:description).to_s.squish,
        aliases: [],
        is_active: true,
        sort_order: next_sort_order(Service)
      )
      record_event!(
        catalog_type: "service",
        target_identifier: service.slug,
        action: "created",
        changes: {before: nil, after: service_state(service)}
      )
      snapshot
    end
  end

  def update_service(id, attributes)
    Service.transaction do
      lock_catalog!
      service = Service.includes(:category).find(id)
      before = service_state(service)
      assign_service_attributes(service, attributes)
      service.save!
      after = service_state(service)
      record_event!(
        catalog_type: "service",
        target_identifier: service.slug,
        action: update_action(before:, after:),
        changes: changed_values(before:, after:)
      )
      snapshot
    end
  end

  def reorder_services(ordered_ids)
    Service.transaction do
      lock_catalog!
      services = Service.ordered.to_a
      normalized_ids = normalize_order(ordered_ids)
      validate_complete_order!(normalized_ids, services.map { |service| service.id.to_s })
      services_by_id = services.index_by { |service| service.id.to_s }

      normalized_ids.each_with_index do |id, sort_order|
        services_by_id.fetch(id).update!(sort_order:)
      end

      record_event!(
        catalog_type: "service",
        target_identifier: "services",
        action: "reordered",
        changes: {order: normalized_ids}
      )
      snapshot
    end
  end

  def create_neighborhood(attributes)
    Neighborhood.transaction do
      lock_catalog!
      neighborhood = Neighborhood.create!(
        code: attributes.fetch(:code).to_s.strip.downcase,
        name: attributes.fetch(:name).to_s.squish,
        state_code: attributes.fetch(:state_code).to_s.strip.upcase,
        city_code: attributes.fetch(:city).to_s.squish,
        is_active: true,
        sort_order: next_sort_order(Neighborhood)
      )
      record_event!(
        catalog_type: "neighborhood",
        target_identifier: neighborhood.code,
        action: "created",
        changes: {before: nil, after: neighborhood_state(neighborhood)}
      )
      snapshot
    end
  end

  def update_neighborhood(code, attributes)
    Neighborhood.transaction do
      lock_catalog!
      neighborhood = Neighborhood.find(code)
      before = neighborhood_state(neighborhood)
      assign_neighborhood_attributes(neighborhood, attributes)
      neighborhood.save!
      after = neighborhood_state(neighborhood)
      record_event!(
        catalog_type: "neighborhood",
        target_identifier: neighborhood.code,
        action: update_action(before:, after:),
        changes: changed_values(before:, after:)
      )
      snapshot
    end
  end

  def reorder_neighborhoods(ordered_codes)
    Neighborhood.transaction do
      lock_catalog!
      neighborhoods = Neighborhood.ordered.to_a
      normalized_codes = normalize_order(ordered_codes)
      validate_complete_order!(normalized_codes, neighborhoods.map(&:code))
      neighborhoods_by_code = neighborhoods.index_by(&:code)

      normalized_codes.each_with_index do |code, sort_order|
        neighborhoods_by_code.fetch(code).update!(sort_order:)
      end

      record_event!(
        catalog_type: "neighborhood",
        target_identifier: "neighborhoods",
        action: "reordered",
        changes: {order: normalized_codes}
      )
      snapshot
    end
  end

  def snapshot
    AdminCatalogSerializer.new(
      categories: ServiceCategory.ordered.to_a,
      services: Service.includes(:category).ordered.to_a,
      neighborhoods: Neighborhood.ordered.to_a
    )
  end

  private

  attr_reader :context

  def lock_catalog!
    ServiceCategory.lock.order(:id).first!
  end

  def next_sort_order(model)
    (model.maximum(:sort_order) || -1) + 1
  end

  def assign_service_attributes(service, attributes)
    service.name = attributes.fetch(:name).to_s.squish if attributes.key?(:name)
    service.description = attributes.fetch(:description).to_s.squish if attributes.key?(:description)
    service.is_active = attributes.fetch(:is_active) if attributes.key?(:is_active)
    return unless attributes.key?(:category_slug)

    service.category = ServiceCategory.find_by!(slug: attributes.fetch(:category_slug))
  end

  def assign_neighborhood_attributes(neighborhood, attributes)
    neighborhood.name = attributes.fetch(:name).to_s.squish if attributes.key?(:name)
    neighborhood.state_code = attributes.fetch(:state_code).to_s.strip.upcase if attributes.key?(:state_code)
    neighborhood.city_code = attributes.fetch(:city).to_s.squish if attributes.key?(:city)
    neighborhood.is_active = attributes.fetch(:is_active) if attributes.key?(:is_active)
  end

  def normalize_order(identifiers)
    Array(identifiers).map(&:to_s)
  end

  def validate_complete_order!(submitted, expected)
    return if submitted.length == expected.length && submitted.uniq.length == submitted.length && submitted.to_set == expected.to_set

    raise Conflict, "catalog order is stale or incomplete"
  end

  def update_action(before:, after:)
    status_changed = before.fetch(:isActive) != after.fetch(:isActive)
    other_changes = before.except(:isActive) != after.except(:isActive)
    return "updated" unless status_changed && !other_changes

    after.fetch(:isActive) ? "activated" : "deactivated"
  end

  def changed_values(before:, after:)
    changed_keys = before.keys.select { |key| before.fetch(key) != after.fetch(key) }
    {
      before: before.slice(*changed_keys),
      after: after.slice(*changed_keys)
    }
  end

  def service_state(service)
    {
      name: service.name,
      categorySlug: service.category.slug,
      description: service.description,
      isActive: service.is_active,
      sortOrder: service.sort_order
    }
  end

  def neighborhood_state(neighborhood)
    {
      name: neighborhood.name,
      stateCode: neighborhood.state_code,
      city: neighborhood.city_code,
      isActive: neighborhood.is_active,
      sortOrder: neighborhood.sort_order
    }
  end

  def record_event!(catalog_type:, target_identifier:, action:, changes:)
    CatalogChangeEvent.create!(
      admin_user_id: context.admin_user_id,
      request_id: context.request_id,
      catalog_type:,
      target_identifier:,
      action:,
      change_data: changes
    )
  end
end
