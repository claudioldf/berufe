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

  def snapshot
    AdminCatalogSerializer.new(
      categories: ServiceCategory.ordered.to_a,
      services: Service.includes(:category).ordered.to_a
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
